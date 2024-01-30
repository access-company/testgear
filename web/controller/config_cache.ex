# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.ConfigCache do
  use Antikythera.Controller

  def check(conn) do
    config_before = Testgear.get_all_env()
    try do
      send(:test_runner, {:finished_fetching_gear_config, self()})
    rescue
      ArgumentError -> :ok
    end
    receive do
      :gear_config_changed -> :ok
    after
      5_000 -> :ok
    end
    config_after = Testgear.get_all_env()
    Conn.json(conn, 200, %{before: config_before, after: config_after})
  end
end
