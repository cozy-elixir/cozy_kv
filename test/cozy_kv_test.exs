defmodule CozyKVTest do
  use ExUnit.Case
  doctest CozyKV

  test "greets the world" do
    assert CozyKV.hello() == :world
  end
end
