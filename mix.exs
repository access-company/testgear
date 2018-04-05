# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

dep_env_var = "SOLOMON_INSTANCE_DEP"
help_message = """
#{dep_env_var} must be a proper mix dependency tuple! Example:

{:your_solomon_instance, [git: "git@github.com:your_organization/your_solomon_instance.git"]}

"""

solomon_instance_dep =
  case System.get_env(dep_env_var) do
    nil           -> Mix.raise("You must supply #{dep_env_var} env var!")
    non_nil_value ->
      expression =
        try do
          {expression, _bindings} = Code.eval_string(non_nil_value)
          expression
        rescue
          e ->
            Mix.raise(Exception.message(e) <> "\n\n" <> help_message)
        end
      if is_tuple(expression), do: expression, else: Mix.raise(help_message)
  end

try do
  parent_dir = Path.expand("..", __DIR__)
  deps_dir =
    case Path.basename(parent_dir) do
      "deps" -> parent_dir                 # this gear project is used by another gear as a gear dependency
      _      -> Path.join(__DIR__, "deps") # this gear project is the toplevel mix project
    end
  Code.require_file(Path.join([deps_dir, "solomon", "mix_common.exs"]))

  defmodule Testgear.Mixfile do
    use Solomon.GearProject, [
      solomon_instance_dep:         solomon_instance_dep,
      source_url:                   "https://github.com/access-company/testgear",
      use_solomon_internal_module?: true,
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
  _any_error ->
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
