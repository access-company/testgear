# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.SseTest do
  use ExUnit.Case

  test "sse_short should respond with single SSE event" do
    expected_body = """
    event: message
    data: Hello from SSE
    id: 1

    """

    response = Req.get("/sse_short")

    assert response.status == 200
    assert response.headers["content-type"] == "text/event-stream"
    assert response.body == expected_body
  end

  test "sse_long should respond with complete SSE event stream" do
    expected_body = """
    event: start
    data: SSE connection established
    id: 1

    event: message
    data: Message 2
    id: 2

    event: message
    data: Message 3
    id: 3

    event: message
    data: Message 4
    id: 4

    event: message
    data: Message 5
    id: 5

    event: end
    data: Sent 5 messages: start, Message 2, Message 3, Message 4, Message 5
    id: 6

    """

    response = Req.get("/sse_long")

    assert response.status == 200
    assert response.headers["content-type"] == "text/event-stream"
    assert response.body == expected_body
  end

  test "sse_long should take appropriate time due to streaming delays" do
    # The SSE endpoint has sleep delays:
    # - No sleep for first event (start)
    # - 100ms sleep for each of 4 message events = 400ms
    # - 100ms sleep for end event = 100ms
    # Total expected: ~500ms

    start_time = System.monotonic_time(:millisecond)
    response = Req.get("/sse_long")
    end_time = System.monotonic_time(:millisecond)

    duration = end_time - start_time

    assert response.status == 200

    # Assert response took at least 400ms (accounting for some timing variance)
    assert duration >= 400, "Expected at least 400ms, got #{duration}ms"

    # Assert response didn't take too long (less than 1 second)
    assert duration < 1000, "Expected less than 1000ms, got #{duration}ms"
  end

  test "streaming_no_body should respond with 202 Accepted and empty body" do
    response = Req.get("/streaming_no_body")

    assert response.status == 202
    assert response.body == ""
  end
end
