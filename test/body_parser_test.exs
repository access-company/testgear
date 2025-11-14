# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.BodyParserTest do
  use ExUnit.Case

  test "should respond JSON with content-type and request body (request body is JSON)" do
    for content_type <- ["application/json", "application/json; charset=utf-8"] do
      req_json = %{"foo" => "bar"}
      response = Req.post("/body_parser", Poison.encode!(req_json), %{"content-type" => content_type})

      assert response.status == 200
      assert response.headers["content-type"] == "application/json"
      resp_json = Poison.decode!(response.body)
      assert resp_json["content-type"] == content_type
      assert resp_json["body"] == req_json
    end
  end

  test "should respond JSON with content-type and request body (request body is Line Delimited JSON)" do
    content_types = [
      "application/json",
      "application/json; charset=utf-8",
      "application/x-ldjson",
      "application/x-ldjson: charset=utf-8",
      "application/x-ndjson",
      "application/x-ndjson: charset=utf-8",
    ]
    req_body = """
    {"valid": "JSON"}
    {
      "with\\r\\nCRLF":
      "with\\nLF"
    }
    {
      "nested":
      {
        "multiline": "JSON"
      }
    }
    """
    expected_body = [
      %{"valid"        => "JSON"},
      %{"with\r\nCRLF" => "with\nLF"},
      %{"nested"       => %{"multiline" => "JSON"}},
    ]
    for content_type <- content_types do
      response = Req.post("/body_parser", req_body, %{"content-type" => content_type})

      assert response.status == 200
      assert response.headers["content-type"] == "application/json"
      resp_json = Poison.decode!(response.body)
      assert resp_json["content-type"] == content_type
      assert resp_json["body"] == expected_body
    end
  end

  test "should respond JSON with content-type and request body (request body is x-www-form-urlencoded)" do
    for content_type <- ["application/x-www-form-urlencoded", "application/x-www-form-urlencoded; charset=utf-8"] do
      req_query = %{"foo" => "bar"}
      response = Req.post("/body_parser", URI.encode_query(req_query), %{"content-type" => content_type})

      assert response.status == 200
      assert response.headers["content-type"] == "application/json"
      resp_json = Poison.decode!(response.body)
      assert resp_json["content-type"] == content_type
      assert resp_json["body"] == req_query
    end
  end

  test "should respond JSON with content-type and request body (request body is plain text)" do
    req_body = "This is plain text."
    response = Req.post("/body_parser", req_body, %{"content-type" => "text/plain"})

    assert response.status == 200
    assert response.headers["content-type"] == "application/json"
    resp_json = Poison.decode!(response.body)
    assert resp_json["content-type"] == "text/plain"
    assert resp_json["body"] == req_body
  end

  test "should respond 400 status if request body is invalid JSON" do
    req_body = "invalid JSON"
    response = Req.post("/body_parser", req_body, %{"content-type" => "application/json"})
    assert response.status == 400
  end

  test "should reject with 400 request body that contains a number that doesn't fit into IEEE double" do
    req_body = ~S|{"foo":100e1000}|
    response = Req.post("/body_parser", req_body, %{"content-type" => "application/json"})
    assert response.status == 400
  end

  test "should respond 400 status if request body is Line Delimited JSON and contains a line of invalid JSON" do
    invalid_body = """
    {"valid": "JSON"}
    {invalid
    JSON}
    """
    empty_bodies = ["", " ", "\n", "\r", "\n\n", "\r\n\r\n"]
    for req_body <- [invalid_body | empty_bodies] do
      response = Req.post("/body_parser", req_body, %{"content-type" => "application/json"})
      assert response.status == 400
    end
  end

  test "should respond 400 status if request body is invalid query" do
    req_body = "a=%%"
    response = Req.post("/body_parser", req_body, %{"content-type" => "application/x-www-form-urlencoded"})
    assert response.status == 400
  end

  test "should respond 400 status if request body is too long" do
    req_body = "a=" <> String.duplicate("a", 8_000_000 + 1_000_000)
    response = Req.post("/body_parser", req_body, %{"content-type" => "application/x-www-form-urlencoded"})
    assert response.status == 400
  end

  test "should return the gzipped body to the gear if the post body is gzip compressed" do
    body_text = "{\"fuga\": \"hoge\"}"
    gzipped_body_text = :zlib.gzip(body_text)
    inspected_json_body = Jason.decode!(body_text) |> inspect()
    [
      {gzipped_body_text, %{"content-encoding" => "gzip", "content-type" => "application/json"}, body_text},
      {gzipped_body_text, %{"content-encoding" => "gzip"}, body_text},
      {body_text, %{"content-type" => "application/json"}, inspected_json_body},
      {body_text, %{}, body_text},
    ]
    |> Enum.each(fn {body, headers, expected_body} ->
      res = Req.post("/gzip_compressed", body, headers)
      assert res.body == expected_body
    end)
  end

end
