# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.McpTest do
  use ExUnit.Case

  @mcp_path "/mcp"

  describe "MCP initialize" do
    test "should respond with server info via SSE" do
      request_body = %{
        jsonrpc: "2.0",
        method: "initialize",
        id: 1,
        params: %{
          protocolVersion: "2025-03-26",
          capabilities: %{},
          clientInfo: %{
            name: "test-client",
            version: "1.0.0"
          }
        }
      }

      response = Req.post_json(@mcp_path, request_body, %{})

      assert response.status == 200
      assert response.headers["content-type"] == "text/event-stream"

      sse_data = parse_sse_response(response.body)
      assert sse_data["jsonrpc"] == "2.0"
      assert sse_data["id"] == 1
      assert sse_data["result"]["protocolVersion"] == "2025-03-26"
      assert sse_data["result"]["serverInfo"]["name"] == "testgear-mcp-server"
      assert sse_data["result"]["serverInfo"]["version"] == "1.0.0"
      assert sse_data["result"]["capabilities"]["tools"]["listChanged"] == false
    end
  end

  describe "MCP notifications/initialized" do
    test "should respond with 202 Accepted" do
      request_body = %{
        jsonrpc: "2.0",
        method: "notifications/initialized"
      }

      response = Req.post_json(@mcp_path, request_body, %{})

      assert response.status == 202
    end
  end

  describe "MCP tools/list" do
    test "should return list of available tools" do
      request_body = %{
        jsonrpc: "2.0",
        method: "tools/list",
        id: 2
      }

      response = Req.post_json(@mcp_path, request_body, %{})

      assert response.status == 200
      assert response.headers["content-type"] == "text/event-stream"

      sse_data = parse_sse_response(response.body)
      assert sse_data["jsonrpc"] == "2.0"
      assert sse_data["id"] == 2

      tools = sse_data["result"]["tools"]
      assert is_list(tools)
      assert length(tools) == 3

      tool_names = Enum.map(tools, & &1["name"])
      assert "testgear" in tool_names
      assert "get_json" in tool_names
      assert "auth_greeting" in tool_names
    end

    test "should return tools with correct schema" do
      request_body = %{
        jsonrpc: "2.0",
        method: "tools/list",
        id: 3
      }

      response = Req.post_json(@mcp_path, request_body, %{})
      sse_data = parse_sse_response(response.body)

      tools = sse_data["result"]["tools"]
      testgear_tool = Enum.find(tools, &(&1["name"] == "testgear"))

      assert testgear_tool["description"] == "Send Data to TestGear API"
      assert testgear_tool["inputSchema"]["type"] == "object"
      assert testgear_tool["inputSchema"]["properties"]["data"]["type"] == "string"
    end
  end

  describe "MCP tools/call" do
    test "testgear tool should return response text" do
      request_body = %{
        jsonrpc: "2.0",
        method: "tools/call",
        id: 4,
        params: %{
          name: "testgear",
          arguments: %{
            data: "test_data"
          }
        }
      }

      response = Req.post_json(@mcp_path, request_body, %{})

      assert response.status == 200
      assert response.headers["content-type"] == "text/event-stream"

      sse_data = parse_sse_response(response.body)
      assert sse_data["jsonrpc"] == "2.0"
      assert sse_data["id"] == 4
      assert is_list(sse_data["result"]["content"])

      content = hd(sse_data["result"]["content"])
      assert content["type"] == "text"
      assert String.contains?(content["text"], "API Response")
      assert String.contains?(content["text"], "from G2G")
    end

    test "testgear tool should use default data when not provided" do
      request_body = %{
        jsonrpc: "2.0",
        method: "tools/call",
        id: 5,
        params: %{
          name: "testgear",
          arguments: %{}
        }
      }

      response = Req.post_json(@mcp_path, request_body, %{})

      assert response.status == 200
      sse_data = parse_sse_response(response.body)
      assert sse_data["result"]["content"] != nil
    end

    test "get_json tool should return JSON response with structuredContent" do
      request_body = %{
        jsonrpc: "2.0",
        method: "tools/call",
        id: 6,
        params: %{
          name: "get_json",
          arguments: %{}
        }
      }

      response = Req.post_json(@mcp_path, request_body, %{})

      assert response.status == 200
      sse_data = parse_sse_response(response.body)
      assert sse_data["jsonrpc"] == "2.0"
      assert sse_data["id"] == 6

      result = sse_data["result"]
      assert is_list(result["content"])
      assert result["structuredContent"]["status"] == 200
      assert is_map(result["structuredContent"]["body"])
    end

    test "auth_greeting tool should return response" do
      request_body = %{
        jsonrpc: "2.0",
        method: "tools/call",
        id: 7,
        params: %{
          name: "auth_greeting",
          arguments: %{}
        }
      }

      response = Req.post_json(@mcp_path, request_body, %{})

      assert response.status == 200
      sse_data = parse_sse_response(response.body)
      assert sse_data["jsonrpc"] == "2.0"
      assert sse_data["id"] == 7
      assert sse_data["result"]["structuredContent"] != nil
    end

    test "auth_greeting tool should return greeting when authorized" do
      request_body = %{
        jsonrpc: "2.0",
        method: "tools/call",
        id: 8,
        params: %{
          name: "auth_greeting",
          arguments: %{}
        }
      }

      response = Req.post_json(@mcp_path, request_body, %{
        "authorization" => "Bearer mykey_testuser"
      })

      assert response.status == 200
      sse_data = parse_sse_response(response.body)
      result = sse_data["result"]["structuredContent"]
      assert result["status"] == 200
      assert result["body"]["message"] == "Hello, testuser"
    end

    test "should return error for unknown tool" do
      request_body = %{
        jsonrpc: "2.0",
        method: "tools/call",
        id: 9,
        params: %{
          name: "nonexistent_tool",
          arguments: %{}
        }
      }

      response = Req.post_json(@mcp_path, request_body, %{})

      assert response.status == 200
      sse_data = parse_sse_response(response.body)
      assert sse_data["jsonrpc"] == "2.0"
      assert sse_data["id"] == 9
      assert sse_data["error"]["code"] == -32_601
      assert String.contains?(sse_data["error"]["message"], "Tool not found")
    end
  end

  describe "MCP unknown method" do
    test "should return error for unknown method" do
      request_body = %{
        jsonrpc: "2.0",
        method: "unknown/method",
        id: 10
      }

      response = Req.post_json(@mcp_path, request_body, %{})

      assert response.status == 400
      body = Jason.decode!(response.body)
      assert body["error"] == "Unknown method"
    end
  end

  describe "MCP method not allowed" do
    test "GET request should return 405 Method Not Allowed" do
      response = Req.get(@mcp_path)

      assert response.status == 405
      body = Jason.decode!(response.body)
      assert body["jsonrpc"] == "2.0"
      assert body["error"]["code"] == -32_000
      assert body["error"]["message"] == "Method not allowed."
    end

    test "DELETE request should return 405 Method Not Allowed" do
      response = Req.delete(@mcp_path)

      assert response.status == 405
      body = Jason.decode!(response.body)
      assert body["jsonrpc"] == "2.0"
      assert body["error"]["code"] == -32_000
      assert body["error"]["message"] == "Method not allowed."
    end
  end

  # Helper function to parse SSE response
  defp parse_sse_response(body) do
    body
    |> String.split("\n")
    |> Enum.find(&String.starts_with?(&1, "data: "))
    |> String.trim_leading("data: ")
    |> Jason.decode!()
  end
end
