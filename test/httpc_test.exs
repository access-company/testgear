# Copyright(c) 2015-2023 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.HttpcTest do
  use ExUnit.Case
  alias Antikythera.Httpc

  @base_url Antikythera.Test.Config.base_url()

  defp remove_extra_headers(res) do
    %Httpc.Response{res | headers: Map.drop(res.headers, ["date", "connection"])}
  end

  test "Httpc.request should respect :max_body option" do
    send_req = fn(len) ->
      Httpc.get(@base_url <> "/custom/static/path/test.html", %{}, [max_body: len])
    end

    {:ok, res1} = send_req.(nil)
    assert res1.status == 200
    len = res1.headers["content-length"] |> String.to_integer()
    {:ok, res2} = send_req.(len)
    assert remove_extra_headers(res2) == remove_extra_headers(res1)
    assert send_req.(len - 1)         == {:error, :response_too_large}
  end

  test "Httpc.request should properly concatenate :params" do
    [
      {"/json"    , []                       , %{}                        },
      {"/json?a=b", []                       , %{"a" => "b"}              },
      {"/json"    , [params: %{"あ" => "い"}], %{"あ" => "い"}            },
      {"/json?a=b", [params: %{"あ" => "い"}], %{"a" => "b", "あ" => "い"}},
    ] |> Enum.each(fn {path, opts, expected_query_params} ->
      qparams = Httpc.get!(@base_url <> path, %{}, opts).body |> Poison.decode!() |> get_in(["request", "query_params"])
      assert qparams == expected_query_params
    end)
  end
end
