# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.Cookie do
  use SolomonLib.Controller

  def show(conn) do
    body =
      case Conn.get_req_query(conn, "key") do
        nil -> %{}
        key -> %{key => Conn.get_req_cookie(conn, key)}
      end
    Conn.json(conn, 200, body)
  end

  def create(%SolomonLib.Conn{request: request} = conn) do
    Enum.reduce(request.body, conn, fn {k, v}, c -> Conn.put_resp_cookie(c, k, v) end)
    |> Conn.json(200, request.body)
  end

  def destroy(conn) do
    case Conn.get_req_query(conn, "key") do
      nil -> Conn.json(conn, 200, %{})
      key -> Conn.put_resp_cookie_to_revoke(conn, key) |> Conn.json(200, %{})
    end
  end

  def multiple_cookies(conn) do
    conn
    |> Conn.put_resp_cookie("k1", "v1")
    |> Conn.put_resp_cookie("k2", "v2")
    |> Conn.put_resp_cookie("k3", "v3")
    |> Conn.put_status(200)
  end
end
