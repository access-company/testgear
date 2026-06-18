# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

use Croma

defmodule Testgear.Greeter do
  @moduledoc """
  A trivial module whose `greeting/0` is called from a controller action so that
  it can be replaced by a Mimic mock in tests (see `test/mimic_test.exs`).
  """

  defun greeting() :: v[String.t] do
    "Hello from the real Greeter"
  end
end
