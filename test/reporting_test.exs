# Copyright(c) 2015-2020 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.ReportingTest do
  use ExUnit.Case

  @tag :blackbox
  test "logging should function correctly" do
    assert Req.get("/report_log").status == 200
  end

  @tag :blackbox
  test "metric reporting should function correctly" do
    assert Req.get("/report_metric").status == 200
  end

  @tag :blackbox
  test "async job registration should function correctly" do
    assert Req.post("/register_async_job", "").status == 200
  end
end
