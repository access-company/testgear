# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.ContentDecodingTest do
  use ExUnit.Case

  @path "/content_decoding"
  @raw_body "foo"
  @compressed_body :zlib.gzip(@raw_body)

  test "should do nothing if content-encoding header is not present" do
    headers = %{
      "content-type" => "text/plain",
    }
    res = Req.post(@path, @raw_body, headers, skip_body_decompression: true)
    assert res.status == 200
    assert res.body == @raw_body
  end

  test "should decompress request body with gzip content-encoding header" do
    headers = %{
      "content-type" => "text/plain",
      "content-encoding" => "gzip",
    }
    res = Req.post(@path, @compressed_body, headers, skip_body_decompression: true)
    assert res.status == 200
    assert res.body == @raw_body
  end

  test "should return 400 status if the compression fails" do
    headers = %{
      "content-type" => "text/plain",
      "content-encoding" => "gzip",
    }
    res = Req.post(@path, @raw_body, headers, skip_body_decompression: true)
    assert res.status == 400
  end
end
