# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

use Croma

defmodule Testgear.Websocket do
  use Antikythera.Websocket
  alias Antikythera.Registry.Unique
  alias Testgear.{Logger, Util}

  plug __MODULE__, :reject_request_without_name_parameter, []

  def reject_request_without_name_parameter(%Conn{request: request} = conn, _opts) do
    Logger.info("should be able to emit log in websocket connect/0 callback")
    if Map.has_key?(request.query_params, "name") do
      conn
    else
      Conn.put_status(conn, 400)
    end
  end

  @impl true
  def init(%Conn{request: request, context: context}) do
    Logger.info("should be able to emit log in websocket connection process")
    :ok = Unique.register(request.query_params["name"], context)
    {%{}, []}
  end

  @impl true
  def handle_client_message(state, %Conn{context: context}, {:text, s} = frame) do
    Logger.info("should be able to emit log in websocket connection process")
    frames =
      case Poison.decode!(s) do
        %{"command" => "close"}                            -> [:close]
        %{"command" => "noop"}                             -> []
        %{"command" => "echo"}                             -> [frame]
        %{"command" => "send", "to" => name, "msg" => msg} -> Unique.send_message(name, context, msg); []
        %{"command" => "raise"}                            -> raise "ws failed!"
        %{"command" => "throw"}                            -> throw "ws failed!"
        %{"command" => "exit"}                             -> exit("ws failed!")
        %{"command" => "exhaust_heap_memory"}              -> Util.exhaust_heap_memory()
      end
    {state, frames}
  end

  @impl true
  def handle_server_message(state, _conn, msg) do
    Logger.info("should be able to emit log in websocket connection process")
    {state, [{:text, msg}]}
  end
end
