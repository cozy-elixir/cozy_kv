defmodule CozyKV.Spec do
  @moduledoc false

  alias CozyKV.Type
  alias CozyKV.Validator
  alias CozyKV.ValidationError

  @base_spec [
    type:
      {:keyword_list,
       [
         type: [
           type: {:custom, Type, :validate_type, []},
           default: :any
         ],
         required: [
           type: :boolean,
           default: false
         ],
         default: [
           type: :any
         ]
       ]}
  ]

  def validate!(spec) when is_list(spec) do
    key_spec = base_spec()
    spec_of_spec = Enum.map(spec, fn {key, _} -> {key, key_spec} end)

    case Validator.run(spec_of_spec, spec) do
      {:ok, spec} ->
        spec

      {:error, %ValidationError{message: message, type: {:invalid_value, _}}}
      when is_binary(message) ->
        raise ArgumentError, "invalid spec. Reason: #{message}"
    end
  end

  defp base_spec, do: @base_spec
end
