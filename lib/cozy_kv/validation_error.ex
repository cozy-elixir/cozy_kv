defmodule CozyKV.ValidationError do
  @moduledoc """
  The error that is returned (or raised) when there is an issue in the
  validation process.

  ## Error messages

  By default, the error struct doesn't include message.

  If you want to turn an error into a human-readable message, you should
  use `Exception.message/1`.

  If you don't like the default error message, you are free to customize your
  own version using the information provided by the error struct.
  """

  alias CozyKV.Primitive

  @type key :: term()
  @type type :: term()
  @type value :: term()

  @type unknown_keys ::
          {:unknown_keys, known_keys: [key()], unknown_keys: [key(), ...]}
  @type missing_key ::
          {:missing_key, received_keys: [key()]}
  @type invalid_value ::
          {:invalid_value, type: type(), value: value()}

  @type t :: %__MODULE__{
          path: [key()],
          type: unknown_keys() | missing_key() | invalid_value()
        }

  defexception [:message, type: nil, path: []]

  @impl true
  def message(%__MODULE__{type: type, path: path}) do
    to_message(type, path)
  end

  defp to_message(
         {:unknown_keys, known_keys: known_keys, unknown_keys: unknown_keys},
         path
       ) do
    "unknown keys #{inspect(unknown_keys)} are used under the path #{inspect(path)})." <>
      "\n\n" <>
      "Known keys: #{inspect(known_keys)}"
  end

  defp to_message(
         {:missing_key, [received_keys: received_keys]},
         path
       ) do
    {{{:kv, _}, key}, rest_path} = List.pop_at(path, -1)

    "key #{inspect(key)} is required under the path #{inspect(rest_path)}" <>
      "but received keys #{inspect(received_keys)} don't include it."
  end

  defp to_message(
         {:invalid_value, [type: {:custom, Primitive.Type, :validate_type}, value: value]},
         path
       ) do
    {{{:kv, _}, key}, _rest_path} = List.pop_at(path, -1)

    "invalid value #{inspect(value)} is used for #{inspect(key)} key under the path #{inspect(path)}." <>
      "\n\n" <>
      "Available types: #{Primitive.Type.available_types_block()}"
  end

  defp to_message(
         {:invalid_value, [type: type, value: value]},
         path
       ) do
    {current_path, _rest_path} = List.pop_at(path, -1)
    "#{to_concret_message(current_path, type, value)} under the path #{inspect(path)}."
  end

  defp to_concret_message({:tuple, _index}, type, value),
    do:
      "invalid value #{inspect(value)} is used for the element of a tuple of type #{inspect(type)}"

  defp to_concret_message({:list, _index}, type, value),
    do:
      "invalid value #{inspect(value)} is used for the element of a tuple of type #{inspect(type)}"

  defp to_concret_message({{:kv, _}, key}, type, value),
    do: "invalid value #{inspect(value)} is used for #{inspect(key)} key of type #{inspect(type)}"
end
