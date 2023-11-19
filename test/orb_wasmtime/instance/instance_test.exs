defmodule OrbWasmtime.Instance.InstanceTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Instance
  alias OrbWasmtime.Wasm

  test "run_instance with wasm" do
    wat_source = """
    (module $single_func
      (func (export "answer") (result i32)
       i32.const 42
      )
    )
    """

    wasm_source = wat_source |> Wasm.to_wasm()
    assert wasm_source =~ "\0asm"

    instance = Instance.run(wasm_source)
    assert Instance.call(instance, "answer") == 42
  end
end
