# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.ErrorHandlerTest do
  use ExUnit.Case
  alias Antikythera.{Request, Conn}
  alias Antikythera.Test.ConnHelper

  test "web request: error" do
    [
      {"/exception", :error  },
      {"/throw"    , :throw  },
      {"/exit"     , :exit   },
      {"/timeout"  , :timeout},
    ]
    |> Enum.each(fn {path, reason_atom} ->
      res = Req.get(path)
      assert res.status == 500
      assert res.body   == Poison.encode!(%{"from" => "custom_error_handler: #{reason_atom}"})
    end)
  end

  test "web request: no_route" do
    res = Req.get("/no_route_matches")
    assert res.status == 400
    assert res.body   == Poison.encode!(%{error: "no_route"})
  end

  test "web request: bad_request" do
    res = Req.post("/json", "invalid JSON", %{"content-type" => "application/json"})
    assert res.status == 400
    assert res.body   == Poison.encode!(%{error: "bad_request"})
  end

  test "web request: catch exceptions raised by badly implemented error handlers" do
    res1 = Req.get("/exception?raise=true")
    assert res1.status == 500

    res2 = Req.get("/no_route_matches?raise=true")
    assert res2.status == 400

    res3 = Req.post("/json?raise=true", "invalid JSON", %{"content-type" => "application/json"})
    assert res3.status == 400
  end

  test "web request: badly implemented controller action should result in an error" do
    [
      "/incorrect_return",
      "/missing_status_code",
      "/illegal_resp_body",
    ]
    |> Enum.each(fn path ->
      res = Req.get(path)
      assert res.status == 500
      assert res.body   == Poison.encode!(%{"from" => "custom_error_handler: error"})
    end)
  end

  test "web request: return 500 if a status code, which shouldn't have body, returns body" do
    [
      "/json_with_status?status=100",
      "/json_with_status?status=101",
      "/json_with_status?status=204",
      "/json_with_status?status=304",
    ]
    |> Enum.each(fn path ->
      res = Req.get(path)
      assert res.status == 500
    end)
  end

  @tag capture_log: true
  test "web request: heap limit violation should be reported as 500 error" do
    res = Req.get("/exhaust_heap_memory")
    assert res.status == 500
    assert res.body   == Poison.encode!(%{"from" => "custom_error_handler: killed"})
  end

  test "g2g request: error" do
    [
      {"exception", :error  },
      {"throw"    , :throw  },
      {"exit"     , :exit   },
      {"timeout"  , :timeout},
    ]
    |> Enum.each(fn {path_element, reason_atom} ->
      conn = ConnHelper.make_conn(path_info: [path_element], sender: {:gear, :testgear})
      res = Testgear.G2g.send(conn)
      assert res.status == 500
      assert res.body   == %{"from" => "custom_error_handler: #{reason_atom}"}
    end)
  end

  test "g2g request: no_route" do
    conn = ConnHelper.make_conn(path_info: ["no_route_matches"], sender: {:gear, :testgear})
    res = Testgear.G2g.send(conn)
    assert res.status == 400
    assert res.body   == %{"error" => "no_route"}
  end

  test "g2g request: catch exceptions raised by badly implemented error handlers" do
    conn_base = ConnHelper.make_conn(sender: {:gear, :testgear}, query_params: %{"raise" => "true"})
    req_base  = conn_base.request

    res1 = %Conn{conn_base | request: %Request{req_base | path_info: ["exception"]}} |> Testgear.G2g.send()
    assert res1.status == 500

    res2 = %Conn{conn_base | request: %Request{req_base | path_info: ["no_route_matches"]}} |> Testgear.G2g.send()
    assert res2.status == 400
  end

  test "g2g request: badly implemented controller action should result in an error" do
    [
      "incorrect_return",
      "missing_status_code",
      "illegal_resp_body",
    ]
    |> Enum.each(fn path_element ->
      conn = ConnHelper.make_conn(path_info: [path_element], sender: {:gear, :testgear})
      res = Testgear.G2g.send(conn)
      assert res.status == 500
      assert res.body   == %{"from" => "custom_error_handler: error"}
    end)
  end

  @tag capture_log: true
  test "g2g request: heap limit violation should be reported as 500 error" do
    conn = ConnHelper.make_conn(path_info: ["exhaust_heap_memory"], sender: {:gear, :testgear})
    res = Testgear.G2g.send(conn)
    assert res.status == 500
    assert res.body   == %{"from" => "custom_error_handler: killed"}
  end

  test "execute custom error handler when executor_pool_for_web_request/1 returns an unavailable tenant exec pool ID" do
    res = Req.get("/bad_executor_pool_id")
    assert res.status == 400
    assert Poison.decode!(res.body) == %{"error" => "bad_executor_pool_id"}
  end

  test "execute custom error handler when parameter validation fails" do
    [
      {"/params_validation/0?foo=2", ~S({"foo": 3}), %{"content-type" => "application/json", "x-foo" => "4"}, %{"foo" => "5"}, "path_matches", "invalid_value", ["Elixir.Testgear.Controller.ParamsValidation.PathMatches", ["Elixir.Croma.PosInteger", "foo"]]},
      {"/params_validation/1?foo=0", ~S({"foo": 3}), %{"content-type" => "application/json", "x-foo" => "4"}, %{"foo" => "5"}, "query_params", "invalid_value", ["Elixir.Testgear.Controller.ParamsValidation.QueryParams", ["Elixir.Croma.TypeGen.Nilable.Croma.PosInteger", "foo"]]},
      {"/params_validation/1?foo=2", ~S({"foo": 0}), %{"content-type" => "application/json", "x-foo" => "4"}, %{"foo" => "5"}, "body", "invalid_value", ["Elixir.Testgear.Controller.ParamsValidation.StructBody", ["Elixir.Croma.PosInteger", "foo"]]},
      {"/params_validation/1?foo=2", ~S({"foo": 3}), %{"content-type" => "application/json", "x-foo" => "0"}, %{"foo" => "5"}, "headers", "invalid_value", ["Elixir.Testgear.Controller.ParamsValidation.Headers", ["Elixir.Croma.PosInteger", "x-foo"]]},
      {"/params_validation/1?foo=2", ~S({"foo": 3}), %{"content-type" => "application/json", "x-foo" => "4"}, %{"foo" => "0"}, "cookies", "invalid_value", ["Elixir.Testgear.Controller.ParamsValidation.Cookies", ["Elixir.Croma.PosInteger", "foo"]]},

      {"/params_validation/1?foo=2", ~S({}), %{"content-type" => "application/json", "x-foo" => "4"}, %{"foo" => "5"}, "body", "value_missing", ["Elixir.Testgear.Controller.ParamsValidation.StructBody", ["Elixir.Croma.PosInteger", "foo"]]},
      {"/params_validation/1?foo=2", ~S({"foo": 3}), %{"content-type" => "application/json"}, %{"foo" => "5"}, "headers", "value_missing", ["Elixir.Testgear.Controller.ParamsValidation.Headers", ["Elixir.Croma.PosInteger", "x-foo"]]},
      {"/params_validation/1?foo=2", ~S({"foo": 3}), %{"content-type" => "application/json", "x-foo" => "4"}, %{}, "cookies", "value_missing", ["Elixir.Testgear.Controller.ParamsValidation.Cookies", ["Elixir.Croma.PosInteger", "foo"]]},

      {"/list_body_validation", ~S({}), %{"content-type" => "application/json"}, %{}, "body", "invalid_value", ["Elixir.Testgear.Controller.ParamsValidation.ListBody"]},

      {"/map_body_validation", ~S([]), %{"content-type" => "application/json"}, %{}, "body", "invalid_value", ["Elixir.Testgear.Controller.ParamsValidation.MapBody"]},
    ]
    |> Enum.each(fn {path, body, headers, cookies, parameter_type, reason_type, mods} ->
      res = Req.post(path, body, headers, cookie: cookies)
      assert res.status == 400
      assert Poison.decode!(res.body) == %{
        "error" => "parameter_validation_error",
        "parameter_type" => parameter_type,
        "reason" => %{
          "type" => reason_type,
          "mods" => mods
        }
      }
    end)
  end
end
