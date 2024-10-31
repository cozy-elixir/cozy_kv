defmodule CozyKV.Validator do
  @moduledoc false

  # WARNING:
  # This module uses many throws, but this is not an issue.
  # Because values are not thrown outside this module, it's a controlled usage.

  alias CozyKV.KV
  alias CozyKV.Value
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
          case Value.validate_value(key_type, key_value, path: path, key: key) do
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
end
