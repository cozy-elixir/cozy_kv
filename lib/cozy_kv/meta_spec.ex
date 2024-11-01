defmodule CozyKV.MetaSpec do
  @moduledoc false

  alias CozyKV.Primitive

  @meta_spec [
    *: [
      type:
        {:keyword_list,
         [
           type: [
             type: {:custom, Primitive.Type, :validate_type},
             default: :any,
             doc: """
             The type of the value.
             """
           ],
           required: [
             type: :boolean,
             default: false,
             doc: """
             The flag value to indicate whether the key is required.
             """
           ],
           default: [
             type: :any,
             doc: """
             The default value of the key.
             This value will be validated according to the `type`. This means that
             you can't have, for example, `type: :integer` and use `default: "a string"`.
             """
           ],
           deprecated: [
             type: :string,
             doc: """
             The message to indicate that the key is deprecated. \
             The message will be displayed as a warning.
             """
           ],
           doc: [
             type: {:type_in, [:string, {:in, [false]}]},
             doc: "The documentation for the key."
           ]
         ]}
    ]
  ]

  def build(spec) when is_list(spec) do
    Enum.map(spec, fn {key, _} -> {key, @meta_spec[:*]} end)
  end
end
