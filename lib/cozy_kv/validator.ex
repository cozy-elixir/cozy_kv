defmodule CozyKV.Validator do
  @moduledoc false

  # WARNING:
  # This module uses many throws, but this is not an issue.
  # Because values are not thrown outside this module, it's a controlled usage.

  alias __MODULE__.KV
  alias CozyKV.ValidationError

  def run(spec, data) do
    {:ok, do_run(spec, data, [], true)}
  catch
    exception when is_exception(exception) -> {:error, exception}
  end

  # * path is for recording the level within the data.
  # * initial_run? is a flag for entering new level of nested data.

  defp do_run([] = initial_spec, data, path, initial_run?) do
    # 1. check unknown keys
    if initial_run? do
      known_keys = KV.keys(initial_spec)
      unknown_keys = KV.keys(data) -- known_keys

      if unknown_keys != [] do
        throw_error({:unknown_keys, known_keys: known_keys, unknown_keys: unknown_keys},
          path: path
        )
      end
    end

    data
  end

  # credo:disable-for-next-line
  defp do_run([spec | rest] = initial_spec, data, path, initial_run?) do
    {key, key_spec} = spec

    data_has_key? = KV.has_key?(data, key)

    # 1. check unknown keys
    if initial_run? do
      known_keys = KV.keys(initial_spec)
      unknown_keys = KV.keys(data) -- known_keys

      if unknown_keys != [] do
        throw_error({:unknown_keys, known_keys: known_keys, unknown_keys: unknown_keys},
          path: path
        )
      end
    end

    # 2. warn deprecated key
    if message = data_has_key? && Keyword.get(key_spec, :deprecated) do
      message_base =
        if path == [],
          do: inspect(key),
          else: "#{inspect(key)} under #{inspect(path)}"

      IO.warn("#{message_base} is deprecated. " <> message)
    end

    # 3. check required key
    if !data_has_key? && Keyword.get(key_spec, :required, false) do
      throw_error({:missing_key, received_keys: KV.keys(data)},
        path: path ++ [path_item(data, key)]
      )
    end

    # 4. put default value
    data =
      if !data_has_key? && Keyword.has_key?(key_spec, :default),
        do: KV.put(data, key, key_spec[:default]),
        else: data

    # 5. validate the type of value
    new_data_has_key? = KV.has_key?(data, key)

    data =
      if new_data_has_key? do
        key_type = key_spec[:type]
        key_value = KV.get(data, key)
        key_value = validate_value(key_type, key_value, path: path ++ [path_item(data, key)])
        KV.put(data, key, key_value)
      else
        data
      end

    do_run(rest, data, path, false)
  end

  def validate_value(:any, value, _metadata) do
    value
  end

  def validate_value(nil = type, value, metadata) do
    if is_nil(value),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:atom = type, value, metadata) do
    if is_atom(value),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:boolean = type, value, metadata) do
    if is_boolean(value),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:string = type, value, metadata) do
    if is_binary(value),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:integer = type, value, metadata) do
    if is_integer(value),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:pos_integer = type, value, metadata) do
    if is_integer(value) and value > 0,
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:non_neg_integer = type, value, metadata) do
    if is_integer(value) and value >= 0,
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:float = type, value, metadata) do
    if is_float(value),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:tuple = type, value, metadata) do
    if is_tuple(value),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:tuple, subtypes} = type, value, metadata) do
    if !is_tuple(value),
      do: throw_error({:invalid_value, type: type, value: value}, metadata)

    if !(tuple_size(value) == length(subtypes)),
      do: throw_error({:invalid_value, type: type, value: value}, metadata)

    Tuple.to_list(value)
    |> Enum.with_index()
    |> Enum.zip(subtypes)
    |> Enum.map(fn {{element, index}, subtype} ->
      metadata = Keyword.update!(metadata, :path, fn path -> path ++ [{:tuple, index}] end)
      validate_value(subtype, element, metadata)
    end)
    |> List.to_tuple()
  end

  def validate_value(:list = type, value, metadata) do
    if is_list(value),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:list, subtype} = type, value, metadata) do
    if !is_list(value), do: throw_error({:invalid_value, type: type, value: value}, metadata)

    value
    |> Enum.with_index()
    |> Enum.map(fn {element, index} ->
      metadata = Keyword.update!(metadata, :path, fn path -> path ++ [{:list, index}] end)
      validate_value(subtype, element, metadata)
    end)
  end

  def validate_value(:keyword_list = type, value, metadata) do
    if keyword_list?(value),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:keyword_list, spec} = type, value, metadata) do
    if !keyword_list?(value),
      do: throw_error({:invalid_value, type: type, value: value}, metadata)

    do_run(spec, value, metadata[:path], true)
  end

  def validate_value(:non_empty_keyword_list = type, value, metadata) do
    if keyword_list?(value) and value != [],
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:non_empty_keyword_list, spec} = type, value, metadata) do
    if !(keyword_list?(value) and value != []),
      do: throw_error({:invalid_value, type: type, value: value}, metadata)

    do_run(spec, value, metadata[:path], true)
  end

  def validate_value(:map, value, metadata) do
    validate_value({:map, :atom, :any}, value, metadata)
  end

  def validate_value({:map, spec} = type, value, metadata) do
    if !is_map(value),
      do: throw_error({:invalid_value, type: type, value: value}, metadata)

    do_run(spec, value, metadata[:path], true)
  end

  def validate_value({:map, key_type, value_type} = type, value, metadata) do
    if !is_map(value),
      do: throw_error({:invalid_value, type: type, value: value}, metadata)

    Enum.into(value, %{}, fn {k, v} ->
      k = validate_value(key_type, k, metadata)
      v = validate_value(value_type, v, metadata)
      {k, v}
    end)
  end

  def validate_value({:struct, struct_name} = type, value, metadata) do
    if match?(%^struct_name{}, value),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:timeout = type, value, metadata) do
    if value == :infinity or (is_integer(value) and value >= 0),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:pid = type, value, metadata) do
    if is_pid(value),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:reference = type, value, metadata) do
    if is_reference(value),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:mfa = type, value, metadata) do
    if match?({mod, fun, args} when is_atom(mod) and is_atom(fun) and is_list(args), value),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:fun, arity} = type, value, metadata) do
    if is_function(value) && fun_arity(value) == arity,
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:mod_args = type, value, metadata) do
    if match?({mod, _args} when is_atom(mod), value),
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:value_in, values} = type, value, metadata) do
    if value in values,
      do: value,
      else: throw_error({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:type_in, subtypes} = type, value, metadata) do
    for subtype <- subtypes do
      try do
        value = validate_value(subtype, value, metadata)
        throw({:ok, value})
      catch
        {:ok, value} -> throw({:ok, value})
        exception when is_exception(exception) -> :next
      end
    end

    throw_error({:invalid_value, type: type, value: value}, metadata)
  catch
    {:ok, value} -> value
    other -> throw(other)
  end

  def validate_value({:custom, mod, fun} = type, value, metadata) do
    case apply(mod, fun, [type, value, metadata]) do
      {:ok, value} ->
        value

      {:error, exception} when is_exception(exception) ->
        throw(exception)

      other ->
        raise "custom validation function #{inspect(mod)}.#{fun}/3 " <>
                "must return {:ok, value} or {:error, exception}, got: #{inspect(other)}"
    end
  end

  defp path_item(data, key) when is_list(data) do
    {{:kv, :list}, key}
  end

  defp path_item(data, key) when is_map(data) do
    {{:kv, :map}, key}
  end

  defp keyword_list?(value) do
    is_list(value) and Enum.all?(value, &match?({key, _value} when is_atom(key), &1))
  end

  defp fun_arity(fun) when is_function(fun) do
    {:arity, arity} = :erlang.fun_info(fun, :arity)
    arity
  end

  defp throw_error({_kind, _detail} = type, metadata) when is_tuple(type) and is_list(metadata) do
    attrs =
      metadata
      |> Keyword.take([:path])
      |> Keyword.put(:type, type)

    throw(struct(ValidationError, attrs))
  end
end
