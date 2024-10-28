defmodule CozyKV do
  @moduledoc """
  Validates data containing key-value pairs.

  ## Terminologies

    * spec - a list which describes the structure of data.
    * data - the data to be validated using a spec.

  """

  alias CozyKV.Spec
  alias CozyKV.Validator
  alias CozyKV.ValidationError

  @type spec :: list()
  @type data :: [{term(), term()}] | %{term() => term()}

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
