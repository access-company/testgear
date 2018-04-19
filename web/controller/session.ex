# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.Session do
  use SolomonLib.Controller

  plug SolomonLib.Plug.Session, :load, [key: "session"]

  def show(conn) do
    body =
      case Conn.get_req_query(conn, "key") do
        nil -> %{}
        key -> %{key => Conn.get_session(conn, key)}
      end
    Conn.json(conn, 200, body)
  end

  def create(%SolomonLib.Conn{request: request} = conn) do
    Enum.reduce(request.body, conn, fn
      ({k, nil}, c) -> Conn.delete_session(c, k)
      ({k, v  }, c) -> Conn.put_session(c, k, v)
    end)
    |> Conn.json(200, request.body)
  end

  def destroy(conn) do
    conn |> Conn.destroy_session |> Conn.put_status(204)
  end
end
