# Copyright(c) 2015-2020 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.BasicAuthenticationTest do
  use ExUnit.Case
  alias Antikythera.Httpc

  @path_list ["/basic_authentication_with_config", "/basic_authentication_with_fun"]

  test "should pass basic authentication" do
    credential = "Basic " <> Base.encode64("admin:password")
    Enum.each(@path_list, fn path ->
      res = Req.get(path, %{"authorization" => credential})
      assert res.status == 200
    end)
  end

  test "should return 401 status if authorization key is invalid" do
    invalid_credential = "Basic " <> Base.encode64("admin:invalid_password")
    Enum.each(@path_list, fn path ->
      %Httpc.Response{status: status, headers: headers, body: body} = Req.get(path, %{"authorization" => invalid_credential})
      assert status == 401
      assert body   == "Access denied."
      Enum.member?(headers, {"www-authenticate", ~S(Basic realm="testgear")})
    end)
  end

  test "should return 401 status if authorization key doesn't exist" do
    %Httpc.Response{status: status, headers: headers, body: body} = Req.get("/basic_authentication_with_config")
    assert status == 401
    assert body   == "Access denied."
    Enum.member?(headers, {"www-authenticate", ~S(Basic realm="testgear")})
  end
end
