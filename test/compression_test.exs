# Copyright(c) 2015-2019 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.CompressionTest do
  use ExUnit.Case
  alias Antikythera.Httpc.Response, as: Res

  test "cowboy should compress controller-generated response bodies when requested" do
    examples =
      [
        {"/html"                            , "text/html; charset=utf-8"},
        {"/json"                            , "application/json"        },
        {"/priv_file/large_static_file.html", "text/html"               },
      ]

    for {path, content_type} <- examples do
      %Res{status: 200, headers: h1, body: b1} = Req.get(path)
      assert h1["content-type"] == content_type
      assert is_nil(h1["content-encoding"])
      assert String.to_integer(h1["content-length"]) == byte_size(b1)

      %Res{status: 200, headers: h2, body: b2} = Req.get(path, %{"accept-encoding" => "gzip"}, skip_body_decompression: true)
      assert h2["content-type"] == content_type
      assert h2["content-encoding"] == "gzip"
      assert String.to_integer(h2["content-length"]) == byte_size(b2)
      if content_type == "application/json" do
        b1_request = b1                   |> Poison.decode!() |> Map.get("request")
        b2_request = b2 |> :zlib.gunzip() |> Poison.decode!() |> Map.get("request")
        assert b2_request == b1_request
      else
        assert :zlib.gunzip(b2) == b1
      end
    end
  end

  test "cowboy should not compress controller-generated response bodies if they are small" do
    assert byte_size(File.read!(Path.join(["priv", "static", "test.html"]))) < 300
    %Res{status: 200, headers: h1} = Req.get("/priv_file/test.html", %{"accept-encoding" => "gzip"}, skip_body_decompression: true)
    assert h1["content-type"] == "text/html"
    assert is_nil(h1["content-encoding"])
  end
end
