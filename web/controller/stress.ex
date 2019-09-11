# Copyright(c) 2015-2019 ACCESS CO., LTD. All rights reserved.

defmodule Testgear.Controller.Stress do
  use Antikythera.Controller

  def pi(conn) do
    loop = parse_int(conn.request.path_matches.loop, 1)
    Conn.json(conn, 200, %{value: calc_pi(loop)})
  end

  def list(conn) do
    loop = parse_int(conn.request.path_matches.loop, 1)
    Conn.json(conn, 200, %{value: sum_list(loop)})
  end

  defp parse_int(str, default) do
    case Integer.parse(str) do
      {val, ""} -> val
      _         -> default
    end
  end

  def calc_pi(loop) do
    if Antikythera.Env.compile_env() == :prod do
      3.14
    else
      # Monte Carlo method
      cnt = Enum.count(1..loop, fn(_) ->
        x = :rand.uniform()
        y = :rand.uniform()
        :math.sqrt(x * x + y * y) < 1.0
      end)
      4 * cnt / loop
    end
  end

  def sum_list(loop) do
    if Antikythera.Env.compile_env() == :prod do
      0
    else
      # create many list and binary to trigger GC
      initial = Enum.to_list(1..loop)
      Enum.reduce(1..loop, initial, fn(_, list) ->
        list
        |> Enum.map(&(" " <> Integer.to_string(&1) <> " "))
        |> Enum.map(&String.to_integer(String.trim(&1)))
      end)
      |> Enum.sum()
    end
  end
end
