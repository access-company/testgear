# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

solomon_instance_dep = {:solomon, [git: "git@github.com:access-company/solomon.git"]}

try do
  parent_dir_basename = Path.absname(__DIR__) |> Path.dirname() |> Path.basename()
  deps_dir =
    case parent_dir_basename do
      "deps" -> ".." # This gear is used by another gear as a gear dependency
      _      -> "deps"
    end
  mix_common_file_path = Path.join([__DIR__, deps_dir, "solomon", "mix_common.exs"])
  Code.require_file(mix_common_file_path)

  defmodule Testgear.Mixfile do
    use Solomon.GearProject, [
      solomon_instance_dep: solomon_instance_dep,
    ]

    defp gear_name(), do: :testgear
    defp version()  , do: "0.0.1"
    defp gear_deps(), do: []

    # Note that we always put the following env vars regardless of `Mix.env()`, as they are not yet set by `Mix.Tasks.Test` task.

    # Tweak GEAR_ACTION_TIMEOUT to accelerate tests for timeout errors.
    System.put_env("GEAR_ACTION_TIMEOUT", "1000")

    # Tweak GEAR_PROCESS_MAX_HEAP_SIZE to quickly reach the limit in tests
    System.put_env("GEAR_PROCESS_MAX_HEAP_SIZE", "5000000")
  end
rescue
  Code.LoadError ->
    defmodule SolomonGearInitialSetup.Mixfile do
      use Mix.Project

      def project() do
        [
          app:  :just_to_fetch_solomon_instance_as_a_dependency,
          deps: [unquote(solomon_instance_dep)],
        ]
      end
    end
end
