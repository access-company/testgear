# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

dep_env_var = "SOLOMON_INSTANCE_DEP"
help_message = """
You must supply a proper mix dependency tuple as a solomon_instance_dep!
Example:

    {:your_solomon_instance, [git: "git@github.com:your_organization/your_solomon_instance.git"]}

"""

solomon_instance_dep_from_string = fn string ->
  try do
    {expression, _bindings} = Code.eval_string(string)
    if is_tuple(expression), do: expression, else: raise(help_message)
  rescue
    e ->
      raise(Exception.message(e) <> "\n\n" <> help_message)
  end
end

solomon_instance_dep =
  case System.get_env(dep_env_var) do
    nil           -> raise("You must supply #{dep_env_var} env var!")
    non_nil_value -> solomon_instance_dep_from_string.(non_nil_value)
  end

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
      source_url:           "https://github.com/access-company/testgear",
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
