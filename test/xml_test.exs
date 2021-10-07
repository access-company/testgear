# Copyright(c) 2015-2021 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.XmlTest do
  use ExUnit.Case

  @tag :blackbox
  test "should return xml" do
    response = Req.get("/xml")
    assert response.status == 200
    assert response.headers["content-type"] == "application/xml"
    assert response.body == "<?xml version='1.0' encoding='UTF-8'?>\n<greeting>Hello!</greeting>"
  end
end
