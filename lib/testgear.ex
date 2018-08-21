# Copyright(c) 2015-2018 ACCESS CO., LTD. All rights reserved.

use Croma

defmodule Testgear do
  use Antikythera.GearApplication
  alias Antikythera.{ExecutorPool, Conn, Request}

  defun children() :: [Supervisor.Spec.spec] do
    [
      # gear-specific workers/supervisors
    ]
  end

  defun executor_pool_for_web_request(%Conn{request: %Request{path_info: path_info}}) :: ExecutorPool.Id.t do
    case path_info do
      ["blackbox_test_for_nonexisting_tenant"] -> {:tenant, "nonexisting_tenant_id"}
      _                                        -> {:gear, :testgear}
    end
  end
end
