# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.SystemInfoExporterTest do
  use ExUnit.Case
  alias Antikythera.{Time, Httpc}
  alias Antikythera.Test.GearLogHelper
  alias AntikytheraCore.Handler.SystemInfoExporter.AccessToken
  require AntikytheraCore.Logger, as: L

  @base_url "http://127.0.0.1:#{Antikythera.Env.port_to_listen()}"

  setup do
    :meck.new(Time, [:passthrough])
    on_exit(&:meck.unload/0)
  end

  test "endpoints should reject request without valid token" do
    [
      "/versions",
      "/updatability",
      "/error_count/_total",
      "/error_count/antikythera",
    ] |> Enum.each(fn path ->
      res = Httpc.get!(@base_url <> path)
      assert res.status == 404
      assert res.body   == ""
    end)
  end

  defp get_with_token(path) do
    Httpc.get!(@base_url <> path, %{"authorization" => AccessToken.get()})
  end

  test "/versions should return versions for request with valid token" do
    res = get_with_token("/versions")
    assert res.status == 200
    expected_versions = Application.started_applications() |> Map.new(fn {n, _, v} -> {Atom.to_string(n), List.to_string(v)} end)
    String.split(res.body, "\n") |> Enum.each(fn line ->
      [name, version] = String.split(line)
      assert version == expected_versions[name]
    end)
  end

  test "/upgradability should return whether hot code upgrade is enabled for request with valid token" do
    assert %_{ status: 200, body: "true" } = get_with_token("/upgradability")

    AntikytheraCore.VersionUpgradeTaskQueue.disable()
    assert %_{ status: 200, body: "false" } = get_with_token("/upgradability")

    AntikytheraCore.VersionUpgradeTaskQueue.enable()
    assert %_{ status: 200, body: "true" } = get_with_token("/upgradability")
  end

  test "/error_count/:otp_app_name should reject request for nonexisting OTP application" do
    res = get_with_token("/error_count/abcnonexistingxyz")
    assert res.status == 404
    assert res.body   == ""
  end

  defp send_request_and_sum_error_counts(otp_app_name_or_total) do
    res = get_with_token("/error_count/#{otp_app_name_or_total}")
    assert res.status == 200
    m =
      String.split(res.body, "\n") |> Map.new(fn l ->
        [s, n] = String.split(l)
        {:ok, t} = Time.from_iso_timestamp(s)
        {t, String.to_integer(n)}
      end)
    assert map_size(m) == 10
    Map.values(m) |> Enum.sum()
  end

  @tag capture_log: true
  test "/error_count/:otp_app_name and /error_count/_total" do
    # flush existing error counts
    t1 = Time.now() |> Time.truncate_to_minute() |> Time.shift_minutes(1)
    :meck.expect(Time, :now, fn -> t1 end)
    L.error("ensure error in antikythera")
    :timer.sleep(10)
    send(AntikytheraCore.Alert.Manager, :error_count_reporter_timeout)
    GearLogHelper.set_context_id()
    Testgear.Logger.error("ensure error in testgear")
    :timer.sleep(10)
    send(Testgear.AlertManager, :error_count_reporter_timeout)
    :timer.sleep(10)
    send(AntikytheraCore.ErrorCountsAccumulator, :beginning_of_minute)
    n_antikythera = send_request_and_sum_error_counts("antikythera")
    n_testgear    = send_request_and_sum_error_counts("testgear"   )
    assert send_request_and_sum_error_counts("_total") == n_antikythera + n_testgear

    # antikythera's error
    L.error("testing SystemInfoExporter")
    :timer.sleep(10)
    send(AntikytheraCore.Alert.Manager, :error_count_reporter_timeout)
    :timer.sleep(10)

    t2 = Time.shift_minutes(t1, 1)
    :meck.expect(Time, :now, fn -> t2 end)
    send(AntikytheraCore.ErrorCountsAccumulator, :beginning_of_minute)
    assert send_request_and_sum_error_counts("antikythera") == n_antikythera + 1
    assert send_request_and_sum_error_counts("testgear"   ) == n_testgear
    assert send_request_and_sum_error_counts("_total"     ) == n_antikythera + n_testgear + 1

    # testgear's error
    Testgear.Logger.error("testing SystemInfoExporter")
    :timer.sleep(10)
    send(Testgear.AlertManager, :error_count_reporter_timeout)
    :timer.sleep(10)

    t3 = Time.shift_minutes(t2, 1)
    :meck.expect(Time, :now, fn -> t3 end)
    send(AntikytheraCore.ErrorCountsAccumulator, :beginning_of_minute)
    assert send_request_and_sum_error_counts("antikythera") == n_antikythera + 1
    assert send_request_and_sum_error_counts("testgear"   ) == n_testgear + 1
    assert send_request_and_sum_error_counts("_total"     ) == n_antikythera + n_testgear + 2
  end
end
