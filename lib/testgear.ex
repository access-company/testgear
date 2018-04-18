# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

use Croma

defmodule Testgear do
  use SolomonLib.GearApplication
  alias SolomonLib.{ExecutorPool, Conn}

  defun children() :: [Supervisor.Spec.spec] do
    [
      # gear-specific workers/supervisors
    ]
  end

  defun executor_pool_for_web_request(_conn :: Conn.t) :: ExecutorPool.Id.t do
    {:gear, :testgear}
  end
end
