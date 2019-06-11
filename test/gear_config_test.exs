# Copyright(c) 2015-2019 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.GearConfigTest do
  use ExUnit.Case
  alias Antikythera.Httpc
  alias Antikythera.Test.GearConfigHelper

  setup do
    current_config = Testgear.get_all_env()
    on_exit(fn ->
      :ets.delete_all_objects(AntikytheraCore.Ets.ConfigCache.table_name())
      GearConfigHelper.set_config(current_config)
    end)
  end

  test "Testgear.get_all_env/0 and get_env/2" do
    assert      GearConfigHelper.set_config(%{}) == :ok
    assert      Testgear.get_all_env()     == %{}
    assert      Testgear.get_env("foo"   ) == nil
    assert      Testgear.get_env("foo", 0) == 0
    catch_error Testgear.get_env!("foo")

    assert      GearConfigHelper.set_config(%{"foo" => 1, "bar" => %{"nested" => "map"}}) == :ok
    assert      Testgear.get_all_env()       == %{"foo" => 1, "bar" => %{"nested" => "map"}}
    assert      Testgear.get_env("foo"     ) == 1
    assert      Testgear.get_env("foo", 0  ) == 1
    assert      Testgear.get_env!("foo")     == 1
    assert      Testgear.get_env("bar"     ) == %{"nested" => "map"}
    assert      Testgear.get_env("bar", %{}) == %{"nested" => "map"}
    assert      Testgear.get_env!("bar")     == %{"nested" => "map"}
    assert      Testgear.get_env("baz"     ) == nil
    assert      Testgear.get_env("baz", %{}) == %{}
    catch_error Testgear.get_env!("baz")
  end

  test "should not reflect changes in gear configs while handling web requests" do
    config = %{"foo" => 1, "bar" => %{"nested" => "map"}}
    assert GearConfigHelper.set_config(config) == :ok

    Process.register(self(), :test_runner)
    spawn(fn ->
      res = Req.get("/config_cache")
      send(:test_runner, {:received_response, res})
    end)

    assert_receive({:finished_fetching_gear_config, handler_pid}, 5_000)

    GearConfigHelper.set_config(%{"foo" => "not_to_be_cached"})
    {:dictionary, info_handling_request} = Process.info(handler_pid, :dictionary)
    assert Keyword.has_key?(info_handling_request, :gear_configs)

    send(handler_pid, :gear_config_changed)

    assert_receive({:received_response, res}, 5_000)
    %Httpc.Response{status: status, body: body} = res
    %{"before" => config_before, "after" => config_after} = Poison.decode!(body)
    assert status == 200
    assert config == config_before
    assert config == config_after
    {:dictionary, info_after_request} = Process.info(handler_pid, :dictionary)
    refute Keyword.has_key?(info_after_request, :gear_configs)
  end
end
