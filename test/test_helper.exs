# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

Antikythera.Test.Config.init()
Antikythera.Test.GearConfigHelper.set_config(%{"BASIC_AUTHENTICATION_ID" => "admin", "BASIC_AUTHENTICATION_PW" => "password"})

defmodule Req do
  use Antikythera.Test.HttpClient
end

defmodule Socket do
  use Antikythera.Test.WebsocketClient
end

defmodule Cookie do
  def response_to_request_cookie(res) do
    cookie_header_value = Enum.map_join(res.cookies, "; ", fn {name, cookie} -> "#{name}=#{cookie.value}" end)
    %{"cookie" => cookie_header_value}
  end

  def valid?(res, name) do
    Map.has_key?(res.cookies, name)
  end

  def expired?(res, name) do
    res.cookies[name].max_age == 0
  end
end

defmodule OpenApiAssert do
  use Antikythera.Test.OpenApiAssertHelper,
    yaml_files: ["doc/api/openapi_one.yaml", "doc/api/openapi_two.yaml"],
    json_files: ["doc/api/openapi_json.json"]
end

defmodule OpenApiAssertNoNull do
  use Antikythera.Test.OpenApiAssertHelper,
    yaml_files: ["doc/api/openapi_one.yaml"],
    allows_null_for_optional: false
end
