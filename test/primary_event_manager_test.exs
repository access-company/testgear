# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.PrimaryEventManagerTest do
  use Croma.TestCase
  alias Testgear.TestHandler

  test "gear should start with its own primary event manager process under its supervision tree" do
    s_pid = Process.whereis(Testgear.Supervisor)
    {_, pid, _, _} =
      Supervisor.which_children(s_pid)
      |> Enum.find(fn {module, _, _, _} -> module == SolomonCore.PrimaryEventManager end)
    assert Process.whereis(PrimaryEventManager) == pid
  end

  test "Primary event manager process of the gear should start with defined event handlers installed" do
    defined_handlers = Testgear.primary_event_handlers() |> Enum.map(fn {handler, _state} -> handler end)
    assert defined_handlers == [TestHandler, {Testgear.TestHandler, 0}]
    installed_handlers = PrimaryEventManager.installed_handlers() |> Enum.sort()
    assert installed_handlers == defined_handlers
  end

  test "APIs of `Testgear.PrimaryEventManager` should allow access to primary event manager process" do
    assert nil == PrimaryEventManager.call(TestHandler, :current)
    assert :ok == PrimaryEventManager.notify(:kick)
    time1 = PrimaryEventManager.call(TestHandler, :current)
    assert {SolomonLib.Time, _, _, _} = time1
    time2 = PrimaryEventManager.call({TestHandler, 0}, :current)
    assert {SolomonLib.Time, _, _, _} = time2
  end
end
