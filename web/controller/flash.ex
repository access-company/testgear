# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.Flash do
  use SolomonLib.Controller

  plug SolomonLib.Plug.Session, :load, [key: "session", store: :cookie]
  plug SolomonLib.Plug.Flash,   :load, []

  def show(conn), do: render(conn, 200, "flash", [])

  def with_notice(conn) do
    conn
    |> put_flash("notice", "message")
    |> render(200, "flash", [])
  end

  def redirect(conn) do
    conn
    |> put_flash("notice", "message")
    |> redirect("/flash")
  end
end