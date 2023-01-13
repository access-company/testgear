# Copyright(c) 2015-2023 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.GearMetricsTest do
  use ExUnit.Case
  alias Antikythera.Time
  alias Antikythera.G2gRequest, as: GReq
  alias Antikythera.Test.{ConnHelper, GenServerHelper}
  alias AntikytheraCore.Cluster.NodeId
  alias AntikytheraCore.ExecutorPool.RegisteredName, as: RegName
  alias AntikytheraEal.MetricsStorage, as: Storage
  alias Testgear.TestAsyncJob

  setup_all do
    now = Time.now()
    _ = Storage.Memory.download(:testgear, {:gear, :testgear}, now, now) # ensure that the agent is started
  end

  setup do
    :meck.new(Time, [:passthrough])
    on_exit(&:meck.unload/0)
  end

  defp clear_existing_metrics() do
    Agent.update(Storage.Memory, fn _ -> %{} end)
  end

  defp set_clock_ahead_and_force_flush(t) do
    :meck.expect(Time, :now, fn -> t end)
    GenServerHelper.send_message_and_wait(Testgear.MetricsUploader, :flush_data)
  end

  defp accumulate_metrics(f) do
    t1 = Time.truncate_to_minute(Time.now())
    t2 = Time.shift_minutes(t1, 1)
    t3 = Time.shift_minutes(t1, 2)
    set_clock_ahead_and_force_flush(t2)
    clear_existing_metrics()

    f.()

    set_clock_ahead_and_force_flush(t3)
    [{_time, doc}] = Storage.Memory.download(:testgear, {:gear, :testgear}, t1, t2)
    assert doc["node_id"     ] == NodeId.get()
    assert doc["otp_app_name"] == "testgear"
    assert doc["epool_id"    ] == "gear-testgear"
    doc
  end

  test "should report web/g2g request metrics and custom metrics" do
    doc =
      accumulate_metrics(fn ->
        greq = GReq.new!([method: :get, path: "/json"])
        context = ConnHelper.make_conn(%{sender: {:gear, :sender_gear}, gear_name: :sender_gear}).context
        Enum.each(1..5, fn _ ->
          assert Req.get("/json")                .status == 200
          assert Testgear.G2g.send(greq, context).status == 200
          assert Req.get("/report_metric")       .status == 200
        end)
        assert Req.get("/bad_request").status == 400
        assert Req.get("/exception"  ).status == 500
      end)

    assert doc["web_request_count_total" ] == 11
    assert doc["web_request_count_4XX"   ] == 0 # Early return due to bad_request/no_route will not be counted
    assert doc["web_request_count_5XX"   ] == 1
    assert doc["g2g_request_count_total" ] == 5
    assert doc["g2g_request_count_4XX"   ] == 0
    assert doc["g2g_request_count_5XX"   ] == 0
    assert doc["custom_report_metric_sum"] == 5
    assert Map.has_key?(doc, "web_response_time_ms_max")
    assert Map.has_key?(doc, "web_response_time_ms_avg")
    assert Map.has_key?(doc, "web_response_time_ms_95%")
    assert Map.has_key?(doc, "g2g_response_time_ms_max")
    assert Map.has_key?(doc, "g2g_response_time_ms_avg")
    assert Map.has_key?(doc, "g2g_response_time_ms_95%")
  end

  test "should report websocket frames count" do
    doc =
      accumulate_metrics(fn ->
        client_pid = Socket.spawn_link("/ws?name=foo")
        Enum.each(1..5, fn _ ->
          Socket.send_json(client_pid, %{"command" => "noop"})
          refute_received(_)
        end)
        Enum.each(1..5, fn _ ->
          Socket.send_json(client_pid, %{"command" => "echo"})
          assert_receive({{:text, _}, ^client_pid}, 500)
        end)
        Socket.send_frame(client_pid, :close)
        assert_receive(:disconnected, 500)
      end)

    assert doc["websocket_frames_received_sum"] == 10
    assert doc["websocket_frames_sent_sum"    ] == 5
  end

  defp wait_until_runners_terminated(pool_name, n \\ 10) do
    if n == 0 do
      raise "async job runners haven't been terminated!"
    else
      case PoolSup.status(pool_name) do
        %{working: 0} -> :ok
        _             ->
          :timer.sleep(100)
          wait_until_runners_terminated(pool_name, n - 1)
      end
    end
  end

  test "should report async job metrics" do
    doc =
      accumulate_metrics(fn ->
        epool_id = {:gear, :testgear}
        Process.register(self(), TestAsyncJob)
        Enum.each(1..5, fn _ ->
          {:ok, _} = TestAsyncJob.register(%{todo: :send}, epool_id)
          assert_receive({:executing, _}, 500) # use longer timeout for CircleCI
        end)
        wait_until_runners_terminated(RegName.async_job_runner_pool(epool_id))
      end)

    assert doc["async_job_success_sum"] == 5
    assert Map.has_key?(doc, "async_job_execution_time_ms_max")
    assert Map.has_key?(doc, "async_job_execution_time_ms_avg")
    assert Map.has_key?(doc, "async_job_execution_time_ms_95%")
  end
end
