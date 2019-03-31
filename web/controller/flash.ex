# Copyright(c) 2015-2019 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.Flash do
  use Antikythera.Controller

  plug Antikythera.Plug.Session, :load, [key: "session", store: :cookie]
  plug Antikythera.Plug.Flash,   :load, []

  def show(conn), do: Conn.render(conn, 200, "flash", [])

  def with_notice(conn) do
    conn
    |> Conn.put_flash("notice", "message")
    |> Conn.render(200, "flash", [])
  end

  def redirect(conn) do
    conn
    |> Conn.put_flash("notice", "message")
    |> Conn.redirect("/flash")
  end
end
