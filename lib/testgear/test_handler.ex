# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.TestHandler do
  @behaviour :gen_event

  @impl true
  def init(args) do
    {:ok, args}
  end

  @impl true
  def handle_event(:kick, _state) do
    {:ok, SolomonLib.Time.now()}
  end
  def handle_event(_msg, state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:current, state) do
    {:ok, state, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:ok, state}
  end

  @impl true
  def terminate(_reason, _state) do
    :ok
  end

  @impl true
  def code_change(_old, state, _extra) do
    {:ok, state}
  end
end
