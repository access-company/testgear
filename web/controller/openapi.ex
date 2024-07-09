# Copyright(c) 2015-2023 ACCESS CO., LTD. All rights reserved.

# This module provides APIs for testing `Antikythera.Test.OpenApiAssertHelper`
# Therefore, these implementations are intentionally different from the OpenAPI specs.
defmodule Testgear.Controller.OpenApi do
  use Antikythera.Controller

  def one_post(conn) do
    code = Conn.get_req_query(conn, "code")
    full = (Conn.get_req_query(conn, "full") || "false") |> String.to_existing_atom
    invalid = (Conn.get_req_query(conn, "invalid") || "false") |> String.to_existing_atom

    one_post_response(conn, code, full, invalid)
  end

  def one_post_response(conn, "200", false, false) do
    Conn.json(conn, 200, %{required: "string"})
  end

  def one_post_response(conn, "200", true, false) do
    Conn.json(conn, 200, %{required: "string", no_required: 111})
  end

  def one_post_response(conn, "200", _, true) do
    Conn.json(conn, 200, %{required: "toooooo loooooong string"})
  end

  def one_post_response(conn, "400-01", _, true) do
    Conn.json(conn, 400, %{code: "400-01"})
  end

  def one_post_response(conn, "400-01", _, _) do
    Conn.json(conn, 400, %{code: "400-01", description: "400-01"})
  end

  def one_post_response(conn, "400-02", _, _) do
    Conn.json(conn, 400, %{code: "400-02", description: "400-02"})
  end

  def one_post_response(conn, "500", _, _) do
    Conn.json(conn, 500, %{code: "500-00", description: "500 Error"})
  end

  def one_post_response(conn, _, _, _) do
    Conn.json(conn, 200, %{required: "string"})
  end

  def one_get(conn) do
    r = Conn.get_req_query(conn, "required")
    Conn.json(conn, 200, %{required: r})
  end

  def one_put(conn) do
    r = Conn.get_req_query(conn, "required")
    Conn.json(conn, 200, %{required: r})
  end

  def one_delete(conn) do
    r = Conn.get_req_query(conn, "required")
    Conn.json(conn, 200, %{required: r})
  end

  def two(conn) do
    r = Conn.get_req_query(conn, "required")
    Conn.json(conn, 200, %{required: r})
  end

  def json(conn) do
    r = Conn.get_req_query(conn, "required")
    Conn.json(conn, 200, %{required: r})
  end

  def query(conn) do
    r = Conn.get_req_query(conn, "required")
    Conn.json(conn, 200, %{required: r})
  end

  def header(conn) do
    r = Conn.get_req_header(conn, "required")
    Conn.json(conn, 200, %{required: r})
  end

  def cookie(conn) do
    r = Conn.get_req_cookie(conn, "required")
    Conn.json(conn, 200, %{required: r})
  end

  def req_body(conn) do
    Conn.json(conn, 200, %{required: conn.request.body["required"]})
  end

  def req_body_ref(conn) do
    Conn.json(conn, 200, %{required: conn.request.body["required"]})
  end

  def all_of(conn) do
    one = Conn.get_req_query(conn, "one") |> String.to_existing_atom
    two = Conn.get_req_query(conn, "two") |> String.to_existing_atom
    body =
      case {one, two} do
        {true, true} -> %{requiredOne: "one", requiredTwo: "two"}
        {true, _} -> %{requiredOne: "one"}
        {_, true} -> %{requiredTwo: "two"}
        _ -> %{}
      end
    Conn.json(conn, 200, body)
  end
end
