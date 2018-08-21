# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.Error do
  use Antikythera.Controller

  def error(conn, _reason) do
    Conn.json(conn, 500, %{from: "custom_error_handler"})
  end

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

  def no_route(conn) do
    Conn.json(conn, 400, %{error: "no_route"})
  end

  def bad_request(conn) do
    Conn.json(conn, 400, %{error: "bad_request"})
  end

  def bad_executor_pool_id(conn, _reason) do
    Conn.json(conn, 400, %{error: "bad_executor_pool_id"})
  end

  def ws_too_many_connections(conn) do
    Conn.json(conn, 503, %{error: "ws_too_many_connections"})
  end

  def incorrect_return(conn) do
    {:ok, Conn.put_status(conn, 200)}
  end

  def exhaust_heap_memory(conn) do
    Testgear.Util.exhaust_heap_memory()
    Conn.json(conn, 200, %{"message" => "this body won't be returned"})
  end

  def blackbox_test_for_nonexisting_tenant(_conn) do
    raise "should not be called"
  end
end
