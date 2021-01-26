# Copyright(c) 2015-2021 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.TestAsyncJob do
  use Antikythera.AsyncJob
  alias Antikythera.Context
  alias Antikythera.AsyncJob.Metadata
  alias Testgear.{Logger, Util}

  @impl true
  def run(payload, %Metadata{}, %Context{}) do
    Logger.info("should be able to emit log in async job")
    case payload[:todo] do
      :ok                  -> :ok
      :send                -> send_message()
      {:sleep, ms}         ->
        :timer.sleep(ms)
        send_message()
      :raise               ->
        send_message()
        raise "job failed!"
      :throw               ->
        send_message()
        throw "job failed!"
      :exit                ->
        send_message()
        exit "job failed!"
      :exhaust_heap_memory ->
        send_message()
        Util.exhaust_heap_memory()
    end
  end

  defp send_message() do
    Logger.info("should be able to emit log in async job")
    send(__MODULE__, {:executing, self()})
  end

  @impl true
  def abandon(_payload, %Metadata{}, %Context{}) do
    Logger.info("should be able to emit log in async job")
    send(__MODULE__, {:abandon, self()})
  end
end
