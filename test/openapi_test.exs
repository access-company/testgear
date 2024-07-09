# Copyright(c) 2015-2023 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.OpenApiTest do
  use ExUnit.Case
  alias ExUnit.AssertionError

  @api_schema OpenApiAssert.find_api("onePost")

  @body %{required: "post"}

  describe "onePost API" do
    test "should return required key when code == 200, full == false and invalid == false" do
      res = OpenApiAssert.post_json_for_success(@api_schema, "/openapi/path1/one?code=200", @body)
      assert res.status == 200
      assert Jason.decode!(res.body)["required"] == "string"
    end

    test "should return required and no_required key when code == 200, full == true and invalid == false" do
      res = OpenApiAssert.post_json_for_success(@api_schema, "/openapi/path1/one?code=200&full=true", @body)
      assert res.status == 200
      body_json = Jason.decode!(res.body)
      assert body_json["required"] == "string"
      assert body_json["no_required"] == 111
    end

    test "wrongly return invalid required when code == 200, full == false and invalid == true" do
      assert_raise AssertionError, fn ->
        OpenApiAssert.post_json_for_success(@api_schema, "/openapi/path1/one?code=200&invalid=true", @body)
      end
    end

    test "should return code == '400-01' and description key when code == 400-1" do
      res = OpenApiAssert.post_json_for_error(@api_schema, "/openapi/path1/one?code=400-01", @body)
      assert res.status == 400
      body_json = Jason.decode!(res.body)
      assert body_json["code"] == "400-01"
      assert body_json["description"] == "400-01"
    end

    test "wrongly return json without description when code == 400-1 and invalid == true" do
      assert_raise AssertionError, fn ->
        OpenApiAssert.post_json_for_error(@api_schema, "/openapi/path1/one?code=400-01&invalid=true", @body)
      end
    end

    test "should return code == '400-02' and description key when code == 400-2" do
      res = OpenApiAssert.post_json_for_error(@api_schema, "/openapi/path1/one?code=400-02", @body)
      assert res.status == 400
      body_json = Jason.decode!(res.body)
      assert body_json["code"] == "400-02"
      assert body_json["description"] == "400-02"
    end

    test "should return code == '500-0' and description key when code == 500" do
      res = OpenApiAssert.post_json_for_error(@api_schema, "/openapi/path1/one?code=500", @body)
      assert res.status == 500
      body_json = Jason.decode!(res.body)
      assert body_json["code"] == "500-00"
      assert body_json["description"] == "500 Error"
    end
  end

  describe "oneGet API" do
    test "should return 200" do
      expected = "hoge"
      res = OpenApiAssert.get_for_success(OpenApiAssert.find_api("oneGet"), "/openapi/path1/one?required=#{expected}")
      assert res.status == 200
      assert Jason.decode!(res.body)["required"] == expected
    end
  end

  describe "onePut API" do
    test "should return 200" do
      expected = "hoge"
      res = OpenApiAssert.put_json_for_success(OpenApiAssert.find_api("onePut"), "/openapi/path1/one?required=#{expected}", %{})
      assert res.status == 200
      assert Jason.decode!(res.body)["required"] == expected
    end
  end

  describe "oneDelete API" do
    test "should return 200" do
      expected = "hoge"
      res = OpenApiAssert.delete_for_success(OpenApiAssert.find_api("oneDelete"), "/openapi/path1/one?required=#{expected}")
      assert res.status == 200
      assert Jason.decode!(res.body)["required"] == expected
    end
  end

  describe "two API" do
    test "should return 200" do
      expected = "hoge"
      res = OpenApiAssert.get_for_success(OpenApiAssert.find_api("two"), "/openapi/two?required=#{expected}")
      assert res.status == 200
      assert Jason.decode!(res.body)["required"] == expected
    end
  end

  describe "json API" do
    test "should return 200" do
      expected = "hoge"
      res = OpenApiAssert.get_for_success(OpenApiAssert.find_api("json"), "/openapi/json?required=#{expected}")
      assert res.status == 200
      assert Jason.decode!(res.body)["required"] == expected
    end
  end

  describe "query API" do
    test "should return 200 if required is specified" do
      expected = "hoge"
      query = "?required=#{expected}&ref=sample"
      res = OpenApiAssert.get_for_success(OpenApiAssert.find_api("query"), "/openapi/query#{query}")
      assert res.status == 200
      assert Jason.decode!(res.body)["required"] == expected
    end

    test "wrongly return 200 if there is no required" do
      assert_raise AssertionError, fn ->
        query = "?no_required=no&ref=sample"
        OpenApiAssert.get_for_success(OpenApiAssert.find_api("query"), "/openapi/query#{query}")
      end
    end

    test "wrongly return 200 if key is wrong" do
      assert_raise AssertionError, fn ->
        query = "?required=required&ref=sample&wrong=sample"
        OpenApiAssert.get_for_success(OpenApiAssert.find_api("header"), "/openapi/query#{query}")
      end
    end
  end

  describe "header API" do
    test "should return 200 if required is specified" do
      expected = "hoge"
      header = %{"required" => expected, "ref" => "sample"}
      res = OpenApiAssert.get_for_success(OpenApiAssert.find_api("header"), "/openapi/header", header)
      assert res.status == 200
      assert Jason.decode!(res.body)["required"] == expected
    end

    test "wrongly return 200 if there is no required" do
      assert_raise AssertionError, fn ->
        header = %{"no_required" => "sample", "ref" => "sample"}
        OpenApiAssert.get_for_success(OpenApiAssert.find_api("header"), "/openapi/header", header)
      end
    end

    test "wrongly return 200 if key is wrong" do
      assert_raise AssertionError, fn ->
        header = %{"wrong" => "sample", "required" => "required", "ref" => "sample"}
        OpenApiAssert.get_for_success(OpenApiAssert.find_api("header"), "/openapi/header", header)
      end
    end
  end

  describe "cookie API" do
    test "should return 200 if required is specified" do
      expected = "hoge"
      header = %{"cookie" => "required=#{expected}; ref=sample"}
      res = OpenApiAssert.get_for_success(OpenApiAssert.find_api("cookie"), "/openapi/cookie", header)
      assert res.status == 200
      assert Jason.decode!(res.body)["required"] == expected
    end

    test "wrongly return 200 if there is no required" do
      assert_raise AssertionError, fn ->
        header = %{"cookie" => "no_required=sample"}
        OpenApiAssert.get_for_success(OpenApiAssert.find_api("cookie"), "/openapi/cookie", header)
      end
    end

    test "wrongly return 200 if there is no cookie" do
      assert_raise AssertionError, fn ->
        OpenApiAssert.get_for_success(OpenApiAssert.find_api("cookie"), "/openapi/cookie")
      end
    end

    test "wrongly return 200 if key is wrong" do
      assert_raise AssertionError, fn ->
        header = %{"cookie" => "wrong=sample; required=required; ref=sample"}
        OpenApiAssert.get_for_success(OpenApiAssert.find_api("cookie"), "/openapi/header", header)
      end
    end
  end

  describe "reqBody API" do
    test "should return 200 if required is specified" do
      expected = "hoge"
      body = %{"required" => expected}
      res = OpenApiAssert.post_json_for_success(OpenApiAssert.find_api("reqBody"), "/openapi/req_body", body)
      assert res.status == 200
      assert Jason.decode!(res.body)["required"] == expected
    end

    test "wrongly return 200 if there is no required" do
      assert_raise AssertionError, fn ->
        body = %{}
        OpenApiAssert.post_json_for_success(OpenApiAssert.find_api("reqBody"), "/openapi/req_body", body)
      end
    end

    test "should return 200 if no_required is null" do
      body = %{"required" => "sample", "no_required" => nil}
      res = OpenApiAssert.post_json_for_success(OpenApiAssert.find_api("reqBody"), "/openapi/req_body", body)
      assert res.status == 200
    end

    test "should fail if no_required is null and :allows_null_for_optional is false" do
      assert_raise AssertionError, fn ->
        body = %{"required" => "sample", "no_required" => nil}
        OpenApiAssertNoNull.post_json_for_success(OpenApiAssertNoNull.find_api("reqBody"), "/openapi/req_body", body)
      end
    end

    test "wrongly return 200 if key is wrong" do
      assert_raise AssertionError, fn ->
        body = %{"required" => "sample", "wrong" => "sample"}
        OpenApiAssertNoNull.post_json_for_success(OpenApiAssertNoNull.find_api("reqBody"), "/openapi/req_body", body)
      end
    end

    test "should return 200 if key is wrong but :ignore_req_fields contains it" do
      ignored_key = "ignored"
      body = %{"required" => "sample", ignored_key => "sample"}
      res =
        OpenApiAssertNoNull.post_json_for_success(
          OpenApiAssertNoNull.find_api("reqBody"),
          "/openapi/req_body",
          body,
          %{},
          [ignore_req_fields: [ignored_key]]
        )
      assert res.status == 200
    end
  end

  describe "reqBodyRef API" do
    test "should return 200 if required is specified" do
      expected = "hoge"
      body = %{"required" => expected}
      res = OpenApiAssert.post_json_for_success(OpenApiAssert.find_api("reqBodyRef"), "/openapi/req_body_ref", body)
      assert res.status == 200
      assert Jason.decode!(res.body)["required"] == expected
    end

    test "wrongly return 200 if there is no required" do
      assert_raise AssertionError, fn ->
        body = %{}
        OpenApiAssert.post_json_for_success(OpenApiAssert.find_api("reqBodyRef"), "/openapi/req_body_ref", body)
      end
    end

    test "should return 200 if no_required is null" do
      body = %{"required" => "sample", "no_required" => nil}
      res = OpenApiAssert.post_json_for_success(OpenApiAssert.find_api("reqBodyRef"), "/openapi/req_body_ref", body)
      assert res.status == 200
    end

    test "should fail if no_required is null and :allows_null_for_optional is false" do
      assert_raise AssertionError, fn ->
        body = %{"required" => "sample", "no_required" => nil}
        OpenApiAssertNoNull.post_json_for_success(OpenApiAssertNoNull.find_api("reqBodyRef"), "/openapi/req_body_ref", body)
      end
    end

    test "wrongly return 200 if key is wrong" do
      assert_raise AssertionError, fn ->
        body = %{"required" => "sample", "wrong" => "sample"}
        OpenApiAssertNoNull.post_json_for_success(OpenApiAssertNoNull.find_api("reqBodyRef"), "/openapi/req_body_ref", body)
      end
    end

    test "should return 200 if key is wrong but :ignore_req_fields contains it" do
      ignored_key = "ignored"
      body = %{"required" => "sample", ignored_key => "sample"}
      res =
        OpenApiAssertNoNull.post_json_for_success(
          OpenApiAssertNoNull.find_api("reqBodyRef"),
          "/openapi/req_body_ref",
          body,
          %{},
          [ignore_req_fields: [ignored_key]]
        )
      assert res.status == 200
    end
  end

  describe "allOf API" do
    test "should return 200 if requiredOne and requiredTwo is specified" do
      res = OpenApiAssert.get_for_success(OpenApiAssert.find_api("allOf"), "/openapi/all_of?one=true&two=true")
      assert res.status == 200
      assert Jason.decode!(res.body)["requiredOne"] == "one"
      assert Jason.decode!(res.body)["requiredTwo"] == "two"
    end

    test "wrongly return 200 if requiredOne lacks" do
      assert_raise AssertionError, fn ->
        OpenApiAssert.get_for_success(OpenApiAssert.find_api("allOf"), "/openapi/all_of?one=false&two=true")
      end
    end

    test "wrongly return 200 if requiredTwo lacks" do
      assert_raise AssertionError, fn ->
        OpenApiAssert.get_for_success(OpenApiAssert.find_api("allOf"), "/openapi/all_of?one=true&two=false")
      end
    end
  end
end
