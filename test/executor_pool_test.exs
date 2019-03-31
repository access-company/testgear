# Copyright(c) 2015-2019 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.ExecutorPoolTest do
  use ExUnit.Case
  alias AntikytheraCore.ExecutorPool.RegisteredName, as: RegName

  test "gear should start with its own ExecutorPool" do
    epool_id = {:gear, :testgear}
    name = RegName.supervisor(epool_id)
    assert Application.started_applications() |> Enum.any?(&match?({:testgear, _, _}, &1))
    assert is_pid(Process.whereis(name))
    # testing stop of :testgear can interrupt other tests
  end
end
