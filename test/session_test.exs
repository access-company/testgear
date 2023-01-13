# Copyright(c) 2015-2023 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.SessionTest do
  use ExUnit.Case
  alias Antikythera.G2gRequest, as: GR

  @g2g_context Antikythera.Test.ConnHelper.make_conn(%{sender: {:gear, :sender_gear}, gear_name: :sender_gear}).context

  test "session should return nil if session is not created" do
    res      = Req.get("/session?key=key")
    res_json = Poison.decode!(res.body)
    assert res.status == 200
    assert res_json   == %{"key" => nil}
  end

  test "session should return saved value if session is created" do
    res1      = Req.post_json("/session", %{"key" => "value"})
    res_json1 = Poison.decode!(res1.body)
    assert res1.status == 200
    assert res_json1   == %{"key" => "value"}
    assert Cookie.valid?(res1, "session")

    res2      = Req.get("/session?key=key", Cookie.response_to_request_cookie(res1))
    res_json2 = Poison.decode!(res2.body)
    assert res2.status == 200
    assert res_json2   == %{"key" => "value"}

    res3      = Req.post_json("/session", %{"key" => "value2"}, Cookie.response_to_request_cookie(res2))
    res_json3 = Poison.decode!(res3.body)
    assert res3.status == 200
    assert res_json3   == %{"key" => "value2"}

    res4      = Req.get("/session?key=key", Cookie.response_to_request_cookie(res3))
    res_json4 = Poison.decode!(res4.body)
    assert res4.status == 200
    assert res_json4   == %{"key" => "value2"}
  end

  test "session should return nil if session value is deleted" do
    res1      = Req.post_json("/session", %{"key" => "value"})
    res2      = Req.get("/session?key=key", Cookie.response_to_request_cookie(res1))
    res_json2 = Poison.decode!(res2.body)
    assert res2.status == 200
    assert res_json2   == %{"key" => "value"}

    res3      = Req.post_json("/session", %{"key" => nil}, Cookie.response_to_request_cookie(res2))
    res4      = Req.get("/session?key=key", Cookie.response_to_request_cookie(res3))
    res_json4 = Poison.decode!(res4.body)
    assert res4.status == 200
    assert res_json4   == %{"key" => nil}
  end

  test "session value in cookie should be expired if session is destroyed" do
    res1 = Req.post_json("/session", %{"key" => "value"})
    res2 = Req.delete("/session", Cookie.response_to_request_cookie(res1))
    assert res2.status == 204
    assert Cookie.expired?(res2, "session")
  end

  test "session should return saved value if session is created (request from gear)" do
    req1 = GR.new!(method: :post, path: "/session", body: %{"key" => "value"})
    res1 = Testgear.G2g.send(req1, @g2g_context)
    assert res1.status == 200
    assert res1.body   == %{"key" => "value"}
    assert Map.has_key?(res1.cookies, "session")
    res1_cookies = Map.new(res1.cookies, fn {n, c} -> {n, c.value} end)

    req2 = GR.new!(method: :get, path: "/session", query_params: %{"key" => "key"}, cookies: res1_cookies)
    res2 = Testgear.G2g.send(req2, @g2g_context)
    assert res2.status == 200
    assert res2.body   == %{"key" => "value"}
    res2_cookies = Enum.into(res2.cookies, res1_cookies, fn {n, c} -> {n, c.value} end)

    req3 = GR.new!(method: :post, path: "/session", cookies: res2_cookies, body: %{"key" => "value2"})
    res3 = Testgear.G2g.send(req3, @g2g_context)
    assert res3.status == 200
    assert res3.body   == %{"key" => "value2"}
    res3_cookies = Enum.into(res3.cookies, res2_cookies, fn {n, c} -> {n, c.value} end)

    req4 = GR.new!(method: :get, path: "/session", query_params: %{"key" => "key"}, cookies: res3_cookies)
    res4 = Testgear.G2g.send(req4, @g2g_context)
    assert res4.status == 200
    assert res4.body   == %{"key" => "value2"}
  end

  test "session_with_set_cookie_option should add an option to the set-cookie header" do
    # We ensure that max-age is not set by default.
    res0 = Req.get("/session")
    assert res0.status == 200
    session0 = res0.cookies["session"]
    assert session0.max_age == nil

    res1 = Req.get("/session_with_set_cookie_option")
    assert res1.status == 200
    session1 = res1.cookies["session"]
    assert session1.max_age == 7200
  end
end
