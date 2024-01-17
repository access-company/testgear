# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.ResponseTest do
  use ExUnit.Case

  @tag :blackbox
  test "should redirect" do
    res1 = Req.get("/redirect")
    assert res1.status == 302
    assert res1.headers["location"] == Testgear.Router.html_path()

    external_url = "http://jp.access-company.com/"
    res2 = Req.get("/redirect?url=#{external_url}")
    assert res2.status == 302
    assert res2.headers["location"] == external_url
  end

  test "should correctly set content-length header and neglect content-length given by gear action" do
    res = Req.get("/incorrect_content_length")
    assert byte_size(res.body) == String.to_integer(res.headers["content-length"])
  end

  test "should correctly set default headers" do
    res1 = Req.get("/json")
    assert res1.headers["x-frame-options"          ] == "DENY"
    assert res1.headers["x-xss-protection"         ] == "1; mode=block"
    assert res1.headers["x-content-type-options"   ] == "nosniff"
    assert res1.headers["strict-transport-security"] == "max-age=31536000"

    res2 = Req.get("/override_default_header")
    assert res2.headers["x-frame-options"          ] == "SAMEORIGIN"
    assert res2.headers["x-xss-protection"         ] == "1; mode=block"
    assert res2.headers["x-content-type-options"   ] == "nosniff"
    assert res2.headers["strict-transport-security"] == "max-age=31536000"
  end
end
