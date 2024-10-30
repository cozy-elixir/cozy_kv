defmodule CozyKV do
  @moduledoc """
  Validates data containing key-value pairs.

  ## Features

    * Supports any type of key, not limited to atoms.
    * Provides errors with detailed metadata, which is useful to build custom error messages.

  ## Terminologies

    * spec - a list which describes the structure of data.
    * data - the data to be validated using a spec.

  ## Usage

  ```elixir
  # 1. create a raw spec
  spec = [
    name: [type: :string, required: true]
  ]

  # 2. validate the spec
  spec = CozyKV.validate_spec!(spec)

  # 3. validate a piece of data using above spec

  # 3.1 validate key-value pairs in list form.
  kv_list = [name: "zeke"]
  {:ok, [name: "zeke"]} = CozyKV.validate(spec, kv_list)

  # 3.2 validate key-value pairs in map form.
  kv_map = %{name: "zeke"}
  {:ok, %{name: "zeke"}} = CozyKV.validate(spec, kv_map)

  # 3.3 when validation fails, an error is returned
  kv_bad = []
  {:error, %CozyKV.ValidationError{path: _, type: _}} = CozyKV.validate(spec, kv_bad)
  ```

  ## Specs

  A valid spec is a list of two-element tuples.

  In each tuple, the first element is the key, the second element is the spec
  options of the value correspoding to the key.

  <!-- tabs-open -->

  ### atom key

  ```elixir
  [
    name: [
      type: :string,
      required: true
    ],
    # ...
  ]
  ```

  ### string key

  ```elixir
  [
    {"name", [
      type: :string,
      required: true
    ]},
    # ...
  ]
  ```

  ### arbitrary key

  ```elixir
  # allows to use arbitrary key in any type.
  [
    {%{}, [
      type: :string,
      required: true
    ]},
    # ...
  ]
  ```

  <!-- tabs-close -->

  ### Spec options

  ## Data

  A valid piece of data is a list of two-element tuples or a map.

  <!-- tabs-open -->

  ### list (atom key)

  ```elixir
  [
    name: "zeke",
    # ...
  ]
  ```

  ### list (string key)


  ```elixir
  [
    {"name", "zeke"},
    # ...
  ]
  ```

  ### list (arbitrary key)

  ```elixir
  [
    {%{}, "zeke"},
    # ...
  ]
  ```

  <!-- tabs-close -->

  <!-- tabs-open -->

  ### map (atom key)

  ```elixir
  %{
    name: "zeke",
    # ...
  }
  ```

  ### map (string key)

  ```elixir
  %{
    "name" => "zeke",
    # ...
  }
  ```

  ### map (arbitrary key)

  ```elixir
  %{
    %{} => "zeke",
    # ...
  }
  ```

  <!-- tabs-close -->

  ## Thanks

  This library is built on the wisdom in following code:

    * [nimble_options](https://hex.pm/packages/nimble_options)

  """

  alias CozyKV.Spec
  alias CozyKV.Validator
  alias CozyKV.ValidationError

  @type spec :: [{term(), term()}]
  @type data :: [{term(), term()}] | map()

  @doc """
  Validates a spec.
  """
  @spec validate_spec!(spec()) :: spec()
  def validate_spec!(spec) do
    if !spec?(spec), do: raise(ArgumentError, "invalid spec")

    Spec.validate!(spec)
  end

  @doc """
  Validates a key-value data.
  """
  @spec validate(spec(), data()) :: {:ok, data()} | {:error, ValidationError.t()}
  def validate(spec, data) do
    if !spec?(spec), do: raise(ArgumentError, "invalid spec")
    if !kv_pairs?(data), do: raise(ArgumentError, "invalid data")

    Validator.run(spec, data)
  end

  @doc """
  Bang version of `validate/2`.
  """
  @spec validate!(spec(), data()) :: data()
  def validate!(spec, data) do
    case validate(spec, data) do
      {:ok, data} -> data
      {:error, %ValidationError{} = exception} -> raise exception
    end
  end

  defp spec?([]), do: true

  defp spec?(list) when is_list(list) do
    Enum.all?(list, &match?({_, _}, &1))
  end

  defp spec?(_), do: false

  defp kv_pairs?(list) when is_list(list),
    do: Enum.all?(list, &match?({_, _}, &1))

  defp kv_pairs?(map) when is_map(map), do: true

  defp kv_pairs?(_), do: false
end
