# Copyright(c) 2015-2023 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Util do
  if Mix.env() == :test do
    def exhaust_heap_memory() do
      exhaust_heap_memory([])
    end
    defp exhaust_heap_memory(acc) do
      # binaries longer than 64byte goes out of per-process heap and become refc (reference-counted) binary
      s = String.duplicate("a", 55)
      Enum.reduce(1..10_000_000, acc, fn(i, acc) ->
        [s <> "#{i}", "#{i}" <> s | acc]
      end)
    end
  else
    def exhaust_heap_memory() do
    end
  end
end
