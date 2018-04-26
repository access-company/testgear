# Testgear

A gear application of [Antikythera]. As the name suggests, used for testing [Antikythera]'s core functionality.

[Antikythera]: https://github.com/access-company/antikythera

Testgear is:

- installable to any [Antikythera] instances
- utilized in [upgrade compatibility test][uct]
- also, a sample case of gear application implementation

[uct]: https://github.com/access-company/antikythera/blob/master/local/mix/upgrade_compatibility_test.ex

## Installation

Testgear can be installed to any Antikythera instances.

To do so, you must supply `ANTIKYTHERA_INSTANCE_DEP` environment variable.
It must declare dependency to your Antikythera instance in the form of dependency tuple,
just like you do in ordinary `mix.exs` file.

Example sequence up to compilation:

```sh
$ git clone https://github.com/access-company/testgear.git
$ cd testgear
$ ANTIKYTHERA_INSTANCE_DEP='{:instance_name, [git: "git@github.com:your_organization/instance_name.git"]}'
$ export ANTIKYTHERA_INSTANCE_DEP
$ mix deps.get
* Getting instance_name (git@github.com:your_organization/instance_name.git)
... (snip)

$ mix deps.get # Fetch dev/test-only dependencies declared in instance_name
$ mix compile
$ unset ANTIKYTHERA_INSTANCE_DEP
```

`ANTIKYTHERA_INSTANCE_DEP` is required **whenever `mix` is involved**, since testgear's `mix.exs` file depends on its value.

When you run already compiled Testgear with your Antikythera instance release (generated by [mix task][gr]),
all necessary information are stored in `testgear.app` so the environment variable is no longer needed.

[gr]: https://github.com/access-company/antikythera/blob/master/core/mix/generate_release.ex

## Copyright and License

Copyright(c) 2015-2018 [ACCESS CO., LTD](https://www.access-company.com). All rights reserved.

Antikythera source code is licensed under the [Apache License version 2.0](./LICENSE).
