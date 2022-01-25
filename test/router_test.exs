# Copyright(c) 2015-2022 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.RouterTest do
  use Croma.TestCase
  alias Antikythera.G2gRequest
  alias Antikythera.Test.ConnHelper

  defp e(s), do: URI.encode_www_form(s)

  test "routing DSL should accept both path with and without trailing slash" do
    [
      "",
      "/",
      "/dot.and~tilde_in_route",
      "/foo/a/b/c/d",
      "/foo/a/b/c/d/",
    ] |> Enum.each(fn path ->
      assert Req.get(path).status == 200
    end)
  end

  test "routing DSL should preserve trailing slash in wildcard match" do
    res1 = Req.get("/path_matches/x/y/z/abc/def")
    assert res1.status == 200
    assert Poison.decode!(res1.body) == %{"a" => "x", "b" => "y", "c" => "z", "d" => "abc/def"}
    res2 = Req.get("/path_matches/x/y/z/abc/def/")
    assert res2.status == 200
    assert Poison.decode!(res2.body) == %{"a" => "x", "b" => "y", "c" => "z", "d" => "abc/def/"}
    res3 = Req.get("/path_matches/x/y/z/")
    assert res3.status == 200
    assert Poison.decode!(res3.body) == %{"a" => "x", "b" => "y", "c" => "z", "d" => ""}
    res4 = Req.get("/path_matches/x/y/z")
    assert res4.status == 400
  end

  test "routes for g2g should not be used for web requests" do
    res1 = Req.get("/only_from_web")
    assert res1.status == 200
    res2 = Req.get("/using_only_from_web_block")
    assert res2.status == 200

    res3 = Req.get("/only_from_gear")
    assert res3.status == 400
    res4 = Req.get("/using_only_from_gear_block")
    assert res4.status == 400
  end

  test "matches in path should be extracted" do
    res1 = Req.get("/path_matches/x/y/z/abc/def/ghi/")
    assert Poison.decode!(res1.body) == %{"a" => "x", "b" => "y", "c" => "z", "d" => "abc/def/ghi/"}
    res2 = Req.get("/path_matches/percent/should_be_decoded/#{e("あ")}/slash_is_#{e("/")}")
    assert Poison.decode!(res2.body) == %{"a" => "percent", "b" => "should_be_decoded", "c" => "あ", "d" => "slash_is_/"}
    res3 = Req.get("/path_matches/percent/should_not_be/doubly_decoded/#{e(e("あ"))}")
    assert Poison.decode!(res3.body) == %{"a" => "percent", "b" => "should_not_be", "c" => "doubly_decoded", "d" => e("あ")}
  end

  test "routing rule should be matched against URL-decoded path" do
    # URL-encoded unreserved chars should be treated as equivalent: https://tools.ietf.org/html/rfc3986#section-2.3
    encoded_path = "/%6A%73%6F%6E"
    assert URI.decode_www_form(encoded_path) == "/json"
    # web
    res = Req.get(encoded_path)
    assert Poison.decode!(res.body) != %{"error" => "no_route"}
    # g2g
    context = ConnHelper.make_conn().context
    req_g2g = G2gRequest.new!(%{method: :get, path: encoded_path})
    res_g2g = Testgear.G2g.send(req_g2g, context)
    assert res_g2g.body != %{"error" => "no_route"}
  end

  test "should reject request containing URL-encoded path match which is not printable" do
    res = Req.get("/path_matches/x/y/z/" <> e(<<0>>))
    assert res.status               == 400
    assert Poison.decode!(res.body) == %{"error" => "no_route"}
  end

  test "xxx_path with valid params" do
    assert Router.html_path() == "/html"

    assert Router.routing_test_path("a", "b", ["c", "d"])                         == "/foo/a/b/c/d"
    assert Router.routing_test_path("a", "b", ["c", "d"], %{"query" => "params"}) == "/foo/a/b/c/d?query=params"
    assert Router.routing_test_path("a", "b", ["c", "d"], %{"empty_value" => ""}) == "/foo/a/b/c/d?empty_value="

    expected = "/foo/#{e("ユー")}/#{e("アール")}/#{e("エル")}/#{e("エンコード")}?#{e("し")}=#{e("ます")}"
    assert Router.routing_test_path("ユー", "アール", ["エル", "エンコード"], %{"し" => "ます"}) == expected
  end

  test "xxx_path should raise if incorrect type of argument is given" do
    catch_error Router.routing_test_path("a", "b", "shouldn't be a string")
    catch_error Router.routing_test_path(["shouldn't be a list"], "b", ["c"])
  end

  test "xxx_path should raise if empty segment or empty query parameter name is given" do
    catch_error Router.routing_test_path("", "b", ["c", "d"])
    catch_error Router.routing_test_path("a", "b", ["c", ""])
    catch_error Router.routing_test_path("a", "b", ["c", "d"], %{"" => "params"})
  end
end
