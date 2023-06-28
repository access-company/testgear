# Copyright(c) 2015-2023 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.Error do
  use Antikythera.Controller

  def action_exception(_conn) do
    raise "error!"
  end

  def action_throw(_conn) do
    throw "error!"
  end

  def action_exit(_conn) do
    exit "error!"
  end

  def action_timeout(_conn) do
    :timer.sleep(11_000)
  end

  def error(conn, reason) do
    raise_if_told(conn, fn ->
      reason_atom =
        case reason do
          {kind, _} -> kind
          atom      -> atom
        end
      Conn.json(conn, 500, %{from: "custom_error_handler: #{reason_atom}"})
    end)
  end

  def no_route(conn) do
    raise_if_told(conn, fn ->
      Conn.json(conn, 400, %{error: "no_route"})
    end)
  end

  def bad_request(conn) do
    raise_if_told(conn, fn ->
      Conn.json(conn, 400, %{error: "bad_request"})
    end)
  end

  def bad_executor_pool_id(conn, _reason) do
    raise_if_told(conn, fn ->
      Conn.json(conn, 400, %{error: "bad_executor_pool_id"})
    end)
  end

  def ws_too_many_connections(conn) do
    raise_if_told(conn, fn ->
      Conn.json(conn, 503, %{error: "ws_too_many_connections"})
    end)
  end

  defp raise_if_told(conn, f) do
    if Map.get(conn.request.query_params, "raise") do
      raise "exception raised in error handler function!"
    else
      f.()
    end
  end

  def incorrect_return(conn) do
    {:ok, Conn.put_status(conn, 200)}
  end

  def json_with_status(conn) do
    status_string = Conn.get_req_query(conn, "status") || "200"
    {status, _} = Integer.parse(status_string)
    Conn.json(conn, status, %{})
  end

  def missing_status_code(conn) do
    %Conn{conn | resp_body: "missing_status_code"}
  end

  def illegal_resp_body(conn) do
    %Conn{conn | status: 200, resp_body: %{"resp_body can't be a map" => "should instead be a binary"}}
  end

  def exhaust_heap_memory(conn) do
    Testgear.Util.exhaust_heap_memory()
    Conn.json(conn, 200, %{"message" => "this body won't be returned"})
  end
end
