defmodule CozyKVTest do
  use ExUnit.Case
  doctest CozyKV

  import CozyKV, only: [validate_spec!: 1]

  describe "validate_spec!/1" do
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
end
