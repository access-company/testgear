# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.FlashTest do
  use ExUnit.Case

  test "flash should not be rendered empty if it is not set" do
    res = Req.get("/flash")
    assert res.status == 200
    assert String.contains?(res.body, "flash_notice=nil")
  end

  test "flash should be rendered if it is set" do
    res = Req.get("/flash/with_notice")
    assert res.status == 200
    assert String.contains?(res.body, "flash_notice=message")
  end

  test "should be rendered at next request of redirect" do
    res1    = Req.get("/flash/redirect")
    cookie1 = Cookie.response_to_request_cookie(res1)

    res2    = Req.get("/flash", cookie1)
    cookie2 = Cookie.response_to_request_cookie(res2)
    assert res2.status == 200
    assert String.contains?(res2.body, "flash_notice=message")

    res3 = Req.get("/flash", cookie2)
    assert res3.status == 200
    assert String.contains?(res3.body, "flash_notice=nil")
  end
end
