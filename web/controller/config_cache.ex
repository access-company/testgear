# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.ConfigCache do
  use Antikythera.Controller

  def check(conn) do
    config_before = Testgear.get_all_env()
    set_cache()
    config_after = Testgear.get_all_env()
    Conn.json(conn, 200, %{before: config_before, after: config_after})
  end

  defp set_cache() do
    # Avoid compile errors due to calling AntikytheraCore modules directly by using 'apply/3'.
    gear_config_module  = Module.safe_concat(["AntikytheraCore", "Config", "Gear"])
    config_cache_module = Module.safe_concat(["AntikytheraCore", "Ets", "ConfigCache", "Gear"])
    new_config = apply(gear_config_module, :new!, [%{kv: %{"foo" => "not_to_be_cached"}, domains: [], log_level: :info, alerts: %{}}])
    apply(gear_config_module , :write, [:testgear, new_config])
    apply(config_cache_module, :write, [:testgear, new_config])
  end
end
