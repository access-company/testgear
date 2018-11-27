# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.ErrorHandlerTest do
  use ExUnit.Case
  alias Antikythera.Test.ConnHelper

  @custom_error_body %{"from" => "custom_error_handler"}

  test "web request: error" do
    ["/exception", "/throw", "/exit", "/timeout"] |> Enum.each(fn path ->
      res = Req.get(path)
      assert res.status == 500
      assert res.body   == Poison.encode!(@custom_error_body)
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

  test "web request: badly implemented controller action should result in an error" do
    [
      "/incorrect_return",
      "/missing_status_code",
      "/illegal_resp_body",
    ]
    |> Enum.each(fn path ->
      res = Req.get(path)
      assert res.status == 500
      assert res.body   == Poison.encode!(@custom_error_body)
    end)
  end

  test "web request: heap limit violation should be reported as 500 error" do
    res = Req.get("/exhaust_heap_memory")
    assert res.status == 500
    assert res.body   == Poison.encode!(@custom_error_body)
  end

  test "g2g request: error" do
    ["exception", "throw", "exit", "timeout"]
    |> Enum.each(fn path_element ->
      conn = ConnHelper.make_conn(path_info: [path_element], sender: {:gear, :testgear})
      res = Testgear.G2g.send(conn)
      assert res.status == 500
      assert res.body   == @custom_error_body
    end)
  end

  test "g2g request: no_route" do
    conn = ConnHelper.make_conn(path_info: ["no_route_matches"], sender: {:gear, :testgear})
    res = Testgear.G2g.send(conn)
    assert res.status == 400
    assert res.body   == %{"error" => "no_route"}
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
      assert res.body   == @custom_error_body
    end)
  end

  test "g2g request: heap limit violation should be reported as 500 error" do
    conn = ConnHelper.make_conn(path_info: ["exhaust_heap_memory"], sender: {:gear, :testgear})
    res = Testgear.G2g.send(conn)
    assert res.status == 500
    assert res.body   == @custom_error_body
  end

  test "execute custom error handler when executor_pool_for_web_request/1 returns an unavailable tenant exec pool ID" do
    res = Req.get("/bad_executor_pool_id")
    assert res.status == 400
    assert Poison.decode!(res.body) == %{"error" => "bad_executor_pool_id"}
  end
end
