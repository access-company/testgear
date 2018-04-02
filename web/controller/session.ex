# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.Session do
  use SolomonLib.Controller

  plug SolomonLib.Plug.Session, :load, [key: "session"]

  def show(conn) do
    case get_req_query(conn, "key") do
      nil -> json(conn, 200, %{})
      key -> json(conn, 200, %{key => get_session(conn, key)})
    end
  end

  def create(%SolomonLib.Conn{request: request} = conn) do
    Enum.reduce(request.body, conn, fn
      {k, nil}, c -> delete_session(c, k)
      {k, v},   c -> put_session(c, k, v)
    end)
    |> json(200, request.body)
  end

  def destroy(conn) do
    conn |> destroy_session |> put_status(204)
  end
end
