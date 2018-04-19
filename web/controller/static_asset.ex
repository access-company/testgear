# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.StaticAsset do
  use SolomonLib.Controller
  alias SolomonLib.MapUtil
  alias Testgear.Asset

  def send_priv_file(%Conn{request: request} = conn) do
    %SolomonLib.Request{path_matches: matches} = request
    Conn.send_priv_file(conn, 200, "static/" <> matches[:file])
  end

  def urls(conn) do
    map = Asset.all() |> MapUtil.map_values(fn {_, url} -> to_absolute(url) end)
    Conn.json(conn, 200, map)
  end

  defp to_absolute(url) do
    if String.starts_with?(url, "http") do
      url
    else
      SolomonLib.Env.default_base_url(:testgear) <> url
    end
  end
end
