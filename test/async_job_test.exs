# Copyright(c) 2015-2021 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.AsyncJobTest do
  use ExUnit.Case
  alias Antikythera.{Time, Cron, AsyncJob}
  alias Antikythera.Test.{ProcessHelper, AsyncJobHelper}
  alias AntikytheraCore.{TerminationManager, ExecutorPool}
  alias AntikytheraCore.ExecutorPool.Setting, as: EPoolSetting
  alias AntikytheraCore.ExecutorPool.RegisteredName, as: RegName
  alias AntikytheraCore.ExecutorPool.AsyncJobBroker, as: Broker
  alias AntikytheraCore.AsyncJob.Queue
  alias Testgear.TestAsyncJob

  @epool_id {:gear, :testgear}

  setup do
    AsyncJobHelper.reset_rate_limit_status(@epool_id)
    try do
      Process.register(self(), TestAsyncJob)
    rescue
      ArgumentError -> # Termination of the previous test process hasn't propagated yet; retry once more.
        :timer.sleep(100)
        Process.register(self(), TestAsyncJob)
    end
    :ok
  end

  defp get_broker_pid() do
    sup_name = RegName.supervisor_unsafe(@epool_id)
    broker_pid =
      Supervisor.which_children(sup_name)
      |> Enum.find_value(fn
        {Broker, pid, :worker, _} -> pid
        _                         -> nil
      end)
    assert is_pid(broker_pid)
    broker_pid
  end

  defp confirm_that_broker_is_active(broker) do
    if :sys.get_state(broker).phase != :active do
      :timer.sleep(500) # if not yet ready it should soon become :active
      assert :sys.get_state(broker).phase == :active
    end
    :timer.sleep(50) # wait for the 1st :polling_timeout in the broker process
  end

  test "broker should (eventually) become active and register its pid to TerminationManager" do
    broker_pid = get_broker_pid()
    confirm_that_broker_is_active(broker_pid)
    %{brokers: brokers} = :sys.get_state(TerminationManager)
    assert broker_pid in brokers
  end

  @tag capture_log: true
  test "after restart of a broker, queue should discard dead pid of the previous broker from brokers_waiting" do
    queue_name = RegName.async_job_queue(@epool_id)
    :timer.sleep(20) # wait for startup of the broker (if not yet finished)
    broker1 = get_broker_pid()
    confirm_that_broker_is_active(broker1)
    {:ok, q1} = RaftFleet.query(queue_name, :get)
    assert q1.brokers_waiting == [broker1]
    Process.exit(broker1, :kill)
    :timer.sleep(50) # wait for supervisor restart and startup of the new broker
    broker2 = get_broker_pid()
    confirm_that_broker_is_active(broker2)
    {:ok, q3} = RaftFleet.query(queue_name, :get)
    assert q3.brokers_waiting == [broker2]
  end

  defp register_job(todo, options \\ []) do
    case TestAsyncJob.register(%{todo: todo}, @epool_id, options) do
      {:ok, _} -> :ok
      error    -> error
    end
  end

  defp n_waiting_runnable_running() do
    queue_name = RegName.async_job_queue(@epool_id)
    jobs = Queue.list(queue_name)
    n1 = Enum.count(jobs, &match?({_, _, :waiting }, &1))
    n2 = Enum.count(jobs, &match?({_, _, :runnable}, &1))
    n3 = Enum.count(jobs, &match?({_, _, :running }, &1))
    {n1, n2, n3}
  end

  test "registered job should be immediately executed" do
    assert register_job(:send) == :ok
    assert_receive({:executing, executor_pid}, 200) # use longer timeout for CircleCI test runs
    ProcessHelper.monitor_wait(executor_pid)
    :timer.sleep(100)
    _ = :sys.get_state(get_broker_pid()) # confirm that DOWN message has been processed
    assert n_waiting_runnable_running() == {0, 0, 0}
  end

  test "registered job with :bypass_job_queue option should be immediately executed" do
    assert register_job(:send, [bypass_job_queue: true]) == :ok
    assert_receive({:executing, executor_pid})
    ProcessHelper.monitor_wait(executor_pid)
  end

  test "registered jobs up to pool capacity should be concurrently executed" do
    pool_status = PoolSup.status(RegName.async_job_runner_pool(@epool_id))
    assert pool_status[:reserved] == 0
    assert pool_status[:ondemand] == 2

    Enum.each(1..5, fn _ -> assert register_job({:sleep, 100}) == :ok end)
    :timer.sleep(150)
    assert_receive({:executing, _pid})
    assert_receive({:executing, _pid})
    :timer.sleep(150)
    assert_receive({:executing, _pid})
    assert_receive({:executing, _pid})
    :timer.sleep(150)
    assert_receive({:executing, _pid})
    refute_received(_)
    :timer.sleep(50)
    assert n_waiting_runnable_running() == {0, 0, 0}
  end

  test "registered jobs with :bypass_job_queue option should return an error if there are no processes in the pool" do
    pool_status = PoolSup.status(RegName.async_job_runner_pool(@epool_id))
    assert pool_status[:reserved] == 0
    assert pool_status[:ondemand] == 2

    assert register_job({:sleep, 500}) == :ok
    assert register_job({:sleep, 500}) == :ok
    :timer.sleep(200)
    assert register_job(:send, [bypass_job_queue: true]) == {:error, :no_available_workers}
    :timer.sleep(500)
    assert_receive({:executing, _pid})
    assert_receive({:executing, _pid})
    :timer.sleep(100)
    assert register_job(:send, [bypass_job_queue: true]) == :ok
    assert_receive({:executing, _pid})
    refute_received(_)
    :timer.sleep(100)
    assert n_waiting_runnable_running() == {0, 0, 0}
  end

  test "changing capacity of pool should trigger job execution (if pool size is increased)" do
    Enum.each(1..3, fn _ -> assert register_job({:sleep, 300}) == :ok end)
    :timer.sleep(100)
    assert n_waiting_runnable_running() == {0, 1, 2}

    new_setting = %EPoolSetting{EPoolSetting.default() | pool_size_j: 3}
    ExecutorPool.apply_setting(@epool_id, new_setting)
    :timer.sleep(100)
    assert n_waiting_runnable_running() == {0, 0, 3}

    :timer.sleep(300)
    Enum.each(1..3, fn _ ->
      assert_receive({:executing, _pid})
    end)
    refute_received(_)
    :timer.sleep(100)
    assert n_waiting_runnable_running() == {0, 0, 0}

    ExecutorPool.apply_setting(@epool_id, EPoolSetting.default())
  end

  test "should brutally kill long running job and retry it" do
    assert register_job({:sleep, 1000}, [max_duration: 100, attempts: 3, retry_interval: {0, 1.0}]) == :ok
    :timer.sleep(50)
    assert n_waiting_runnable_running() == {0, 0, 1}
    :timer.sleep(100)
    {0, runnable1, running1} = n_waiting_runnable_running()
    assert runnable1 + running1 == 1
    :timer.sleep(100)
    {0, runnable2, running2} = n_waiting_runnable_running()
    assert runnable2 + running2 == 1
    :timer.sleep(300)
    assert n_waiting_runnable_running() == {0, 0, 0}
    assert_receive({:abandon, _pid})
    refute_received(_)
  end

  test "should retry failed job" do
    Enum.each([:raise, :throw, :exit], fn todo ->
      assert register_job(todo, [attempts: 3, retry_interval: {0, 1.0}]) == :ok
      Enum.each(1..3, fn _ ->
        :timer.sleep(100)
        assert_receive({:executing, _pid})
      end)
      assert_receive({:abandon, _pid}, 1_000) # long timeout for Circle CI
      assert n_waiting_runnable_running() == {0, 0, 0}
      refute_received(_)
    end)
  end

  @tag capture_log: true
  test "should handle death of worker due to heap limit violation" do
    assert register_job(:exhaust_heap_memory, [attempts: 1]) == :ok
    :timer.sleep(1000)
    assert n_waiting_runnable_running() == {0, 0, 0}
    assert_receive({:executing, _pid})
    assert_receive({:abandon, _pid})
    refute_received(_)
  end

  defp timed_job_starter_pid() do
    {_, pid, _, _} =
      Supervisor.which_children(RegName.supervisor(@epool_id))
      |> Enum.find(&match?({AntikytheraCore.ExecutorPool.TimedJobStarter, _, :worker, _}, &1))
    pid
  end

  test "timed job should be automatically run" do
    job_starter_pid = timed_job_starter_pid()
    t = Time.shift_milliseconds(Time.now(), 200)
    assert register_job(:send, [schedule: {:once, t}]) == :ok
    assert n_waiting_runnable_running() == {1, 0, 0}
    send(job_starter_pid, :timeout) # manually trigger timeout of TimedJobStarter
    :timer.sleep(200)
    send(job_starter_pid, :timeout)
    assert_receive({:executing, _pid}, 1_000) # long timeout for Circle CI
    refute_received(_)
    :timer.sleep(100)
    assert n_waiting_runnable_running() == {0, 0, 0}
  end

  test "cancelled job should not run" do
    job_starter_pid = timed_job_starter_pid()
    job_id = "foobar"
    t = Time.shift_milliseconds(Time.now(), 100)
    assert register_job(:send, [id: job_id, schedule: {:once, t}]) == :ok
    assert n_waiting_runnable_running() == {1, 0, 0}

    assert AsyncJob.cancel(:testgear, {:gear, :foo}, job_id) == {:error, {:invalid_executor_pool, {:gear, :foo}}}
    assert AsyncJob.cancel(:testgear, @epool_id    , job_id) == :ok

    send(job_starter_pid, :timeout) # manually trigger timeout of TimedJobStarter but no job started
    :timer.sleep(100)
    refute_receive(_)
    assert n_waiting_runnable_running() == {0, 0, 0}
  end

  test "recurring job should be requeued on completion" do
    :meck.new(Cron, [:passthrough])

    job_starter_pid = timed_job_starter_pid()
    job_id = "foobar"
    now_millis = System.system_time(:millisecond)

    # tweak first execution time on job registration
    {Time, _ymd, {_h, m1, _s}, _} = Time.now()
    m2 = if m1 < 2, do: m1 + 58, else: m1 - 2
    :meck.expect(Cron, :next_in_epoch_milliseconds, fn(_cron, _time) -> now_millis + 100 end)
    assert register_job(:send, [id: job_id, schedule: {:cron, Cron.parse!("#{m2} * * * *")}]) == :ok
    :meck.unload()

    refute_received(_)
    :timer.sleep(100)
    send(job_starter_pid, :timeout) # manually trigger timeout of TimedJobStarter
    :timer.sleep(100)
    assert_receive({:executing, _pid})
    refute_received(_)
    :timer.sleep(100)
    assert n_waiting_runnable_running() == {1, 0, 0}
    {:ok, status} = AsyncJob.status(@epool_id, job_id)
    assert status.start_time >= Time.from_epoch_milliseconds(now_millis)

    assert AsyncJob.cancel(:testgear, @epool_id, job_id) == :ok
    assert AsyncJob.status(@epool_id, job_id)            == {:error, :not_found}
  end

  test "status should report current status of queued job" do
    job_id = "foobar"
    assert AsyncJob.status(@epool_id, job_id) == {:error, :not_found}
    assert register_job({:sleep, 100}, [id: job_id]) == :ok
    {:ok, status} = AsyncJob.status(@epool_id, job_id)
    assert status.payload == %{todo: {:sleep, 100}}
    :timer.sleep(200)
    assert AsyncJob.status(@epool_id, job_id) == {:error, :not_found}
  end

  defmodule JobWithRaisingInspectPayload do
    use Antikythera.AsyncJob

    @impl true
    def inspect_payload(_) do
      raise "fail"
    end

    @impl true
    def run(_, _, _) do
      send(TestAsyncJob, :run)
    end
  end

  test "exception during inspect_payload/1 should be handeled" do
    {:ok, job_id} = JobWithRaisingInspectPayload.register(%{p: :p}, @epool_id, [])
    :timer.sleep(100)
    assert_receive(:run)
    :timer.sleep(100)
    assert AsyncJob.status(@epool_id, job_id) == {:error, :not_found}
  end
end
