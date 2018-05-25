# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.GearConfigTest do
  use ExUnit.Case
  alias AntikytheraCore.Ets.ConfigCache.Gear, as: Cache
  alias AntikytheraCore.Config.Gear, as: GearConfig

  setup do
    current_config = Testgear.get_all_env()
    on_exit(fn ->
      Antikythera.Test.GearConfigHelper.set_config(current_config)
      System.delete_env("LOG_LEVEL")
    end)
  end

  test "Testgear.get_all_env/0 and get_env/2" do
    assert Cache.write(:testgear, %GearConfig{kv: %{}, domains: [], log_level: :info, alerts: %{}}) == :ok
    assert      Testgear.get_all_env()     == %{}
    assert      Testgear.get_env("foo"   ) == nil
    assert      Testgear.get_env("foo", 0) == 0
    catch_error Testgear.get_env!("foo")

    assert Cache.write(:testgear, %GearConfig{kv: %{"foo" => 1, "bar" => %{"nested" => "map"}}, domains: [], log_level: :info, alerts: %{}}) == :ok
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
end
