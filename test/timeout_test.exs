# Copyright(c) 2015-2023 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.TimeoutTest do
  use ExUnit.Case
  alias Antikythera.Test.ConnHelper

  test "web request: return 200 when timeout is longer than the response time" do
    res = Req.get("/timeout_long", %{}, recv_timeout: 13_000)
    assert res.status == 200
    assert res.body   == Poison.encode!(%{})
  end

  test "g2g request: return 200 when timeout is longer than the response time" do
    conn = ConnHelper.make_conn(path_info: ["timeout_long"], sender: {:gear, :testgear})
    res  = Testgear.G2g.send(conn)
    assert res.status == 200
    assert res.body   == %{}
  end
end
