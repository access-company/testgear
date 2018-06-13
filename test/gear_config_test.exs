# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.GearConfigTest do
  use ExUnit.Case
  alias Antikythera.Httpc
  alias Antikythera.Test.GearConfigHelper
  alias AntikytheraCore.Config.Gear, as: GearConfig
  alias AntikytheraCore.Ets.ConfigCache

  setup do
    current_config = Testgear.get_all_env()
    on_exit(fn ->
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

    :ets.delete_all_objects(AntikytheraCore.Ets.ConfigCache.table_name())
  end

  test "should not reflect changes in gear configs while handling web requests" do
    config = %{"foo" => 1, "bar" => %{"nested" => "map"}}
    assert GearConfigHelper.set_config(config) == :ok

    Process.register(self(), :test_runner)
    spawn(fn ->
      res = Req.get("/config_cache")
      send(:test_runner, {:received_response, res})
    end)
    receive do
      {:finished_fetching_gear_config, caller} ->
        set_gear_config_only_in_ets(%{"foo" => "not_to_be_cached"})
        send(caller, :gear_config_changed)
    end
    receive do
      {:received_response, res} ->
        %Httpc.Response{status: status, body: body} = res
        %{"before" => config_before, "after" => config_after} = Poison.decode!(body)
        assert status == 200
        assert config == config_before
        assert config == config_after
    end

    Process.unregister(:test_runner)
    :ets.delete_all_objects(AntikytheraCore.Ets.ConfigCache.table_name())
  end

  defp set_gear_config_only_in_ets(kv) do
    new_config = %GearConfig{kv: kv, domains: [], log_level: :info, alerts: %{}}
    GearConfig.write(:testgear, new_config)
    ConfigCache.Gear.write(:testgear, new_config)
  end
end
