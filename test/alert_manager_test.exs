# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

use Croma

defmodule Testgear.AlertManagerTest do
  use Croma.TestCase, alias_as: GearNManager
  alias Antikythera.{Time, Test.GearLogHelper}
  alias AntikytheraCore.Ets.ConfigCache
  alias AntikytheraCore.Config.Gear, as: GearConfig
  alias AntikytheraCore.Alert.Manager, as: CoreNManager
  alias AntikytheraCore.Alert.Handler, as: AHandler
  alias AntikytheraCore.Alert.Handler.Email, as: EmailHandler
  alias AntikytheraCore.Alert.ErrorCountReporter
  alias AntikytheraEal.AlertMailer.{Mail, MemoryInbox}

  defp which_handlers() do
    :gen_event.which_handlers(GearNManager)
  end

  setup do
    :meck.new(ConfigCache.Gear, [:passthrough])
    on_exit(fn ->
      CoreNManager.update_handler_installations(:testgear, %{}) # reset
      MemoryInbox.clean()
      :meck.unload()
    end)
  end

  test "should install/uninstall handler if the gear config has sufficient information" do
    assert which_handlers() == [ErrorCountReporter]

    valid_config = %{"email" => %{"to" => ["test@example.com"]}}
    update_handler_installations_and_mock_gear_config_cache(valid_config)
    assert which_handlers() == [{AHandler, EmailHandler}, ErrorCountReporter]

    update_handler_installations_and_mock_gear_config_cache(%{})
    assert which_handlers() == [ErrorCountReporter]
  end

  test "should start fast-then-delayed alert chain on message" do
    valid_config = %{"email" => %{"to" => ["test@example.com"], "fast_interval" => 1, "delayed_interval" => 2}}
    update_handler_installations_and_mock_gear_config_cache(valid_config)
    assert which_handlers() == [{AHandler, EmailHandler}, ErrorCountReporter]
    assert %{message_buffer: [], busy?: false} = get_handler_state(EmailHandler)

    GearNManager.notify("test_body\nsecond line")
    assert %{message_buffer: buffer, busy?: true} = get_handler_state(EmailHandler)
    assert [{time, "test_body\nsecond line"}] = buffer
    :timer.sleep(1_100)
    assert %{message_buffer: [], busy?: true} = get_handler_state(EmailHandler)
    assert [%Mail{to: ["test@example.com"], subject: subject, body: body}] = MemoryInbox.get()
    assert String.ends_with?(subject, "test_body")
    assert body ==
      """
      [#{Time.to_iso_timestamp(time)}] test_body
      second line


      """

    :timer.sleep(2_000)
    assert %{message_buffer: [], busy?: false} = get_handler_state(EmailHandler)
  end

  test "should get notified via <GearName>.Logger.error/1 call" do
    valid_config = %{"email" => %{"to" => ["test@example.com"], "fast_interval" => 1, "delayed_interval" => 1}}
    update_handler_installations_and_mock_gear_config_cache(valid_config)
    assert %{message_buffer: [], busy?: false} = get_handler_state(EmailHandler)

    GearLogHelper.set_context_id()
    Testgear.Logger.error("error from gear logger")
    assert %{message_buffer: [{_time, message}], busy?: true} = get_handler_state(EmailHandler)
    assert "error from gear logger\nContext: " <> _context_id = message
    :timer.sleep(2_100) # wait for handler to become non-busy
  end

  defp update_handler_installations_and_mock_gear_config_cache(alert_config) do
    assert CoreNManager.update_handler_installations(:testgear, alert_config) == :ok
    mock_config = %GearConfig{ConfigCache.Gear.read(:testgear) | alerts: alert_config}
    :meck.expect(ConfigCache.Gear, :read, fn
      :testgear -> mock_config
      _         -> GearConfig.default()
    end)
  end

  defp get_handler_state(handler) do
    :sys.get_state(GearNManager)
    |> Enum.find(&match?({_, ^handler, _}, &1))
    |> elem(2)
  end
end
