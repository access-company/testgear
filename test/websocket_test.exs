# Copyright(c) 2015-2020 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.WebsocketTest do
  use ExUnit.Case
  alias Antikythera.Test.ProcessHelper
  alias AntikytheraCore.ExecutorPool.RegisteredName, as: RegName
  alias AntikytheraCore.ExecutorPool.WebsocketConnectionsCounter

  defp connect(name) do
    Socket.spawn_link("/ws?name=#{name}", 10_000)
  end

  @tag :blackbox
  test "websocket handshake should process plugs" do
    catch_error Socket.spawn_link("/ws")
  end

  @tag :blackbox
  test "websocket connection should respond ping with pong" do
    client_pid = connect("foo")
    Socket.send_frame(client_pid, :ping)
    assert_receive({{:pong, ""}, ^client_pid}, 500)
    Socket.send_frame(client_pid, :close)
    ProcessHelper.monitor_wait(client_pid)
  end

  @tag :blackbox
  test "multiple websocket clients can communicate with each other using the registry" do
    names = Enum.map(1..10, &Integer.to_string/1)
    pairs = Enum.map(names, fn n -> {n, connect(n)} end)

    for {n1, c1} <- pairs, {n2, c2} <- pairs, n1 != n2 do
      msg = "hello from #{n1} to #{n2}"
      Socket.send_json(c1, %{"command" => "send", "to" => n2, "msg" => msg})
      assert_receive({{:text, ^msg}, ^c2}, 500)
    end

    Enum.each(pairs, fn {_, client_pid} ->
      Socket.send_frame(client_pid, :close)
      ProcessHelper.monitor_wait(client_pid)
    end)
  end

  defp server_pid(name) do
    server_pid = Enum.find_value(1..10, fn _ ->
      :timer.sleep(100)
      case :syn.find_by_key({:gear, :testgear, name}) do
        :undefined -> nil
        pid        -> pid
      end
    end)
    assert is_pid(server_pid)
    server_pid
  end

  @ws_counter_name RegName.websocket_connections_counter({:gear, :testgear})

  defp get_connections_count() do
    :sys.get_state(@ws_counter_name)[:count]
  end

  test "websocket connection should send/receive frames" do
    client_pid = connect("foo")
    server_pid = Enum.find_value(1..10, fn _ ->
      :timer.sleep(100)
      case :syn.find_by_key({:gear, :testgear, "foo"}) do
        :undefined -> nil
        pid        -> pid
      end
    end)
    assert is_pid(server_pid)

    Socket.send_json(client_pid, %{"command" => "noop"})
    refute_receive(_)

    m = %{"command" => "echo"}
    Socket.send_json(client_pid, m)
    received =
      receive do
        {{:text, s}, ^client_pid} -> Poison.decode!(s)
      after
        500 -> raise "no text message"
      end
    assert received == m

    send(server_pid, "message")
    assert_receive({{:text, "message"}, ^client_pid}, 500)

    Socket.send_json(client_pid, %{"command" => "close"})
    assert_receive(:disconnected, 500)
    ProcessHelper.monitor_wait(client_pid)
    ProcessHelper.monitor_wait(server_pid)
    refute_receive(_)
  end

  test "number of websocket connections should be counted; connection that exceeds the upper limit should be rejected" do
    max = :sys.get_state(@ws_counter_name)[:max]
    if get_connections_count() != 0 do
      :timer.sleep(500)
      assert get_connections_count() == 0
    end

    client_pids =
      Enum.map(1..max, fn n ->
        pid = connect(Integer.to_string(n))
        assert get_connections_count() == n
        pid
      end)

    # should not establish ws connection any more
    catch_error connect(Integer.to_string(max + 1))
    # the actual HTTP error response should look like the following
    res = Req.get("/ws", %{}, [params: %{"name" => max + 1}])
    assert res.status == 503
    assert res.body   == Poison.encode!(%{error: "ws_too_many_connections"})

    Enum.shuffle(client_pids) |> Enum.each(fn client_pid ->
      count = get_connections_count()
      Socket.send_frame(client_pid, :close)
      ProcessHelper.monitor_wait(client_pid)
      :timer.sleep(10)
      assert get_connections_count() == count - 1
    end)
    assert get_connections_count() == 0
  end

  test "sending too large websocket frame causes the connection to be closed" do
    client_pid = connect("0")
    limit = 5_000_000
    Socket.send_json(client_pid, %{"command" => "noop", "data" => String.duplicate("a", limit - 100_000)})
    _ = :sys.get_state(client_pid)
    assert Process.alive?(client_pid)
    Socket.send_json(client_pid, %{"command" => "noop", "data" => String.duplicate("a", limit + 100_000)})
    ProcessHelper.monitor_wait(client_pid)
  end

  test "error in server-side connection process should close the connection" do
#    Enum.each(["raise", "throw", "exit", "exhaust_heap_memory"], fn command ->
    Enum.each(["exhaust_heap_memory"], fn command ->
      client_pid = connect("foo")
      server_pid = server_pid("foo")
      assert get_connections_count() == 1
      Socket.send_json(client_pid, %{"command" => command})
      assert_receive(:disconnected, 1_000)
      ProcessHelper.monitor_wait(client_pid)
      ProcessHelper.monitor_wait(server_pid)
      :timer.sleep(10)
      assert get_connections_count() == 0
    end)
  end

  test "before host termination active ws connections should be terminated" do
    # should successfully run with no ws connections
    WebsocketConnectionsCounter.gradually_terminate_all_ws_connections()
    assert_receive({:DOWN, _, :process, _, :normal})

    names       = ["foo", "bar", "baz"]
    client_pids = Enum.map(names, &connect/1)
    server_pids = Enum.map(names, &server_pid/1)

    WebsocketConnectionsCounter.gradually_terminate_all_ws_connections()
    Enum.each(server_pids, &ProcessHelper.monitor_wait/1)
    Enum.each(client_pids, fn client_pid ->
      ProcessHelper.monitor_wait(client_pid)
      assert_received(:disconnected)
    end)
    assert_receive({:DOWN, _, :process, _, :normal})
  end
end
