# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.ContentDecoding do
  use Antikythera.Controller

  plug Antikythera.Plug.ContentDecoding, :decode, []

  def echo(conn) do
    conn
    |> Conn.put_status(200)
    |> Conn.resp_body(conn.request.body)
  end
end
