# AGENTS.md

Comprehensive guidelines for both AI agents and human developers working on **Testgear**.

## References

- [`README.md`](./README.md) — project overview, installation, and the `ANTIKYTHERA_INSTANCE_DEP` requirement.
- Antikythera [`STYLE_GUIDE.md`](https://github.com/access-company/antikythera/blob/master/STYLE_GUIDE.md) — coding conventions (vendored copy: `deps/antikythera/STYLE_GUIDE.md`).
- Antikythera [`CONTRIBUTING.md`](https://github.com/access-company/antikythera/blob/master/CONTRIBUTING.md) — contribution workflow and self-review checklist (vendored copy: `deps/antikythera/CONTRIBUTING.md`).
- [Antikythera documentation](https://hexdocs.pm/antikythera) and [Testing in gears](https://hexdocs.pm/antikythera/testing.html).
- [Croma.Defun](https://hexdocs.pm/croma/Croma.Defun.html) — typespec/validation helpers referenced by the style guide.

## Overview

Testgear is a **gear application of [Antikythera]**. As the name suggests, it is used for testing Antikythera's core functionality. It is:

- installable to any Antikythera instance,
- utilized in Antikythera's upgrade compatibility test, and
- a sample case of gear application implementation.

Code layout:

- `lib/` — gear library code (`testgear.ex`, helpers, and `lib/testgear/`).
- `web/` — controllers, templates, router (`web/router.ex`), websocket, assets.
- `test/` — ExUnit whitebox/blackbox tests (`*_test.exs`) and `test/test_helper.exs`.
- `priv/`, `script/` — supporting assets and scripts.

[Antikythera]: https://github.com/access-company/antikythera

## Commands

> **Prerequisite:** `ANTIKYTHERA_INSTANCE_DEP` **MUST** be exported whenever `mix` is involved, because `mix.exs` evaluates it. Example:
>
> ```sh
> export ANTIKYTHERA_INSTANCE_DEP='{:antikythera_instance_example, [git: "git@github.com:access-company/antikythera_instance_example.git"]}'
> ```

| Purpose | Command |
| --- | --- |
| Install dependencies | `mix deps.get && mix deps.get` |
| Compile | `mix compile` |
| Run (interactive shell) | `iex -S mix` |
| Format | `mix format` |
| Test (whitebox) | `mix test` |
| Typecheck | `mix dialyzer` |
| Static code analysis | `mix credo -a --strict` |

Additional checks used in the contribution workflow (see Antikythera `CONTRIBUTING.md`):

- Blackbox test: `TEST_MODE=blackbox_local mix test`
- Markdown lint (config: `.markdownlint-cli2.yaml`): `markdownlint-cli2 --fix "**/*.md"`
- Docs build: `mix docs`

> **Note:** `mix deps.get` must be run **multiple times** until all dependencies are resolved. The first run fetches the Antikythera instance; subsequent runs fetch the dev/test-only dependencies it declares. Repeat until no new dependencies are fetched.

## Development Rules

Follow Antikythera's [`STYLE_GUIDE.md`](https://github.com/access-company/antikythera/blob/master/STYLE_GUIDE.md) (mostly [Credo's Elixir Style Guide](https://github.com/rrrene/elixir-style-guide)) and the self-review checklist in [`CONTRIBUTING.md`](https://github.com/access-company/antikythera/blob/master/CONTRIBUTING.md). Keep changes small, single-responsibility, and consistent with surrounding code.

### Reviewer checklist (highlights)

- [ ] **Parentheses:** never omit parentheses in function calls or definitions (macros MAY be called without them).
- [ ] **Module names:** use CamelCase even for acronyms — `Antikythera.Url`, not `Antikythera.URL`.
- [ ] **Alias order:** order aliases by generality — external modules → `Antikythera` → `AntikytheraCore` → `AntikytheraEal`; bundle same-level aliases (e.g. `alias Antikythera.{GearName, GearNameStr}`).
- [ ] **Typespecs:** declare typespecs, especially for public functions; prefer `Croma.Defun` and `v[]` validations.
- [ ] **`import`:** do not abuse it; scope it and limit with `:only`.
- [ ] **Pipe `|>`:** use only when it improves readability (complex first argument or a data-transformation chain), not for trivial single calls.
- [ ] **Docs & comments:** provide `@moduledoc`/`@doc`/`@typedoc` for public modules/functions; add explanatory comments for any workaround or hacky code.
- [ ] **Tests:** cover the behavior of public interfaces; when behavior must be verified through an actual gear, add/extend Testgear controllers, routes, and request/response tests.
- [ ] **Self-review:** review your own diff before requesting review; ensure it fits existing code.

### Auto-generated & read-only files

- Do **not** hand-edit generated or fetched directories: `_build/`, `_build_local/`, `cover/`, `deps/`, `exdoc/`, and `doc/` (regenerate `doc`/`exdoc` via `mix docs`).
- `.credo.exs` and `.tool-versions` are **symlinks into `deps/antikythera/`** — treat them as read-only; change the source in Antikythera, not the links.
- `mix.lock` is intentionally git-ignored (exact deps are determined per Antikythera instance and are not globally shareable). Do not commit it.
- `CLAUDE.md` only re-exports this file (`@AGENTS.md`); edit `AGENTS.md`, not `CLAUDE.md`.

## Definition of Done

A change is done only when **all** of the following pass, in order:

1. **Run tests:** `mix test` (and `TEST_MODE=blackbox_local mix test` when behavior is exercised through the running gear) — all green.
2. **Lint / typecheck:** `mix format`, `mix compile`, `mix credo -a --strict`, and `mix dialyzer` produce no new warnings or errors. Run `markdownlint-cli2 --fix "**/*.md"` when Markdown files changed.
3. **Review:** self-review the diff against the **Reviewer checklist** in [Development Rules](#development-rules) and confirm every item.
4. **Re-verify:** if steps 2 or 3 modified any files, **re-run** the relevant tests, linting, and typechecking until they pass again.
