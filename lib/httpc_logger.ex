# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

use Croma

defmodule Testgear.HttpcLogger do
  alias Croma.Result, as: R

  alias Testgear.Logger
  alias Antikythera.{Time, Url}
  alias Antikythera.Httpc.{Response, ReqBody}
  alias Antikythera.Http.{Method, Headers}

  defun log(
           method :: v[Method.t()],
           url :: v[Url.t()],
           body :: v[ReqBody.t()],
           headers :: v[Headers.t()],
           options :: Keyword.t(),
           response :: v[R.t(Response.t())],
           start_time :: v[Time.t()],
           end_time :: v[Time.t()],
           used_time :: v[non_neg_integer]
  ) :: :ok do
    # Remote call for mock in the tests
    Testgear.HttpcLogger.log_info("method: #{method}, url: #{url}, body: #{body}, headers: #{inspect(headers)}, options: #{options}, response: #{inspect(response)}, start_time: #{Time.to_iso_timestamp(start_time)}, end_time: #{Time.to_iso_timestamp(end_time)}, used_time: #{used_time}")
    :ok
  end

  defun log_info(string :: v[String.t()]) :: :ok do
    Logger.info(string)
  end
end
