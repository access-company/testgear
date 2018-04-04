# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

SolomonLib.Test.Config.init()
SolomonLib.Test.GearConfigHelper.set_config(%{"BASIC_AUTHENTICATION_ID" => "admin", "BASIC_AUTHENTICATION_PW" => "password"})

defmodule Req do
  use SolomonLib.Test.HttpClient
end

defmodule Socket do
  use SolomonLib.Test.WebsocketClient
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