# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.LoggerTest do
  use ExUnit.Case
  alias SolomonLib.Test.ProcessHelper
  alias SolomonCore.Path, as: CorePath
  alias SolomonCore.GearModule
  alias SolomonCore.GearLog.Writer

  defp find_log_files(dir) do
    uploaded = Path.wildcard(Path.join(dir, "testgear.log.*.uploaded.gz"))
    rotated  = Path.wildcard(Path.join(dir, "testgear.log.*.gz")) -- uploaded
    {rotated, uploaded}
  end

  test "should rotate and start uploading" do
    log_dir = CorePath.gear_log_file_path(:testgear) |> Path.dirname()
    logger_name = GearModule.logger(:testgear)
    %{uploader: nil} = :sys.get_state(logger_name)
    {rotated_logs_before, uploaded_logs_before} = find_log_files(log_dir)

    assert Writer.rotate_and_start_upload_in_all_nodes(:testgear) == :abcast
    %{uploader: uploader} = :sys.get_state(logger_name)
    assert is_pid(uploader)
    assert Writer.rotate_and_start_upload_in_all_nodes(:testgear) == :abcast
    %{uploader: ^uploader} = :sys.get_state(logger_name) # don't spawn multiple uploader processes simultaneously
    ProcessHelper.monitor_wait(uploader)

    {rotated_logs_after, uploaded_logs_after} = find_log_files(log_dir)
    assert rotated_logs_after == []
    uploaded_logs_created = uploaded_logs_after -- uploaded_logs_before
    assert length(uploaded_logs_created) == length(rotated_logs_before) + 1
    Enum.zip(uploaded_logs_created, rotated_logs_before)
    |> Enum.each(fn {uploaded_log, rotated_log} ->
      assert String.replace_suffix(uploaded_log, ".uploaded.gz", ".gz") == rotated_log
    end)
  end
end
