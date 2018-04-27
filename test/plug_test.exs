# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.PlugTest do
  use ExUnit.Case
  alias Antikythera.G2gRequest, as: GReq

  @triplets [
    {"/action1_with_plug", %{"plug" => "proceed"}, 200, Poison.encode!(%{msg: "OK"})},
    {"/action1_with_plug", %{"plug" => "halt"   }, 400, ""                          },
    {"/action2_with_plug", %{}                   , 200, Poison.encode!(%{msg: "OK"})},
  ]

  test "should execute plugs in the order they are specified in controller (web)" do
    for {path, req_body, resp_status, resp_body} <- @triplets do
      res = Req.post_json(path, req_body)
      assert res.status == resp_status
      assert res.body   == resp_body
    end
  end

  test "should handle error during plug (web)" do
    [
      "/action_plug_error",
      "/action_plug_before_send_error",
    ] |> Enum.each(fn path ->
      res = Req.get(path)
      assert res.status == 500
      assert res.body   == ~S|{"from":"custom_error_handler"}|
    end)
  end

  @context Antikythera.Test.ConnHelper.make_conn().context

  defp g2g_post_json(path, body) do
    GReq.new!([method: :post, path: path, body: body]) |> Testgear.G2g.send(@context)
  end

  test "should execute plug in the order they are specified in controller (g2g)" do
    for {path, req_body, resp_status, resp_body} <- @triplets do
      res = g2g_post_json(path, req_body)
      assert res.status == resp_status
      expected_body = if is_map(res.body), do: Poison.decode!(resp_body), else: resp_body
      assert res.body == expected_body
    end
  end

  test "should handle error during plug (g2g)" do
    [
      "/action_plug_error",
      "/action_plug_before_send_error",
    ] |> Enum.each(fn path ->
      res = GReq.new!([method: :get, path: path, body: ""]) |> Testgear.G2g.send(@context)
      assert res.status == 500
      assert res.body   == %{"from" => "custom_error_handler"}
    end)
  end

  test "NoCache should set cache-control response header" do
    res1 = Req.post_json("/action1_with_plug", %{"plug" => "proceed"})
    assert res1.status == 200
    assert res1.headers["cache-control"] == Antikythera.Plug.NoCache.header_value()

    res2 = Req.post_json("/action2_with_plug", %{})
    assert res2.status == 200
    refute Map.has_key?(res2.headers, "cache-control")
  end
end
