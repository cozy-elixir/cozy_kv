defmodule CozyKV.Spec do
  @moduledoc false

  alias CozyKV.Type
  alias CozyKV.Validator

  @base_spec [
    type:
      {:keyword_list,
       [
         type: [
           type: {:custom, Type, :validate_type},
           default: :any,
           doc: """
           The type of the value.
           """
         ],
         required: [
           type: :boolean,
           default: false,
           doc: """
           Defines if the key is required.
           """
         ],
         default: [
           type: :any,
           doc: """
           The default value.\
           This value will be validated according to the `type`. This means that
           you can't have, for example, `type: :integer` and use `default: "a string"`.
           """
         ],
         deprecated: [
           type: :string,
           doc: """
           Defines a message to indicate that the key is deprecated. \
           The message will be displayed as a warning.
           """
         ],
         doc: [
           type: {:type_in, [:string, {:in, [false]}]},
           type_doc: "`t:String.t/0` or `false`",
           doc: "The documentation for the key."
         ]
       ]}
  ]

  def validate!(spec) when is_list(spec) do
    key_spec = base_spec()
    spec_of_spec = Enum.map(spec, fn {key, _} -> {key, key_spec} end)

    case Validator.run(spec_of_spec, spec) do
      {:ok, spec} ->
        spec

      {:error, exception} ->
        raise ArgumentError, "invalid spec. Reason: #{Exception.message(exception)}"
    end
  end

  defp base_spec, do: @base_spec
end
