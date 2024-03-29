# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.Hello do
  use Antikythera.Controller
  alias Antikythera.{Time, Request, G2gResponse, Xml}

  def html(conn) do
    Testgear.Gettext.put_locale(conn.request.query_params["locale"] || "en")
    args = [contents: [{"Headline 1", "Content 1"}, {"Headline 2", "Content 2"}]]
    Conn.render(conn, 200, "hello/hello", args)
  end

  def var_bindings(conn) do
    qs = conn.request.query_params
    args =
      [x1: "x1", x2: 10, x3: "x3", x4: "x4", x5: 5, x6: "x6", x7: [1, 2, 3], x8: Integer, x9: 9, x10: 10]
      |> Enum.filter(fn {k, _v} -> Map.has_key?(qs, Atom.to_string(k)) end)
    Conn.render(conn, 200, "hello/var_bindings", args)
  end

  def html_escaping(conn) do
    Conn.render(conn, 200, "hello/html_escaping", [param: "<script>alert('hello')</script>"])
  end

  def partial(conn) do
    Conn.render(conn, 200, "hello/partial", [])
  end

  def json(%Conn{request: req, context: ctx} = conn) do
    try_sleep(conn)
    req_map = Map.from_struct(req) |> Map.put(:sender, Tuple.to_list(req.sender))
    ctx_map =
      Map.from_struct(ctx)
      |> Map.put(:start_time, Time.to_iso_timestamp(ctx.start_time))
      |> Map.put(:executor_pool_id, Tuple.to_list(ctx.executor_pool_id))
      |> Map.put(:gear_entry_point, Tuple.to_list(ctx.gear_entry_point))
    Conn.json(conn, 200, %{request: req_map, context: ctx_map})
  end

  def json_via_g2g(%Conn{request: req} = conn) do
    conn2 = %Conn{conn | request: %Request{req | path_info: ["json"]}}
    %G2gResponse{status: status, body: body} = Testgear.G2g.send(conn2)
    Conn.json(conn, status, body)
  end

  def redirect(conn) do
    url = Conn.get_req_query(conn, "url") || Testgear.Router.html_path()
    Conn.redirect(conn, url)
  end

  def body_parser(%Conn{request: request} = conn) do
    try_sleep(conn)
    content_type = request.headers["content-type"]
    Conn.json(conn, 200, %{"content-type": content_type, body: request.body})
  end

  def path_matches(%Conn{request: request} = conn) do
    %Antikythera.Request{path_matches: matches} = request
    Conn.json(conn, 200, matches)
  end

  def camelized_header_key(conn) do
    conn
    |> Conn.put_resp_header("Camelized-Key", "Value")
    |> Conn.json(200, %{})
  end

  def gzip_compressed(conn) do
    body = Poison.encode!(%{"hello" => "compressed"}) |> :zlib.gzip()
    conn
    |> Conn.put_status(200)
    |> Conn.put_resp_body(body)
    |> Conn.put_resp_headers(%{"content-encoding" => "gzip", "content-type" => "application/json"})
  end

  def gzip_compressed_post(%Conn{request: request} = conn) do
    body =
      case request.headers["content-encoding"] do
        "gzip" -> :zlib.gunzip(request.body)
        _ ->
          if is_binary(request.body) do
            request.body
          else
            inspect(request.body)
          end
      end
    conn
    |> Conn.put_status(200)
    |> Conn.put_resp_body(body)
  end

  def incorrect_content_length(conn) do
    conn
    |> Conn.put_status(200)
    |> Conn.put_resp_body("0123456789")
    |> Conn.put_resp_header("content-length", "20")
  end

  def override_default_header(conn) do
    conn
    |> Conn.put_status(200)
    |> Conn.put_resp_header("x-frame-options", "SAMEORIGIN")
  end

  defp try_sleep(conn) do
    sleep = conn.request.query_params["sleep"]
    if sleep != nil do
      with {msec, _} <- Integer.parse(sleep) do
        Process.sleep(msec)
      end
    end
  end

  def xml(conn) do
    xml_body =
      "<greeting>Hello!</greeting>"
      |> Xml.decode!()
      |> Xml.encode(with_header: true)
    conn
    |> Conn.put_resp_header("content-type", "application/xml")
    |> Conn.resp_body(xml_body)
    |> Conn.put_status(200)
  end
end
