# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.OpenApiInProcessTest do
  use ExUnit.Case

  test "GET should succeed via InProcessClient" do
    expected = "hoge"
    res = OpenApiAssertInProcess.get_for_success(OpenApiAssertInProcess.find_api("oneGet"), "/openapi/path1/one?required=#{expected}")
    assert res.status == 200
    assert Jason.decode!(res.body)["required"] == expected
  end

  test "POST should succeed via InProcessClient" do
    res = OpenApiAssertInProcess.post_json_for_success(OpenApiAssertInProcess.find_api("onePost"), "/openapi/path1/one?code=200", %{required: "post"})
    assert res.status == 200
    assert Jason.decode!(res.body)["required"] == "string"
  end

  test "POST should return error response via InProcessClient" do
    res = OpenApiAssertInProcess.post_json_for_error(OpenApiAssertInProcess.find_api("onePost"), "/openapi/path1/one?code=400-01", %{required: "post"})
    assert res.status == 400
    assert Jason.decode!(res.body)["code"] == "400-01"
  end

  test "controller action runs in the same process as the test" do
    res = OpenApiAssertInProcess.get_for_success(OpenApiAssertInProcess.find_api("storePid"), "/store_pid")
    assert res.status == 200
    assert Process.get(:controller_pid) == self()
  end
end
