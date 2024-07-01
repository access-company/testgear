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

  test "should fail validation if some parameters are invalid" do
    [
      {"/params_validation/invalid?foo=2", ~S({"foo": 3}), %{"content-type" => "application/json", "x-foo" => "4"}, %{"foo" => "5"}, "path_matches", ["Elixir.Testgear.Controller.ParamsValidation.PathMatches", ["Elixir.Croma.PosInteger", "foo"]]},
      {"/params_validation/1?foo=invalid", ~S({"foo": 3}), %{"content-type" => "application/json", "x-foo" => "4"}, %{"foo" => "5"}, "query_params", ["Elixir.Testgear.Controller.ParamsValidation.QueryParams", ["Elixir.Croma.TypeGen.Nilable.Croma.PosInteger", "foo"]]},
      {"/params_validation/1?foo=2", ~S({"foo": "invalid"}), %{"content-type" => "application/json", "x-foo" => "4"}, %{"foo" => "5"}, "body", ["Elixir.Testgear.Controller.ParamsValidation.StructBody", ["Elixir.Croma.PosInteger", "foo"]]},
      {"/params_validation/1?foo=2", ~S({"foo": 3}), %{"content-type" => "application/json", "x-foo" => "invalid"}, %{"foo" => "5"}, "headers", ["Elixir.Testgear.Controller.ParamsValidation.Headers", ["Elixir.Croma.PosInteger", "x-foo"]]},
      {"/params_validation/1?foo=2", ~S({"foo": 3}), %{"content-type" => "application/json", "x-foo" => "4"}, %{"foo" => "invalid"}, "cookies", ["Elixir.Testgear.Controller.ParamsValidation.Cookies", ["Elixir.Croma.PosInteger", "foo"]]},

      {"/list_body_validation", ~S({}), %{"content-type" => "application/json"}, %{}, "body", ["Elixir.Testgear.Controller.ParamsValidation.ListBody"]},

      {"/map_body_validation", ~S([]), %{"content-type" => "application/json"}, %{}, "body", ["Elixir.Testgear.Controller.ParamsValidation.MapBody"]},
    ]
    |> Enum.each(fn {path, body, headers, cookies, parameter_type, mods} ->
      res = Req.post(path, body, headers, cookie: cookies)
      assert res.status == 400
      assert %{
        "parameter_type" => ^parameter_type,
        "reason" => %{
          "type" => "invalid_value",
          "mods" => ^mods
        }
      } = Poison.decode!(res.body)
    end)
  end

  test "should fail validation if some required parameters are missing" do
    [

      {"/params_validation/1?foo=2", ~S({}), %{"content-type" => "application/json", "x-foo" => "4"}, %{"foo" => "5"}, "body", ["Elixir.Testgear.Controller.ParamsValidation.StructBody", ["Elixir.Croma.PosInteger", "foo"]]},
      {"/params_validation/1?foo=2", ~S({"foo": 3}), %{"content-type" => "application/json"}, %{"foo" => "5"}, "headers", ["Elixir.Testgear.Controller.ParamsValidation.Headers", ["Elixir.Croma.PosInteger", "x-foo"]]},
      {"/params_validation/1?foo=2", ~S({"foo": 3}), %{"content-type" => "application/json", "x-foo" => "4"}, %{}, "cookies", ["Elixir.Testgear.Controller.ParamsValidation.Cookies", ["Elixir.Croma.PosInteger", "foo"]]}
    ]
    |> Enum.each(fn {path, body, headers, cookies, parameter_type, mods} ->
      res = Req.post(path, body, headers, cookie: cookies)
      assert res.status == 400
      assert %{
        "parameter_type" => ^parameter_type,
        "reason" => %{
          "type" => "value_missing",
          "mods" => ^mods
        }
      } = Poison.decode!(res.body)
    end)
  end
end
