# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.ConfigCache do
  use Antikythera.Controller

  def check(conn) do
    config_before = Testgear.get_all_env()
    send(:test_runner, {:finished_fetching_gear_config, self()})
    receive do
      :gear_config_changed -> :ok
    end
    config_after = Testgear.get_all_env()
    Conn.json(conn, 200, %{before: config_before, after: config_after})
  end
end
