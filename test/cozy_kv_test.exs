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
      invalid spec. Reason: unknown keys [:unknown] are used under the path [{{:kv, :list}, :name}]).

      Known keys: [:type, :required, :default, :deprecated, :doc]\
      """

      assert_raise ArgumentError, message, fn -> validate_spec!(bad_spec) end
    end

    test "raises ArgumentError when spec is using a bad type" do
      bad_spec = [name: [type: :bad]]

      message = """
      invalid spec. Reason: invalid value :bad is used for :type key under the path [{{:kv, :list}, :name}, {{:kv, :list}, :type}].

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
      invalid spec. Reason: invalid value :bad is used for :required key of type :boolean under the path [{{:kv, :list}, :name}, {{:kv, :list}, :required}].\
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

  describe "validate/2 supports validating these data structures - " do
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

  describe "validate/2 supports these types - " do
    test ":any" do
      spec = validate_spec!(k: [type: :any])
      assert {:ok, [k: "string"]} = validate(spec, k: "string")
      assert {:ok, [k: :atom]} = validate(spec, k: :atom)
    end

    test "nil" do
      spec = validate_spec!(k: [type: nil])
      assert {:ok, [k: nil]} = validate(spec, k: nil)
      assert {:error, _} = validate(spec, k: :bad)
    end

    test ":atom" do
      spec = validate_spec!(k: [type: :atom])
      assert {:ok, [k: :good]} = validate(spec, k: :good)
      assert {:error, _} = validate(spec, k: "bad")
    end

    test ":boolean" do
      spec = validate_spec!(k: [type: :boolean])
      assert {:ok, [k: true]} = validate(spec, k: true)
      assert {:ok, [k: false]} = validate(spec, k: false)
      assert {:error, _} = validate(spec, k: :bad)
    end

    test ":string" do
      spec = validate_spec!(k: [type: :string])
      assert {:ok, [k: "string"]} = validate(spec, k: "string")
      assert {:error, _} = validate(spec, k: :bad)
    end

    test ":integer" do
      spec = validate_spec!(k: [type: :integer])
      assert {:ok, [k: 1]} = validate(spec, k: 1)
      assert {:ok, [k: 0]} = validate(spec, k: 0)
      assert {:ok, [k: -1]} = validate(spec, k: -1)
      assert {:error, _} = validate(spec, k: :bad)
    end

    test ":pos_integer" do
      spec = validate_spec!(k: [type: :pos_integer])
      assert {:ok, [k: 1]} = validate(spec, k: 1)
      assert {:error, _} = validate(spec, k: 0)
      assert {:error, _} = validate(spec, k: -1)
      assert {:error, _} = validate(spec, k: :bad)
    end

    test ":non_neg_integer" do
      spec = validate_spec!(k: [type: :non_neg_integer])
      assert {:ok, [k: 1]} = validate(spec, k: 1)
      assert {:ok, [k: 0]} = validate(spec, k: 0)
      assert {:error, _} = validate(spec, k: -1)
      assert {:error, _} = validate(spec, k: :bad)
    end

    test ":float" do
      spec = validate_spec!(k: [type: :float])
      assert {:ok, [k: 1.0]} = validate(spec, k: 1.0)
      assert {:ok, [k: +0.0]} = validate(spec, k: 0.0)
      assert {:ok, [k: -1.0]} = validate(spec, k: -1.0)
      assert {:error, _} = validate(spec, k: 1)
      assert {:error, _} = validate(spec, k: :bad)
    end

    test ":tuple" do
      spec = validate_spec!(k: [type: :tuple])
      assert {:ok, [k: {"name", :age}]} = validate(spec, k: {"name", :age})
      assert {:error, _} = validate(spec, k: :bad)
    end

    test "{:tuple, subtypes} whose subtypes are simple subtypes" do
      spec = validate_spec!(k: [type: {:tuple, [:atom, :boolean, :string]}])
      assert {:ok, [k: {:atom, true, "string"}]} = validate(spec, k: {:atom, true, "string"})
      # bad size
      assert {:error, _} = validate(spec, k: {:atom, true})
      # bad type
      assert {:error, _} = validate(spec, k: {:atom, true, :atom})
    end

    test "{:tuple, subtypes} whose subtypes are composite subtypes" do
      spec =
        validate_spec!(
          k: [
            type:
              {:tuple,
               [
                 {:map,
                  [
                    name: [type: :string, required: true],
                    age: [type: :non_neg_integer, default: 18]
                  ]}
               ]}
          ]
        )

      assert {:ok, [k: {%{name: "zeke", age: 18}}]} =
               validate(spec, k: {%{name: "zeke"}})

      assert {:error, %{path: [{{:kv, :list}, :k}, {:tuple, 0}, {{:kv, :map}, :age}]}} =
               validate(spec, k: {%{name: "zeke", age: "18"}})
    end

    test ":list" do
      spec = validate_spec!(k: [type: :list])
      assert {:ok, [k: []]} = validate(spec, k: [])
      assert {:error, _} = validate(spec, k: :bad)
    end

    test "{:list, subtype} whose subtype is simple subtype" do
      spec = validate_spec!(k: [type: {:list, :string}])
      assert {:ok, [k: ["zeke"]]} = validate(spec, k: ["zeke"])
      assert {:error, %{path: [{{:kv, :list}, :k}]}} = validate(spec, k: :not_list)
      assert {:error, %{path: [{{:kv, :list}, :k}, {:list, 0}]}} = validate(spec, k: [:atom])
    end

    test "{:list, subtype} whose subtype is compsite subtype" do
      spec =
        validate_spec!(
          k: [
            type:
              {:list,
               {:map,
                [
                  name: [type: :string, required: true],
                  age: [type: :non_neg_integer, default: 18]
                ]}}
          ]
        )

      assert {:ok, [k: []]} = validate(spec, k: [])
      assert {:error, %{path: [{{:kv, :list}, :k}]}} = validate(spec, k: :bad)

      assert {:ok, [k: [%{name: "zeke", age: 18}]]} = validate(spec, k: [%{name: "zeke"}])
      assert {:error, %{path: [{{:kv, :list}, :k}, {:list, 0}]}} = validate(spec, k: [:bad])
    end

    test ":keyword_list" do
      spec = validate_spec!(k: [type: :keyword_list])
      assert {:ok, [k: []]} = validate(spec, k: [])
      assert {:ok, [k: [name: "zeke"]]} = validate(spec, k: [name: "zeke"])
      assert {:error, %{path: [{{:kv, :list}, :k}]}} = validate(spec, k: :bad)
    end

    test "{:keyword_list, spec}" do
      spec =
        validate_spec!(
          k: [
            type:
              {:keyword_list,
               [
                 name: [type: :string, required: true],
                 age: [type: :non_neg_integer, default: 18]
               ]}
          ]
        )

      assert {:ok, [k: [age: 18, name: "zeke"]]} =
               validate(spec, k: [name: "zeke"])

      assert {:error, %{path: [{{:kv, :list}, :k}]}} =
               validate(spec, k: :bad)

      assert {:error, %{path: [{{:kv, :list}, :k}, {{:kv, :list}, :name}]}} =
               validate(spec, k: [name: 1])
    end

    test ":non_empty_keyword_list" do
      spec = validate_spec!(k: [type: :non_empty_keyword_list])
      assert {:error, %{path: [{{:kv, :list}, :k}]}} = validate(spec, k: [])
      assert {:ok, [k: [name: "zeke"]]} = validate(spec, k: [name: "zeke"])
      assert {:error, %{path: [{{:kv, :list}, :k}]}} = validate(spec, k: :bad)
    end

    test "{:non_empty_keyword_list, spec}" do
      spec =
        validate_spec!(
          k: [
            type:
              {:non_empty_keyword_list,
               [
                 name: [type: :string, required: true],
                 age: [type: :non_neg_integer, default: 18]
               ]}
          ]
        )

      assert {:ok, [k: [age: 18, name: "zeke"]]} =
               validate(spec, k: [name: "zeke"])

      assert {:error, %{path: [{{:kv, :list}, :k}]}} =
               validate(spec, k: :bad)

      assert {:error, %{path: [{{:kv, :list}, :k}, {{:kv, :list}, :name}]}} =
               validate(spec, k: [name: 1])
    end

    test ":map" do
      spec = validate_spec!(k: [type: :map])
      assert {:ok, [k: %{}]} = validate(spec, k: %{})
      assert {:error, %{path: [{{:kv, :list}, :k}]}} = validate(spec, k: :bad)
    end

    test "{:map, spec}" do
      spec =
        validate_spec!(
          k: [
            type:
              {:map,
               [
                 name: [type: :string, required: true],
                 age: [type: :non_neg_integer, default: 18]
               ]}
          ]
        )

      assert {:ok, [k: %{name: "zeke", age: 18}]} = validate(spec, k: %{name: "zeke"})
      assert {:error, %{path: [{{:kv, :list}, :k}]}} = validate(spec, k: :bad)
    end

    test "{:type_in, subtypes}" do
      spec =
        validate_spec!(
          k: [
            type:
              {:type_in,
               [
                 :integer,
                 :string,
                 {:map,
                  [
                    name: [type: :string, required: true],
                    age: [type: :non_neg_integer, default: 18]
                  ]}
               ]}
          ]
        )

      assert {:ok, [k: 1]} = validate(spec, k: 1)
      assert {:ok, [k: "string"]} = validate(spec, k: "string")
      assert {:ok, [k: %{name: "zeke", age: 18}]} = validate(spec, k: %{name: "zeke"})
      assert {:error, %{path: [{{:kv, :list}, :k}]}} = validate(spec, k: :bad)
      assert {:error, %{path: [{{:kv, :map}, :k}]}} = validate(spec, %{k: :bad})
    end
  end
end
