defmodule CozyKV.Validator do
  @moduledoc false

  # WARNING:
  # This module uses many throws, but this is not an issue.
  # Because values are not thrown outside this module, it's a controlled usage.

  alias CozyKV.KV
  alias __MODULE__.KV
  alias CozyKV.ValidationError

  def run(spec, data) do
    {:ok, do_run(spec, data, [], true)}
  catch
    {:error, %ValidationError{}} = result -> result
  end

  # * path is for recording the level within the data.
  # * initial_run? is a flag for entering new level of nested data.

  defp do_run([] = initial_spec, data, path, initial_run?) do
    # 1. check unknown keys
    if initial_run? do
      known_keys = KV.keys(initial_spec)
      unknown_keys = KV.keys(data) -- known_keys

      if unknown_keys != [] do
        {parent_key, parent_path} = List.pop_at(path, -1)

        throw(
          {:error,
           %ValidationError{
             type:
               {:unknown_keys,
                key: parent_key, known_keys: known_keys, unknown_keys: unknown_keys},
             path: parent_path
           }}
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
        {parent_key, parent_path} = List.pop_at(path, -1)

        throw(
          {:error,
           %ValidationError{
             type:
               {:unknown_keys,
                key: parent_key, known_keys: known_keys, unknown_keys: unknown_keys},
             path: parent_path
           }}
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
      throw(
        {:error,
         %ValidationError{
           type: {:missing_key, required_key: key, received_keys: KV.keys(data)},
           path: path
         }}
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

        # 5.1 validate the outline shape of value
        key_value =
          case validate_value(key_type, key_value, path: path, key: key) do
            {:ok, key_value} ->
              key_value

            {:error, %ValidationError{}} = result ->
              throw(result)
          end

        # 5.2 validate the accurate shape of value
        key_value =
          case key_type do
            {t, spec} when t in [:keyword_list, :non_empty_keyword_list, :map] ->
              do_run(spec, key_value, path ++ [key], true)

            _ ->
              key_value
          end

        KV.put(data, key, key_value)
      else
        data
      end

    do_run(rest, data, path, false)
  end

  def validate_value(:any, value, _metadata) do
    {:ok, value}
  end

  def validate_value(nil = type, value, metadata) do
    if is_nil(value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:atom = type, value, metadata) do
    if is_atom(value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:boolean = type, value, metadata) do
    if is_boolean(value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:string = type, value, metadata) do
    if is_binary(value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:integer = type, value, metadata) do
    if is_integer(value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:pos_integer = type, value, metadata) do
    if is_integer(value) and value > 0,
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:non_neg_integer = type, value, metadata) do
    if is_integer(value) and value >= 0,
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:float = type, value, metadata) do
    if is_float(value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:tuple = type, value, metadata) do
    if is_tuple(value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:tuple, subtypes} = type, value, metadata) do
    if !is_tuple(value), do: throw(:invalid_value)
    if !(tuple_size(value) == length(subtypes)), do: throw(:invalid_value)

    for {t, v} <- Enum.zip(subtypes, Tuple.to_list(value)) do
      if match?({:error, _}, validate_value(t, v, metadata)),
        do: throw(:invalid_value)
    end

    {:ok, value}
  catch
    :invalid_value ->
      error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:list, value, metadata) do
    validate_value({:list, :any}, value, metadata)
  end

  def validate_value({:list, subtype} = type, value, metadata) do
    if !is_list(value), do: throw(:invalid_value)

    for v <- value do
      if match?({:error, _}, validate_value(subtype, v, metadata)),
        do: throw(:invalid_value)
    end

    {:ok, value}
  catch
    :invalid_value ->
      error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:keyword_list = type, value, metadata) do
    if keyword_list?(value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:keyword_list, _spec} = type, value, metadata) do
    if keyword_list?(value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:non_empty_keyword_list = type, value, metadata) do
    if keyword_list?(value) and value != [],
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:non_empty_keyword_list, _spec} = type, value, metadata) do
    if keyword_list?(value) and value != [],
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:map, value, metadata) do
    validate_value({:map, :atom, :any}, value, metadata)
  end

  def validate_value({:map, key_type, value_type} = type, value, metadata) do
    if !is_map(value), do: throw(:invalid_value)

    for {k, v} <- value do
      if match?({:error, _}, validate_value(key_type, k, metadata)),
        do: throw(:invalid_value)

      if match?({:error, _}, validate_value(value_type, v, metadata)),
        do: throw(:invalid_value)
    end

    {:ok, value}
  catch
    :invalid_value ->
      error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:map, _spec} = type, value, metadata) do
    if is_map(value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:struct, struct_name} = type, value, metadata) do
    if match?(%^struct_name{}, value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:timeout = type, value, metadata) do
    if value == :infinity or (is_integer(value) and value >= 0),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:pid = type, value, metadata) do
    if is_pid(value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:reference = type, value, metadata) do
    if is_reference(value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:mfa = type, value, metadata) do
    if match?({mod, fun, args} when is_atom(mod) and is_atom(fun) and is_list(args), value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:fun, arity} = type, value, metadata) do
    if is_function(value) && fun_arity(value) == arity,
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value(:mod_args = type, value, metadata) do
    if match?({mod, _args} when is_atom(mod), value),
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:value_in, values} = type, value, metadata) do
    if value in values,
      do: {:ok, value},
      else: error_tuple({:invalid_value, type: type, value: value}, metadata)
  end

  def validate_value({:type_in, subtypes} = type, value, metadata) do
    for t <- subtypes do
      if match?({:ok, _}, validate_value(t, value, metadata)),
        do: throw(:ok)
    end

    error_tuple({:invalid_value, type: type, value: value}, metadata)
  catch
    :ok -> {:ok, value}
  end

  def validate_value({:custom, mod, fun} = type, value, metadata) do
    case apply(mod, fun, [type, value, metadata]) do
      {:ok, value} ->
        {:ok, value}

      {:error, exception} when is_exception(exception) ->
        {:error, exception}

      other ->
        raise "custom validation function #{inspect(mod)}.#{fun}/3 " <>
                "must return {:ok, value} or {:error, exception}, got: #{inspect(other)}"
    end
  end

  defp keyword_list?(value) do
    is_list(value) and Enum.all?(value, &match?({key, _value} when is_atom(key), &1))
  end

  defp fun_arity(fun) when is_function(fun) do
    {:arity, arity} = :erlang.fun_info(fun, :arity)
    arity
  end

  defp error_tuple({kind, detail} = type, metadata) when is_tuple(type) and is_list(metadata) do
    key = Keyword.fetch!(metadata, :key)
    detail = Keyword.put(detail, :key, key)

    attrs =
      metadata
      |> Keyword.take([:path])
      |> Keyword.put(:type, {kind, detail})

    {:error, struct(ValidationError, attrs)}
  end
end
