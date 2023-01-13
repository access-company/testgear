# Copyright(c) 2015-2023 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.CookieTest do
  use ExUnit.Case

  test "cookie of request should not automatically be set to response header" do
    res = Req.get("/json", %{"cookie" => "foo=bar"})
    assert res.status  == 200
    assert res.cookies == %{}
  end

  test "cookie with forbidden characters should be registered" do
    key       = "key_()<>@,;:\\<>/[]?={} "
    value     = "val_()<>@,;:\\<>/[]?={} "
    res1      = Req.post_json("/cookie", %{key => value})
    res_json1 = Poison.decode!(res1.body)
    assert res1.status    == 200
    assert res_json1[key] == value

    query     = URI.encode_query(%{key: key})
    res2      = Req.get("/cookie?#{query}", Cookie.response_to_request_cookie(res1))
    res_json2 = Poison.decode!(res2.body)
    assert res2.status    == 200
    assert res_json2[key] == value
  end

  test "deleted cookie should be expired" do
    res = Req.delete("/cookie?key=foo", %{"cookie" => "foo=bar"})
    assert res.status == 200
    assert Cookie.expired?(res, "foo")
  end

  test "should be able to set multiple cookies at once" do
    res = Req.get("/multiple_cookies")
    assert res.status == 200
    assert res.cookies["k1"].value == "v1"
    assert res.cookies["k2"].value == "v2"
    assert res.cookies["k3"].value == "v3"
  end
end
