defmodule CozyKV.Type do
  @moduledoc false

  # WARNING:
  # This module uses many throws, but this is not an issue.
  # Because values are not thrown outside this module, it's a controlled usage.

  alias CozyKV.ValidationError

  @available_types [
    :any,
    nil,
    :atom,
    :boolean,
    :string,
    :integer,
    :pos_integer,
    :non_neg_integer,
    :float,
    :tuple,
    "{:tuple, subtypes}",
    :list,
    "{:list, subtype}",
    :keyword_list,
    "{:keyword_list, spec}",
    :non_empty_keyword_list,
    "{:non_empty_keyword_list, spec}",
    :map,
    "{:map, key_type, value_type}",
    "{:map, spec}",
    "{:struct, struct_name}",
    :timeout,
    :pid,
    :reference,
    :mfa,
    "{:fun, arity}",
    :mod_args,
    "{:value_in, values}",
    "{:type_in, subtyes}",
    "{:custom, mod, fun}"
  ]

  @available_types_block Enum.map_join(@available_types, ", ", fn
                           type when is_atom(type) -> inspect(type)
                           type -> type
                         end)

  @basic_types Enum.filter(@available_types, &is_atom(&1))

  def validate_type(_init_type, type, _metadata) when type in @basic_types do
    {:ok, type}
  end

  def validate_type(init_type, {:tuple, subtypes} = type, metadata) when is_list(subtypes) do
    for subtype <- subtypes do
      if match?({:error, _}, validate_type(init_type, subtype, metadata)),
        do: throw(:invalid_value)
    end

    {:ok, type}
  catch
    :invalid_value ->
      error_tuple({:invalid_value, init_type: init_type, type: type}, metadata)
  end

  def validate_type(init_type, {:list, subtype} = type, metadata) do
    if match?({:error, _}, validate_type(init_type, subtype, metadata)), do: throw(:invalid_value)
    {:ok, type}
  catch
    :invalid_value ->
      error_tuple({:invalid_value, init_type: init_type, type: type}, metadata)
  end

  # keys should be validated by Spec module, but I don't want a cross-dependency
  # between the Spec module and current module.
  def validate_type(_init_type, {:keyword_list, _spec} = type, _metadata) do
    {:ok, type}
  end

  # the comment of {:keyword_list, spec} applies here.
  def validate_type(_init_type, {:non_empty_keyword_list, _spec} = type, _metadata) do
    {:ok, type}
  end

  def validate_type(init_type, {:map, key_type, value_type} = type, metadata) do
    if match?({:error, _}, validate_type(init_type, key_type, metadata)),
      do: throw(:invalid_value)

    if match?({:error, _}, validate_type(init_type, value_type, metadata)),
      do: throw(:invalid_value)

    {:ok, type}
  catch
    :invalid_value ->
      error_tuple({:invalid_value, init_type: init_type, type: type}, metadata)
  end

  # the comment of {:keyword_list, spec} applies here.
  def validate_type(_init_type, {:map, _spec} = type, _metadata) do
    {:ok, type}
  end

  def validate_type(_init_type, {:struct, struct_name} = type, _metadata)
      when is_atom(struct_name) do
    {:ok, type}
  end

  def validate_type(_init_type, {:fun, arity} = type, _metadata)
      when is_integer(arity) and arity >= 0 do
    {:ok, type}
  end

  # `values` can be any enumerable. For now, there's no easy and fast way to validate it.
  def validate_type(_init_type, {:value_in, _values} = type, _metadata) do
    {:ok, type}
  end

  def validate_type(init_type, {:type_in, subtypes} = type, metadata) when is_list(subtypes) do
    for subtype <- subtypes do
      if match?({:error, _}, validate_type(init_type, subtype, metadata)),
        do: throw(:invalid_value)
    end

    {:ok, type}
  catch
    :invalid_value ->
      error_tuple({:invalid_value, init_type: init_type, type: type}, metadata)
  end

  def validate_type(_init_type, {:custom, mod, fun} = type, _metadata)
      when is_atom(mod) and is_atom(fun) do
    {:ok, type}
  end

  def validate_type(init_type, type, metadata) do
    error_tuple({:invalid_value, init_type: init_type, type: type}, metadata)
  end

  def available_types_block(), do: @available_types_block

  defp error_tuple({kind, detail} = type, metadata) when is_tuple(type) and is_list(metadata) do
    [init_type: init_type, type: type] = detail

    key = Keyword.fetch!(metadata, :key)
    detail = [key: key, type: init_type, value: type]

    attrs =
      metadata
      |> Keyword.take([:path])
      |> Keyword.put(:type, {kind, detail})

    {:error, struct(ValidationError, attrs)}
  end
end
