# Copyright(c) 2015-2019 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.StaticAssetTest do
  use ExUnit.Case
  alias Antikythera.Httpc
  alias Testgear.Asset

  @test_html_basename "test.html"
  @test_html_path     Path.join([__DIR__, "..", "priv", "static", @test_html_basename])
  @test_html_content  File.read!(@test_html_path)

  test "send_priv_file should return existing file as response body" do
    res = Req.get("/priv_file/test.html")
    assert res.status == 200
    assert res.headers["content-type"] == "text/html"
    assert res.body == @test_html_content
  end

  test "should send files placed under priv/static/ (using :cowboy_static)" do
    res = Req.get("/custom/static/path/test.html")
    assert res.status == 200
    assert res.headers["content-type"] == "text/html"
    assert res.body == @test_html_content
  end

  test "should return 404 for nonexisting file" do
    res = Req.get("/custom/static/path/nonexisting")
    assert res.status == 404
  end

  test "Asset.all/0 and Asset.url/1" do
    map = Asset.all()
    Enum.each(map, fn {path, url} ->
      assert Asset.url(path) == url
    end)

    static_dir         = Path.join("priv", "static")
    all_asset_paths    = Map.keys(map) |> Enum.sort()
    all_existing_paths = Path.wildcard(Path.join(static_dir, "**")) |> Enum.map(&Path.relative_to(&1, static_dir)) |> Enum.sort()
    assert all_asset_paths == all_existing_paths
  end

  @tag :blackbox
  test "Asset file is retrievable from CDN URL returned by Asset.all/0" do
    res1 = Req.get("/asset_urls")
    assert res1.status == 200
    %{@test_html_basename => url} = Poison.decode!(res1.body)
    res2 = Httpc.get!(url, %{"origin" => Req.base_url()}) # pretend to be CORS request by adding `origin` request header
    assert res2.status == 200
    assert res2.body == @test_html_content
  end
end
