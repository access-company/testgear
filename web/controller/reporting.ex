# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.Reporting do
  use SolomonLib.Controller

  def log(conn) do
    Testgear.Logger.info("report log")
    Conn.put_status(conn, 200)
  end

  def metric(conn) do
    Testgear.MetricsUploader.submit([{"report_metric", :sum, 1}], conn.context)
    Conn.put_status(conn, 200)
  end

  def register_async_job(conn) do
    {:ok, _} = Testgear.TestAsyncJob.register(%{todo: :ok}, conn.context)
    Conn.put_status(conn, 200)
  end
end
