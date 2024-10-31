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

  @type key :: term()
  @type type :: term()
  @type value :: term()

  @type unknown_keys ::
          {:unknown_keys, key: key(), known_keys: [key()], unknown_keys: [key(), ...]}
  @type missing_key ::
          {:missing_key, key: key(), received_keys: [key()]}
  @type invalid_value ::
          {:invalid_value, key: key(), type: type(), value: value()}

  @type t :: %__MODULE__{
          path: [key()],
          type: unknown_keys() | missing_key() | invalid_value()
        }

  defexception [:message, type: nil, path: []]

  @impl true
  def message(%__MODULE__{type: type, path: path}), do: to_message(type, path)

  defp to_message(
         {:unknown_keys, key: key, known_keys: known_keys, unknown_keys: unknown_keys},
         path
       ) do
    "unknown keys #{inspect(unknown_keys)} is used for #{inspect(key)} key under the path #{inspect(path)})." <>
      "\n\n" <>
      "Known keys: #{inspect(known_keys)}"
  end

  defp to_message(
         {:missing_key, [key: key, received_keys: received_keys]},
         _path
       ) do
    "key #{inspect(key)} is required, " <>
      "but received keys #{inspect(received_keys)} don't include it."
  end

  defp to_message(
         {:invalid_value, [key: key, type: {:custom, CozyKV.Type, :validate_type}, value: value]},
         path
       ) do
    "invalid type #{inspect(value)} is used for #{inspect(key)} key under the path #{inspect(path)}." <>
      "\n\n" <>
      "Available types: #{CozyKV.Type.available_types_block()}"
  end

  defp to_message(
         {:invalid_value, [key: key, type: type, value: value]},
         path
       ) do
    "invalid value #{inspect(value)} is used for #{inspect(key)} key of type #{inspect(type)} under the path #{inspect(path)}."
  end
end
