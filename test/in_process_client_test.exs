# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.InProcessClientTest do
  use ExUnit.Case

  defp e(s), do: URI.encode_www_form(s)

  test "GET should route and return 200 for known paths" do
    for path <- ["", "/", "/dot.and~tilde_in_route", "/foo/a/b/c/d", "/foo/a/b/c/d/"] do
      assert ReqInProcess.get(path).status == 200
    end
  end

  test "GET should return 400 no_route for unknown paths" do
    res = ReqInProcess.get("/this_path_does_not_exist")
    assert res.status == 400
    assert Poison.decode!(res.body) == %{"error" => "no_route"}
  end

  test "GET should extract path matches" do
    res = ReqInProcess.get("/path_matches/x/y/z/abc/def")
    assert res.status == 200
    assert Poison.decode!(res.body) == %{"a" => "x", "b" => "y", "c" => "z", "d" => "abc/def"}
  end

  test "GET should URL-decode path before routing" do
    res = ReqInProcess.get("/%6A%73%6F%6E")
    assert res.status == 200
    assert Poison.decode!(res.body) |> Map.has_key?("request")
  end

  test "GET should pass query params and concatenate :params option" do
    qparams =
      ReqInProcess.get("/json?a=b", %{}, params: %{"あ" => "い"}).body
      |> Poison.decode!()
      |> get_in(["request", "query_params"])

    assert qparams == %{"a" => "b", "あ" => "い"}
  end

  test "GET should propagate request headers (downcased)" do
    res = ReqInProcess.get("/json", %{"X-Custom-Header" => "hello"})
    assert res.status == 200
    headers = Poison.decode!(res.body) |> get_in(["request", "headers"])
    assert headers["x-custom-header"] == "hello"
  end

  test "POST with JSON body should be parsed as JSON" do
    req_json = %{"foo" => "bar"}
    res = ReqInProcess.post_json("/body_parser", req_json)
    assert res.status == 200
    assert res.headers["content-type"] == "application/json"
    resp = Poison.decode!(res.body)
    assert resp["content-type"] == "application/json"
    assert resp["body"] == req_json
  end

  test "POST with form body should be parsed as form" do
    res = ReqInProcess.post_form("/body_parser", [{"foo", "bar"}, {"baz", "qux"}])
    assert res.status == 200
    resp = Poison.decode!(res.body)
    assert resp["content-type"] == "application/x-www-form-urlencoded"
    assert resp["body"] == %{"foo" => "bar", "baz" => "qux"}
  end

  test "POST with raw body + explicit content-type should be echoed" do
    res = ReqInProcess.post("/body_parser", "raw text", %{"content-type" => "text/plain"})
    assert res.status == 200
    resp = Poison.decode!(res.body)
    assert resp["content-type"] == "text/plain"
    assert resp["body"] == "raw text"
  end

  test "plug pipeline should run and allow halt" do
    proceed = ReqInProcess.post_json("/action1_with_plug", %{"plug" => "proceed"})
    assert proceed.status == 200
    assert proceed.body == Poison.encode!(%{msg: "OK"})

    halted = ReqInProcess.post_json("/action1_with_plug", %{"plug" => "halt"})
    assert halted.status == 400
  end

  test "custom error handler should be invoked on plug errors" do
    res = ReqInProcess.get("/action_plug_error")
    assert res.status == 500
    assert res.body == ~S|{"from":"custom_error_handler: error"}|
  end

  test "POST /cookie should set response cookies via before_send" do
    res = ReqInProcess.post_form("/cookie", [{"k1", "v1"}, {"k2", "v2"}])
    assert res.status == 200
    assert Map.has_key?(res.cookies, "k1")
    assert Map.has_key?(res.cookies, "k2")
    assert res.cookies["k1"].value == "v1"
  end

  test "simple GET body should match HttpClient output" do
    in_proc = ReqInProcess.get("/html")
    http = Req.get("/html")
    assert in_proc.status == http.status
    assert in_proc.body == http.body
  end

  test "DELETE /cookie should succeed" do
    assert ReqInProcess.delete("/cookie").status == 200
  end

  test "controller action runs in the same process as the test" do
    res = ReqInProcess.get("/store_pid")
    assert res.status == 200

    assert Process.get(:controller_pid) == self()
  end

  test "percent-encoded path matches should be decoded once" do
    res = ReqInProcess.get("/path_matches/percent/should_be_decoded/#{e("あ")}/slash_is_#{e("/")}")

    assert Poison.decode!(res.body) == %{
             "a" => "percent",
             "b" => "should_be_decoded",
             "c" => "あ",
             "d" => "slash_is_/"
           }
  end
end
