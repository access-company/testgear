# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

use Croma

defmodule Testgear.HttpcWithLoggingNoLog do
  use Antikythera.GearApplication.HttpcWithLogging

  # No custom log function
end

defmodule Testgear.HttpcWithLoggingWithLog do
  use Antikythera.GearApplication.HttpcWithLogging

  @impl true
  defun log(
    method :: v[Http.Method.t()],
    url :: v[Antikythera.Url.t()],
    _body :: v[ReqBody.t()],
    _headers :: v[Http.Headers.t()],
    _options :: Keyword.t(),
    response :: R.t(Response.t()),
    _start_time :: Antikythera.Time.t(),
    _end_time :: Antikythera.Time.t(),
    _used_time :: non_neg_integer()
  ) :: :ok do
    Testgear.Logger.info("CustomLog: #{inspect(method)} #{url} #{inspect(response)}")
  end
end
