# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.ParamsValidationTest do
  use ExUnit.Case

  test "should parse params and pass if the parameters are all valid" do
    res = Req.post_json("/params_validation/1?foo=2", %{foo: 3}, %{"x-foo" => "4"}, cookie: %{"foo" => "5"})

    assert res.status == 200
    assert Poison.decode!(res.body) == %{
      "path_matches" => 1,
      "query_params" => 2,
      "body"         => 3,
      "headers"      => 4,
      "cookies"      => 5
    }
  end

  test "should pass validation if the nilable parameter is not given" do
    res = Req.post_json("/params_validation/1", %{foo: 3}, %{"x-foo" => "4"}, cookie: %{"foo" => "5"})

    assert res.status == 200
    assert Poison.decode!(res.body) == %{
      "path_matches" => 1,
      "query_params" => nil,
      "body"         => 3,
      "headers"      => 4,
      "cookies"      => 5
    }
  end

  test "should pass validation if the list body is valid" do
    res = Req.post("/list_body_validation", ~S([1, 2, 3]), %{"content-type" => "application/json"})

    assert res.status == 200
    assert Poison.decode!(res.body) == %{"body" => [1, 2, 3]}
  end

  test "should pass validation if the map body is valid" do
    res = Req.post("/map_body_validation", ~S({"a": 1, "b": 2, "c": 3}), %{"content-type" => "application/json"})

    assert res.status == 200
    assert Poison.decode!(res.body) == %{"body" => %{"a" => 1, "b" => 2, "c" => 3}}
  end
end
