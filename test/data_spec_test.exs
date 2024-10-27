defmodule DataSpecTest do
  use ExUnit.Case
  doctest DataSpec

  test "greets the world" do
    assert DataSpec.hello() == :world
  end
end
