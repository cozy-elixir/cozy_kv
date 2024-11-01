defmodule CozyKV.Validator.KV do
  @moduledoc false

  def has_key?(term, key) when is_list(term),
    do: :lists.keymember(key, 1, term)

  def has_key?(term, key) when is_map(term),
    do: Map.has_key?(term, key)

  def keys(term) when is_list(term) do
    :lists.map(
      fn {key, _} -> key end,
      term
    )
  end

  def keys(term) when is_map(term),
    do: Map.keys(term)

  def get(term, key, default \\ nil)

  def get(term, key, default) when is_list(term) do
    case :lists.keyfind(key, 1, term) do
      {^key, value} -> value
      false -> default
    end
  end

  def get(term, key, default) when is_map(term),
    do: Map.get(term, key, default)

  def put(term, key, value) when is_list(term) do
    [{key, value} | delete(term, key)]
  end

  def put(term, key, value) when is_map(term) do
    Map.put(term, key, value)
  end

  # copied from https://github.com/elixir-lang/elixir/blob/78f63d08313677a680868685701ae79a2459dcc1/lib/elixir/lib/keyword.ex#L719C3-L728C36
  defp delete(list, key) when is_list(list) do
    case :lists.keymember(key, 1, list) do
      true -> delete_key(list, key)
      _ -> list
    end
  end

  defp delete_key([{key, _} | tail], key), do: delete_key(tail, key)
  defp delete_key([{_, _} = pair | tail], key), do: [pair | delete_key(tail, key)]
  defp delete_key([], _key), do: []
end
