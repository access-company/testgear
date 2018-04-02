# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.BasicAuthentication do
  use SolomonLib.Controller
  alias SolomonLib.Plug.BasicAuthentication, as: BAuth

  plug BAuth, :check_with_config  , []                             , except: [:check_with_fun   ]
  plug BAuth, :check_with_fun     , [mod: __MODULE__, fun: :check3], except: [:check_with_config]

  def check_with_config(conn) do
    json(conn, 200, %{})
  end

  def check_with_fun(conn) do
    %Conn{assigns: %{foo: "foo"}} = conn # check that the value has been assigned
    json(conn, 200, %{})
  end

  def check3(conn, "admin", "password") do
    {:ok, Conn.assign(conn, :foo, "foo")}
  end
  def check3(_conn, _, _), do: :error
end
