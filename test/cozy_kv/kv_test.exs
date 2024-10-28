defmodule CozyKV.KVTest do
  use ExUnit.Case

  alias CozyKV.KV

  setup do
    samples = %{
      list: %{
        atom_key: [a: 1, b: 2],
        string_key: [{"a", 1}, {"b", 2}],
        any_key: [{{:name, :a}, 1}, {{:name, :b}, 2}]
      },
      map: %{
        atom_key: %{a: 1, b: 2},
        string_key: %{"a" => 1, "b" => 2},
        any_key: %{{:name, :a} => 1, {:name, :b} => 2}
      }
    }

    {:ok, samples: samples}
  end

  test "has_key?/2 supports all forms of kv", %{samples: samples} do
    assert KV.has_key?(samples.list.atom_key, :a) == true
    assert KV.has_key?(samples.list.string_key, "a") == true
    assert KV.has_key?(samples.list.any_key, {:name, :a}) == true
    assert KV.has_key?(samples.list.atom_key, :c) == false
    assert KV.has_key?(samples.list.string_key, "c") == false
    assert KV.has_key?(samples.list.any_key, {:name, :c}) == false

    assert KV.has_key?(samples.map.atom_key, :a) == true
    assert KV.has_key?(samples.map.string_key, "a") == true
    assert KV.has_key?(samples.map.any_key, {:name, :a}) == true
    assert KV.has_key?(samples.list.atom_key, :c) == false
    assert KV.has_key?(samples.list.string_key, "c") == false
    assert KV.has_key?(samples.list.any_key, {:name, :c}) == false
  end

  test "keys/1 supports all forms of kv", %{samples: samples} do
    assert KV.keys(samples.list.atom_key) == [:a, :b]
    assert KV.keys(samples.list.string_key) == ["a", "b"]
    assert KV.keys(samples.list.any_key) == [{:name, :a}, {:name, :b}]

    assert KV.keys(samples.map.atom_key) -- [:a, :b] == []
    assert KV.keys(samples.map.string_key) -- ["a", "b"] == []
    assert KV.keys(samples.map.any_key) -- [{:name, :a}, {:name, :b}] == []
  end

  test "get/2 supports all forms of kv", %{samples: samples} do
    assert KV.get(samples.list.atom_key, :a) == 1
    assert KV.get(samples.list.string_key, "a") == 1
    assert KV.get(samples.list.any_key, {:name, :a}) == 1
    assert KV.get(samples.list.atom_key, :c) == nil
    assert KV.get(samples.list.string_key, "c") == nil
    assert KV.get(samples.list.any_key, {:name, :c}) == nil

    assert KV.get(samples.map.atom_key, :a) == 1
    assert KV.get(samples.map.string_key, "a") == 1
    assert KV.get(samples.map.any_key, {:name, :a}) == 1
    assert KV.get(samples.map.atom_key, :c) == nil
    assert KV.get(samples.map.string_key, "c") == nil
    assert KV.get(samples.map.any_key, {:name, :c}) == nil
  end

  test "get/3 supports all forms of kv", %{samples: samples} do
    assert KV.get(samples.list.atom_key, :a, :default) == 1
    assert KV.get(samples.list.string_key, "a", :default) == 1
    assert KV.get(samples.list.any_key, {:name, :a}, :default) == 1
    assert KV.get(samples.list.atom_key, :c, :default) == :default
    assert KV.get(samples.list.string_key, "c", :default) == :default
    assert KV.get(samples.list.any_key, {:name, :c}, :default) == :default

    assert KV.get(samples.map.atom_key, :a, :default) == 1
    assert KV.get(samples.map.string_key, "a", :default) == 1
    assert KV.get(samples.map.any_key, {:name, :a}, :default) == 1
    assert KV.get(samples.map.atom_key, :c, :default) == :default
    assert KV.get(samples.map.string_key, "c", :default) == :default
    assert KV.get(samples.map.any_key, {:name, :c}, :default) == :default
  end

  test "put/3 supports all forms of kv", %{samples: samples} do
    assert KV.put(samples.list.atom_key, :a, 3) == [a: 3, b: 2]
    assert KV.put(samples.list.string_key, "a", 3) == [{"a", 3}, {"b", 2}]
    assert KV.put(samples.list.any_key, {:name, :a}, 3) == [{{:name, :a}, 3}, {{:name, :b}, 2}]

    assert KV.put(samples.map.atom_key, :a, 3) == %{a: 3, b: 2}
    assert KV.put(samples.map.string_key, "a", 3) == %{"a" => 3, "b" => 2}
    assert KV.put(samples.map.any_key, {:name, :a}, 3) == %{{:name, :a} => 3, {:name, :b} => 2}
  end
end
