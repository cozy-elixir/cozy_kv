defmodule CozyKVTest do
  use ExUnit.Case, async: true
  doctest CozyKV

  import CozyKV, only: [validate_spec!: 1, validate: 2]

  describe "validate_spec!/1" do
    test "raises ArgumentError when spec is using an invalid structure" do
      bad_spec = %{}
      message = "invalid spec. It should be a list of two-element tuples."
      assert_raise ArgumentError, message, fn -> validate_spec!(bad_spec) end
    end

    test "raises ArgumentError when spec is using unknown keys" do
      bad_spec = [name: [unknown: "unknown"]]

      message = """
      invalid spec. Reason: unknown keys [:unknown] is used for :name key under the path []).

      Known keys: [:type, :required, :default, :deprecated, :doc]\
      """

      assert_raise ArgumentError, message, fn -> validate_spec!(bad_spec) end
    end

    test "raises ArgumentError when spec is using a bad type" do
      bad_spec = [name: [type: :bad]]

      message = """
      invalid spec. Reason: invalid type :bad is used for :type key under the path [:name].

      Available types: :any, nil, :atom, :boolean, :string, :integer, \
      :pos_integer, :non_neg_integer, :float, :tuple, {:tuple, subtypes}, \
      :list, {:list, subtype}, :keyword_list, {:keyword_list, spec}, \
      :non_empty_keyword_list, {:non_empty_keyword_list, spec}, \
      :map, {:map, key_type, value_type}, {:map, spec}, \
      {:struct, struct_name}, :timeout, :pid, :reference, :mfa, {:fun, arity}, \
      :mod_args, {:value_in, values}, {:type_in, subtyes}, {:custom, mod, fun}\
      """

      assert_raise ArgumentError, message, fn -> validate_spec!(bad_spec) end
    end

    test "raises ArgumentError when spec is using a bad value" do
      bad_spec = [name: [type: :string, required: :bad]]

      message = """
      invalid spec. Reason: invalid value :bad is used for :required key of type :boolean under the path [:name].\
      """

      assert_raise ArgumentError, message, fn -> validate_spec!(bad_spec) end
    end

    test "validates empty spec" do
      spec = []
      assert validate_spec!(spec) == []
    end

    test "sets default options to spec" do
      spec = [name: []]
      validated_spec = validate_spec!(spec)
      assert Keyword.keys(validated_spec[:name]) -- [:type, :required] == []
      assert get_in(validated_spec, [:name, :type]) == :any
      assert get_in(validated_spec, [:name, :required]) == false
    end

    test "allows to use atom key" do
      spec = [name: [type: :string]]
      assert validate_spec!(spec)
    end

    test "allows to use string key" do
      spec = [{"name", [type: :string]}]
      assert validate_spec!(spec)
    end

    test "allows to use arbitrary key" do
      spec = [{%{}, [type: :string]}]
      assert validate_spec!(spec)
    end
  end

  describe "validate/2 supports validating" do
    setup do
      spec = [name: [type: :string]]
      {:ok, spec: spec}
    end

    test "a list of two-element tuples", %{spec: spec} do
      assert {:ok, [name: "zeke"]} = validate(spec, name: "zeke")
    end

    test "a map", %{spec: spec} do
      assert {:ok, %{name: "zeke"}} = validate(spec, %{name: "zeke"})
    end
  end

  describe "validate/2 raises ArgumentError when" do
    test "spec is using an invalid structure" do
      bad_spec = %{}
      message = "invalid spec. It should be a list of two-element tuples."
      assert_raise ArgumentError, message, fn -> validate(bad_spec, []) end
    end

    test "data is using an invalid structure" do
      bad_data = :bad_data
      message = "invalid data. It should be a list of two-element tuples or a map."
      assert_raise ArgumentError, message, fn -> validate([], bad_data) end
    end
  end
end
