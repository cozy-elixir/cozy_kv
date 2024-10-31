defmodule CozyKV do
  @moduledoc """
  Validates data containing key-value pairs.

  ## Features

    * Supports any type of key, not limited to atoms.
    * Provides errors with detailed metadata, which is useful to build custom error messages.

  ## Terminologies

    * spec - a list which describes the structure of key-value pairs.
    * data - the key-value pairs to be validated using a spec.

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

  These options are supported:

  ### Types and Values

  > The left side of `-` is the type name, and the right side is the description
  > of the value corresponding to the type.

    * `:any` - Any value.

    * `nil` - `nil` itself.

    * `:atom` - An atom.

    * `:boolean` - A boolean.

    * `:string` - A string.

    * `:integer` - An integer.

    * `:pos_integer` - A positive integer.

    * `:non_neg_integer` - A non-negative integer.

    * `:float` - A float.

    * `:tuple` - A tuple.

    * `{:tuple, subtypes}` - A tuple as described by `subtypes`. The length of
      the expected tuple must match the length of `subtypes`. The type of each
      element in tuple must match the type at the same position of `subtypes`.
      For example, a valid value of `{:tuple, [:atom, :string, {:list, :integer}]}`
      can be `{:name, "zeke", [3, 2, 2]}`.

    * `:list` - A list.

    * `{:list, subtype}` - A list with elements of type `subtype`.

    * `:keyword_list` - A keyword list.

    * `{:keyword_list, spec}` - A keyword list with key-value pairs structured
      by `spec`.

    * `:non_empty_keyword_list` - A non-empty keyword list.

    * `{:non_empty_keyword_list, spec}` - A non-empty keyword list with key-value
      pairs structured by `spec`.

    * `:map` - A map with atom keys. It is a shortcut of `{:map, :atom, :any}`.

    * `{:map, key_type, value_type}` - A map with `key_type` keys and `value_type` values.

    * `{:map, spec}` - A map with key-value pairs structured by `spec`.

    * `{:struct, struct_name}` - A struct.

    * `:timeout` - A non-negative integer or the atom `:infinity`.

    * `:pid` - A PID.

    * `:reference` - A reference (see `t:reference/0`).

    * `:mfa` - A tuple in the format `{mod, fun, args}`.

    * `{:fun, arity}` - A function with a specific `arity`.

    * `:mod_args` - A tuple in the format `{mod, args}`. It is usually used
      for process initialization using `start_link` and similar.

    * `{:value_in, values}` - A value which is one of the values in `values`.
      `values` can be any enumerable value, such as a list or a `%Range{}`.

    * `{:type_in, subtypes}` - A value which matches one of the types in `subtypes`.
      `subtypes` is a list of types.

    * `{:custom, mod, fun}` - A custom type. The related value will be validated
      by `apply(mod, fun, [type, value, metadata])`.
      `type` is the `{:custom, mod, fun}` itself. `mod.fun(type, value, metadata)`
      must return `{:ok, value}` or `{:error, exception}`.

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
  # In general, you don't do this.
  # I just want to demonstrate what this package can do.
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
  # In general, you don't do this.
  # I just want to demonstrate what this package can do.
  %{
    %{} => "zeke",
    # ...
  }
  ```

  <!-- tabs-close -->

  ## Limitations

    * `validate_spec!/1` doesn't validate the inner spec of a nested spec.

  ## TODO

    * Generates doc automatically.

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
    ensure_structure_of_spec!(spec)
    Spec.validate!(spec)
  end

  @doc """
  Validates a key-value data.
  """
  @spec validate(spec(), data()) :: {:ok, data()} | {:error, ValidationError.t()}
  def validate(spec, data) do
    ensure_structure_of_spec!(spec)
    ensure_structure_of_data!(data)
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

  defp ensure_structure_of_spec!(spec) do
    if !spec?(spec),
      do: raise(ArgumentError, "invalid spec. It should be a list of two-element tuples.")
  end

  defp ensure_structure_of_data!(data) do
    if !kv_pairs?(data),
      do:
        raise(ArgumentError, "invalid data. It should be a list of two-element tuples or a map.")
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
