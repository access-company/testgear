# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.MalformedRequestTest do
  use ExUnit.Case

  defp run_curl(path_and_params, options) do
    url = Antikythera.Test.Config.base_url() <> path_and_params
    {output, 0} = System.cmd("curl", options ++ ["-s", "-o", "/dev/null", "-w", "%{http_code}", url])
    String.to_integer(output)
  end

  test "return 400 for malformed method" do
    assert run_curl("/", ["-Xhoge"]) == 400
  end

  test "return 400 for malformed URL path" do
    assert run_curl("/incorrect_url_encoding_%xy", []) == 400
  end

  test "return 400 for malformed query params" do
    assert run_curl("/?non_hex=%xy", []) == 400
  end
end
