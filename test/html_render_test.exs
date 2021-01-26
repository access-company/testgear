# Copyright(c) 2015-2021 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.HtmlRenderTest do
  use ExUnit.Case

  @tag :blackbox
  test "should render HAML template as HTML" do
    response = Req.get("/html")
    assert response.status == 200
    assert response.headers["content-type"] == "text/html; charset=utf-8"
    body = response.body
    assert body |> String.starts_with?("<!DOCTYPE html>") # HAML is correctly converted
    assert body |> String.contains?("Application layout") # layout file is used
    assert body |> String.contains?("Content 2")          # dynamic parameters are correctly inserted
  end

  test "should appropriately bind variables in HAML template; missing parameter should result in an error" do
    keys = ~W(x1 x2 x3 x4 x5 x6 x7 x8 x9 x10)

    complete_params = Enum.map(keys, fn k -> {k, true} end)
    assert Req.get("/var_bindings", %{}, [params: complete_params]).status == 200

    Enum.each(keys, fn key ->
      incomplete_params = List.delete(keys, key) |> Enum.map(fn k -> {k, true} end)
      assert Req.get("/var_bindings", %{}, [params: incomplete_params]).status == 500
    end)
  end

  test "should HTML-escape dynamic parts in HAML template" do
    res = Req.get("/html_escaping")
    assert res.status == 200
    body = res.body
    assert String.contains?(body, ~S|<h2 comment="normal tag shouldn't be escaped <>">|)
    assert String.contains?(body, "elixir literal should be escaped &lt;&gt;&amp;&#39;&quot;")
    refute String.contains?(body, "<script>")
    refute String.contains?(body, "nil") # missing else clause of if expression should not emit "nil"
    assert String.contains?(body, "<raw content shouldn't be escaped>")
    assert String.contains?(body, "charlist literal")
    assert String.contains?(body, "dynamic charlist")
  end

  test "should translate text using gettext" do
    %{
      "en"             => "Hello",
      "ja"             => "こんにちは",
      "unknown_locale" => "Hello",
    } |> Enum.each(fn {locale, text} ->
      res = Req.get("/html", %{}, [params: %{"locale" => locale}])
      assert res.status == 200
      assert String.contains?(res.body, text)
    end)
  end

  test "should render partial contents" do
    assert %{status: 200, body: body} = Req.get("/partial")
    assert String.contains?(body, "inserted contents")
    assert String.contains?(body, "static contents")
  end
end
