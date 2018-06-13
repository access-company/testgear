# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.GearConfigTest do
  use ExUnit.Case
  alias Antikythera.Httpc
  alias Antikythera.Test.GearConfigHelper

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

    %Httpc.Response{status: status, body: body} = Req.get("/config_cache")
    %{"before" => config_before, "after" => config_after} = Poison.decode!(body)
    assert status == 200
    assert config == config_before
    assert config == config_after

    :ets.delete_all_objects(AntikytheraCore.Ets.ConfigCache.table_name())
  end
end
