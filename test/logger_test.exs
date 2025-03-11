# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.LoggerTest do
  use ExUnit.Case
  alias Antikythera.Test.{GearLogHelper, ProcessHelper}
  alias AntikytheraCore.Path, as: CorePath
  alias AntikytheraCore.GearModule
  alias AntikytheraCore.GearLog.Writer

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

    # Make sure that a new rotated file is created and its file name isn't conflicted with existing ones.
    # FileHandle.rotated_file_path/1 uses current seconds as a suffix of the file name.
    # We need to 1 second sleep to avoid the confliction.
    GearLogHelper.set_context_id()
    Testgear.Logger.error("ensure log to be rotated")
    :timer.sleep(1000)

    # This should create a new rotated log file and start uploading it because there are logs in the current log file.
    assert Writer.rotate_and_start_upload_in_all_nodes(:testgear) == :abcast
    %{uploader: uploader} = :sys.get_state(logger_name)
    assert is_pid(uploader)
    # This shouldn't create a new rotated log file because there are no logs in the current log file.
    # But, this may be flaky because other process may write logs to the current log file.
    # In this case, AntikytheraEal.LogStorage.FileSystem.upload_rotated_logs/1 may upload this log file
    # depending on where upload_rotated_logs/1 is processing.
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
