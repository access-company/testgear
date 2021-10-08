# Copyright(c) 2015-2021 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.XmlTest do
  use ExUnit.Case

  # This blackbox test is used for ensureing that
  # Antikythera.Xml works as expected after hot code upgrade.
  # This is important because Antikythera.Xml indirectly (via fast_xml) depends on native code.
  @tag :blackbox
  test "should return xml" do
    response = Req.get("/xml")
    assert response.status == 200
    assert response.headers["content-type"] == "application/xml"
    assert response.body == "<?xml version='1.0' encoding='UTF-8'?>\n<greeting>Hello!</greeting>"
  end
end
