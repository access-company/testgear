# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.AuthGreetingTest do
  use ExUnit.Case

  test "returns greeting with valid Authorization header" do
    response = Req.get("/auth_greeting", %{"authorization" => "Bearer mykey_testuser123"})
    assert response.status == 200
    assert Jason.decode!(response.body) == %{"message" => "Hello, testuser123"}
  end

  test "returns error when Authorization header is missing" do
    response = Req.get("/auth_greeting")
    assert response.status == 401
    assert Jason.decode!(response.body) == %{"error" => "Authorization header is required"}
  end

  test "returns error when Authorization header is invalid" do
    response = Req.get("/auth_greeting", %{"authorization" => "Bearer falsekey_testuser123"})
    assert response.status == 401
    assert Jason.decode!(response.body) == %{"error" => "Invalid authorization format. Expected 'Bearer <secret>_<username>'"}
  end

  test "returns error when Authorization header has no username" do
    response = Req.get("/auth_greeting", %{"authorization" => "Bearer mykey_"})
    assert response.status == 401
    assert Jason.decode!(response.body) == %{"error" => "Invalid authorization format. Expected 'Bearer <secret>_<username>'"}
  end

  test "returns greeting with special characters in username" do
    response = Req.get("/auth_greeting", %{"authorization" => "Bearer mykey_user@example.com"})
    assert response.status == 200
    assert Jason.decode!(response.body) == %{"message" => "Hello, user@example.com"}
  end

  test "returns error when Authorization header prefix is not 'Bearer'" do
    response = Req.get("/auth_greeting", %{"authorization" => "Basic testuser"})
    assert response.status == 401
    assert Jason.decode!(response.body) == %{"error" => "Invalid authorization format. Expected 'Bearer <secret>_<username>'"}
  end
end
