# Copyright(c) 2015-2022 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.G2gTest do
  use   ExUnit.Case
  alias Antikythera.Http.SetCookie
  alias Antikythera.G2gRequest , as: GReq
  alias Antikythera.G2gResponse, as: GRes

  @context Antikythera.Test.ConnHelper.make_conn(%{sender: {:gear, :sender_gear}, gear_name: :sender_gear}).context

  test "gear client should request with specified params" do
    path    = "/foo/hoge/bar/wildcard"
    qparams = %{"foo1" => "bar1"}
    headers = %{"foo2" => "bar2"}
    cookies = %{"foo3" => "bar3"}
    expected_body_keys = ["context", "request"]

    req = GReq.new!([method: :get, path: path, query_params: qparams, headers: headers, cookies: cookies])
    res1 = Testgear.G2g.send(req, @context)
    assert res1.status  == 200
    assert res1.cookies == %{}
    assert Map.keys(res1.body) |> Enum.sort() == expected_body_keys

    conn = Antikythera.Test.ConnHelper.make_conn(%{
      method:       :get,
      path_info:    ["foo", "hoge", "bar", "wildcard"],
      query_params: qparams,
      headers:      headers,
      cookies:      cookies,
      gear_name:    :sender_gear,
      context_id:   @context.context_id,
    })
    res2 = Testgear.G2g.send(conn)
    assert res2.status  == 200
    assert res2.cookies == %{}
    assert Map.keys(res2.body) |> Enum.sort() == expected_body_keys
  end

  test "json response should be docoded" do
    res1 = Testgear.G2g.send(GReq.new!([method: :get, path: "/json"]), @context)
    assert res1.status == 200
    assert is_map(res1.body)

    res2 = Testgear.G2g.send(GReq.new!([method: :get, path: "/html"]), @context)
    assert res2.status == 200
    assert is_binary(res2.body)
  end

  test "gzip compressed body should not cause error" do
    req = GReq.new!([method: :get, path: "/gzip_compressed", headers: %{"accept-encoding" => "gzip"}])
    res1 = Testgear.G2g.send(req, @context)
    assert res1.status == 200
    assert res1.headers["content-type"    ] == "application/json"
    assert res1.headers["content-encoding"] == nil
    assert is_map(res1.body)

    res2 = Testgear.G2g.send_without_decoding(req, @context)
    assert res2.status == 200
    assert res2.headers["content-type"    ] == "application/json"
    assert res2.headers["content-encoding"] == "gzip"
    assert is_binary(res2.body)

    assert GRes.decode_body(res2) == res1
    assert GRes.decode_body(res1) == res1 # should be idempotent
  end

  test "routing for web should not be used" do
    [
      {"/json",             200},
      {"/only_from_gear",   200},
      {"/nonexisting_path", 400},
      {"/only_from_web",    400},
    ] |> Enum.each(fn {path, expected_status} ->
      res = Testgear.G2g.send(GReq.new!([method: :get, path: path]), @context)
      assert res.status == expected_status
    end)
  end

  test "trailing '/' in path should be removed" do
    [
      {"/json",  200},
      {"/json/", 200},
    ] |> Enum.each(fn {path, expected_status} ->
      res = Testgear.G2g.send(GReq.new!([method: :get, path: path]), @context)
      assert res.status == expected_status
    end)
  end

  test "content-type/length header should be set automatically" do
    [
      {:post, "/json", %{},                                     %{"foo" => "bar"}, "application/json"},
      {:post, "/json", %{},                                     ["foo", "bar"],    "application/json"},
      {:post, "/json", %{},                                     "plain text",      "text/plain"},
      {:post, "/json", %{"content-type" => "application/json"}, "plain text",      "application/json"},
      {:get,  "/json", %{},                                     %{"foo" => "bar"}, nil},
      {:get,  "/json", %{},                                     "plain text",      nil},
    ] |> Enum.each(fn {method, path, headers, body, expected_content_type} ->
      res = Testgear.G2g.send(GReq.new!([method: method, path: path, headers: headers, body: body]), @context)
      expected_content_length =
        case method do
          :post ->
            string_body = if is_binary(body), do: body, else: Poison.encode!(body)
            byte_size(string_body) |> Integer.to_string()
          :get -> nil
        end
      received_headers = res.body["request"]["headers"]
      assert received_headers["content-length"] == expected_content_length
      assert received_headers["content-type"]   == expected_content_type
    end)
  end

  test "specified cookie should be deleted" do
    cookies = %{"foo1" => "bar1", "foo2" => "bar2"}
    req = GReq.new!([method: :delete, path: "/cookie", cookies: cookies, query_params: %{"key" => "foo1"}])
    res = Testgear.G2g.send(req, @context)
    assert res.cookies == %{"foo1" => %SetCookie{value: "", path: "/", max_age: 0}}
  end

  test "header key should be downcased" do
    req = GReq.new!([method: :get, path: "/camelized_header_key"])
    %Antikythera.G2gResponse{headers: headers} = Testgear.G2g.send(req, @context)
    assert headers == %{"camelized-key" => "Value", "content-type" => "application/json"}
  end

  @tag :blackbox
  test "controller action should be able to communicate via g2g" do
    res = Req.get("/json_via_g2g")
    assert res.status == 200
  end
end
