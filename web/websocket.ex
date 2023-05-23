# Copyright(c) 2015-2023 ACCESS CO., LTD. All rights reserved.

use Croma

defmodule Testgear.Websocket do
  use Antikythera.Websocket
  alias Antikythera.Registry.{Group, Unique}
  alias Testgear.{Logger, Util}

  plug __MODULE__, :reject_request_without_name_and_group_name_parameter, []

  def reject_request_without_name_and_group_name_parameter(%Conn{request: request} = conn, _opts) do
    Logger.info("should be able to emit log in websocket connect/0 callback")
    if Map.has_key?(request.query_params, "name") or Map.has_key?(request.query_params, "group_name") do
      conn
    else
      Conn.put_status(conn, 400)
    end
  end

  @impl true
  def init(%Conn{request: request, context: context}) do
    Logger.info("should be able to emit log in websocket connection process")
    if Map.has_key?(request.query_params, "name") do
      :ok = Unique.register(request.query_params["name"], context)
    else
      :ok = Group.join(request.query_params["group_name"], context)
    end
    {%{}, []}
  end

  defp handle_command(%{"command" => "close"}, _context, _frame) do
    [:close]
  end

  defp handle_command(%{"command" => "noop"}, _context, _frame) do
    []
  end

  defp handle_command(%{"command" => "echo"}, _context, frame) do
    [frame]
  end

  defp handle_command(%{"command" => "send", "to" => name, "msg" => msg}, context, _frame) do
    Unique.send_message(name, context, msg)
    []
  end

  defp handle_command(%{"command" => "send_group", "to" => name, "msg" => msg}, context, _frame) do
    Group.publish(name, context, msg)
    []
  end

  defp handle_command(%{"command" => "raise"}, _context, _frame) do
    raise "ws failed!"
  end

  defp handle_command(%{"command" => "throw"}, _context, _frame) do
    throw "ws failed!"
  end

  defp handle_command(%{"command" => "exit"}, _context, _frame) do
    exit("ws failed!")
  end

  defp handle_command(%{"command" => "exhaust_heap_memory"}, _context, _frame) do
    Util.exhaust_heap_memory()
  end

  @impl true
  def handle_client_message(state, %Conn{context: context}, {:text, s} = frame) do
    Logger.info("should be able to emit log in websocket connection process")
    frames = Poison.decode!(s) |> handle_command(context, frame)
    {state, frames}
  end

  @impl true
  def handle_server_message(state, _conn, msg) do
    Logger.info("should be able to emit log in websocket connection process")
    {state, [{:text, msg}]}
  end
end
