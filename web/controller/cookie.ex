# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.Cookie do
  use SolomonLib.Controller

  def show(conn) do
    case get_req_query(conn, "key") do
      nil -> json(conn, 200, %{})
      key -> json(conn, 200, %{key => get_req_cookie(conn, key)})
    end
  end

  def create(%SolomonLib.Conn{request: request} = conn) do
    Enum.reduce(request.body, conn, fn {k, v}, c -> put_resp_cookie(c, k, v) end)
    |> json(200, request.body)
  end

  def destroy(conn) do
    case get_req_query(conn, "key") do
      nil -> json(conn, 200, %{})
      key -> put_resp_cookie_to_revoke(conn, key) |> json(200, %{})
    end
  end

  def multiple_cookies(conn) do
    conn
    |> put_resp_cookie("k1", "v1")
    |> put_resp_cookie("k2", "v2")
    |> put_resp_cookie("k3", "v3")
    |> put_status(200)
  end
end
