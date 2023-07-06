defmodule OrbWasmtimeTest do
  use ExUnit.Case
  doctest OrbWasmtime

  test "greets the world" do
    assert OrbWasmtime.hello() == :world
  end
end
