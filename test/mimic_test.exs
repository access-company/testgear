# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

# Demonstrates mocking `Testgear.Greeter.greeting/0` (called from the `Hello.greeting/1`
# controller action) with Mimic, contrasting the two situations Mimic distinguishes:
#
#   * Same process     - the controller action runs in the *test* process, so a default
#                        (private mode) Mimic stub is visible to it.
#   * Different process - the controller action runs in a separate executor-pool process,
#                        so the stub is only visible when Mimic is switched to global mode.
#
# `ReqInProcess` (Antikythera.Test.InProcessClient) executes the action inline, in the
# caller's process, whereas `Req` (Antikythera.Test.HttpClient) sends a real HTTP request
# that the gear handles in its own process.

defmodule Testgear.MimicSameProcessTest do
  use ExUnit.Case, async: true
  use Mimic

  test "private-mode stub is visible because the controller action runs in the same process" do
    stub(Testgear.Greeter, :greeting, fn -> "Mocked greeting (same process)" end)

    res = ReqInProcess.get("/greeting")
    assert res.status == 200
    body = Poison.decode!(res.body)
    assert body["message"] == "Mocked greeting (same process)"
    # The action ran inline, i.e. in this very test process.
    assert body["pid"] == inspect(self())
  end

  test "without a stub the real implementation is used" do
    res = ReqInProcess.get("/greeting")
    assert Poison.decode!(res.body)["message"] == "Hello from the real Greeter"
  end
end

defmodule Testgear.MimicDifferentProcessTest do
  # Global mode replaces the module for *all* processes, so it must not run concurrently
  # with other tests.
  use ExUnit.Case, async: false
  use Mimic

  setup :set_mimic_global

  test "global-mode stub is visible in the separate process that handles the HTTP request" do
    stub(Testgear.Greeter, :greeting, fn -> "Mocked greeting (different process)" end)

    res = Req.get("/greeting")
    assert res.status == 200
    body = Poison.decode!(res.body)
    assert body["message"] == "Mocked greeting (different process)"
    # The action ran in the gear's executor-pool process, not in this test process.
    refute body["pid"] == inspect(self())
  end
end
