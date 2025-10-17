defmodule Testgear.HttpcWithLoggingTest do
  use ExUnit.Case
  alias Testgear.HttpcWithLoggingNoLog, as: NoLog
  alias Testgear.HttpcWithLoggingWithLog, as: WithLog

  @test_url "http://example.com"
  @test_body ""
  @test_headers %{"content-type" => "application/json", "authorization" => "Bearer token"}
  @test_options [timeout: 1000]
  @success_response %{status: 200, body: "ok", headers: %{}}

  setup do
    :meck.new(Antikythera.Httpc, [:passthrough])
    :meck.new(Testgear.Logger, [:passthrough])

    on_exit(&:meck.unload/0)
  end

  test "The default log implementation should use GearLog" do
    :meck.expect(Antikythera.Httpc, :request, fn :get, url, body, headers, options ->
      assert url == @test_url
      assert body == @test_body
      assert headers == @test_headers
      assert options == @test_options
      {:ok, @success_response}
    end)

    :meck.expect(Testgear.Logger, :info, fn msg ->
      # The default log message
      assert msg =~ "HTTP"
      :ok
    end)

    assert {:ok, @success_response} = NoLog.request(:get, @test_url, @test_body, @test_headers, @test_options)
    assert :meck.called(Testgear.Logger, :info, 1)
  end

  test "The original log/9 implementation should be called" do
    :meck.expect(Antikythera.Httpc, :request, fn :get, url, body, headers, options ->
      assert url == @test_url
      assert body == @test_body
      assert headers == @test_headers
      assert options == @test_options
      {:ok, @success_response}
    end)

    :meck.expect(Testgear.Logger, :info, fn msg ->
      assert msg =~ "CustomLog:"
      :ok
    end)

    assert {:ok, @success_response} = WithLog.request(:get, @test_url, @test_body, @test_headers, @test_options)
    assert :meck.called(Testgear.Logger, :info, 1)
  end
end
