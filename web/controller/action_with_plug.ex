# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.ActionWithPlug do
  use SolomonLib.Controller
  alias SolomonLib.Plug.NoCache
  alias Testgear.Logger

  def plug1(conn, [option: s]) do
    Logger.info("should be able to emit log in plug")
    conn
    |> assign(:already_called, s)
    |> register_before_send(fn c ->
      Logger.info("should be able to emit log in before_send callback")
      c
    end)
  end

  defmodule OtherModule do
    def plug2(conn, [option: s]) do
      %{already_called: "plug1"} = conn.assigns
      case conn.request.body["plug"] do
        "proceed" -> put_resp_header(conn, "already_called", s)
        "halt"    -> put_status(conn, 400)
      end
    end
  end

  def plug_error(_conn, _) do
    raise "plug_error"
  end

  def plug_before_send_error(conn, _) do
    Conn.register_before_send(conn, fn _c ->
      raise "plug_before_send_error"
    end)
  end

  # testing `NoCache` plug and `:only` option
  plug NoCache, :put_resp_header, [], only: [:action1]

  # testing `:except` option
  plug __MODULE__ , :plug1, [option: "plug1"], except: [          :action_plug_error, :action_plug_before_send_error]
  plug OtherModule, :plug2, [option: "plug2"], except: [:action2, :action_plug_error, :action_plug_before_send_error]

  def action1(conn) do
    %{already_called: "plug1"}     = conn.assigns
    %{"already_called" => "plug2"} = conn.resp_headers
    json(conn, 200, %{msg: "OK"})
  end

  def action2(conn) do
    %{already_called: "plug1"} = conn.assigns
    nil = conn.resp_headers["already_called"]
    json(conn, 200, %{msg: "OK"})
  end

  # testing error handling in plug execution
  plug __MODULE__, :plug_error            , [], except: [:action1, :action2,                     :action_plug_before_send_error]
  plug __MODULE__, :plug_before_send_error, [], except: [:action1, :action2, :action_plug_error                                ]

  def action_plug_error(conn) do
    json(conn, 200, %{msg: "OK"})
  end

  def action_plug_before_send_error(conn) do
    json(conn, 200, %{msg: "OK"})
  end
end
