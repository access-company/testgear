# Copyright(c) 2015-2024 ACCESS CO., LTD. All rights reserved.

use Croma

defmodule Testgear.Controller.ParamsValidation do
  use Antikythera.Controller

  defmodule PathMatches do
    use Antikythera.ParamStringStruct, fields: [
      foo: Croma.PosInteger
    ]
  end

  defmodule QueryParams do
    use Antikythera.ParamStringStruct, fields: [
      foo: Croma.TypeGen.nilable(Croma.PosInteger)
    ]
  end

  defmodule StructBody do
    use Antikythera.BodyJsonStruct, fields: [
      foo: Croma.PosInteger
    ]
  end

  defmodule ListBody do
    use Antikythera.BodyJsonList, elem_module: Croma.PosInteger
  end

  defmodule MapBody do
    use Antikythera.BodyJsonMap, value_module: Croma.PosInteger
  end

  defmodule Headers do
    use Antikythera.ParamStringStruct, fields: [
      "x-foo": Croma.PosInteger
    ]
  end

  defmodule Cookies do
    use Antikythera.ParamStringStruct, fields: [
      foo: Croma.PosInteger
    ]
  end

  plug Antikythera.Plug.ParamsValidator, :validate, [
    path_matches: PathMatches,
    query_params: QueryParams,
    body: StructBody,
    headers: Headers,
    cookies: Cookies
  ], only: [:validate_params]
  plug Antikythera.Plug.ParamsValidator, :validate, [body: ListBody], only: [:validate_list_body]
  plug Antikythera.Plug.ParamsValidator, :validate, [body: MapBody], only: [:validate_map_body]

  def validate_params(%{assigns: %{validated: validated}} = conn) do
    Conn.json(conn, 200, %{
      path_matches: validated.path_matches.foo,
      query_params: validated.query_params.foo,
      body: validated.body.foo,
      headers: validated.headers."x-foo",
      cookies: validated.cookies.foo
    })
  end

  def validate_list_body(%{assigns: %{validated: validated}} = conn) do
    Conn.json(conn, 200, %{
      body: validated.body
    })
  end

  def validate_map_body(%{assigns: %{validated: validated}} = conn) do
    Conn.json(conn, 200, %{
      body: validated.body
    })
  end
end
