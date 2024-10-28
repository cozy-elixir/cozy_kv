defmodule CozyKV.Type do
  @moduledoc false

  # WARNING:
  # This module uses many throws, but this is not an issue.
  # Because values are not thrown outside this module, it's a controlled usage.

  @basic_types [
    :any,
    :atom,
    nil,
    :boolean,
    :string,
    :integer,
    :pos_integer,
    :non_neg_integer,
    :float,
    :timeout,
    :pid,
    :reference,
    :mfa,
    :mod_args,
    :list,
    :keyword_list,
    :non_empty_keyword_list,
    :map
  ]

  defp available_types() do
    types =
      Enum.map(@basic_types, &inspect/1) ++
        [
          "{:list, subtype}",
          "{:keyword_list, keys_spec}",
          "{:non_empty_keyword_list, keys_spec}",
          "{:map, keys_spec}",
          "{:map, key_type, value_type}",
          "{:fun, arity}",
          "{:struct, struct_name}",
          "{:tuple, subtypes}",
          "{:in, choices}",
          "{:or, subtypes}",
          "{:custom, mod, fun, args}"
        ]

    Enum.join(types, ", ")
  end

  @doc false
  def validate_type(type) when type in @basic_types do
    {:ok, type}
  end

  def validate_type({:list, subtype} = type) do
    case validate_type(subtype) do
      {:ok, _} ->
        :pass

      {:error, reason} ->
        throw({:error, "invalid subtype given to {:list, subtype} type: #{reason}"})
    end

    {:ok, type}
  catch
    {:error, reason} -> {:error, reason}
  end

  def validate_type({:tuple, subtypes} = type) when is_list(subtypes) do
    for subtype <- subtypes do
      case validate_type(subtype) do
        {:ok, _} ->
          :pass

        {:error, reason} ->
          throw({:error, "invalid subtype given to {:tuple, subtypes} type: #{reason}"})
      end
    end

    {:ok, type}
  catch
    {:error, reason} -> {:error, reason}
  end

  # keys should be validated by Spec module, but I don't want a cross-dependency
  # between the Spec module and current module.
  def validate_type({:keyword_list, _keys_spec} = type) do
    {:ok, type}
  end

  # the comment of {:keyword_list, keys_spec} applies here.
  def validate_type({:non_empty_keyword_list, _keys_spec} = type) do
    {:ok, type}
  end

  # the comment of {:keyword_list, keys_spec} applies here.
  def validate_type({:map, _keys_spec} = type) do
    {:ok, type}
  end

  def validate_type({:map, key_type, value_type} = type) do
    case validate_type(key_type) do
      {:ok, _} ->
        :pass

      {:error, reason} ->
        throw({:error, "invalid key_type for {:map, key_type, value_type} type: #{reason}"})
    end

    case validate_type(value_type) do
      {:ok, _} ->
        :pass

      {:error, reason} ->
        throw({:error, "invalid value_type for {:map, key_type, value_type} type: #{reason}"})
    end

    {:ok, type}
  catch
    {:error, reason} -> {:error, reason}
  end

  def validate_type({:fun, arity} = value) when is_integer(arity) and arity >= 0 do
    {:ok, value}
  end

  def validate_type({:struct, struct_name}) when is_atom(struct_name) do
    {:ok, {:struct, struct_name}}
  end

  # `choices` can be any enumerable. For now, there's no easy and fast way to validate it.
  def validate_type({:in, _choices} = value) do
    {:ok, value}
  end

  def validate_type({:or, subtypes} = type) when is_list(subtypes) do
    for subtype <- subtypes do
      case validate_type(subtype) do
        {:ok, _} ->
          :pass

        {:error, reason} ->
          throw({:error, "invalid subtype given to {:or, subtypes} type: #{reason}"})
      end
    end

    {:ok, type}
  catch
    {:error, reason} -> {:error, reason}
  end

  def validate_type({:custom, mod, fun, args} = value)
      when is_atom(mod) and is_atom(fun) and is_list(args) do
    {:ok, value}
  end

  def validate_type(value) do
    {:error, "unknown type #{inspect(value)}.\n\nAvailable types: #{available_types()}"}
  end
end
