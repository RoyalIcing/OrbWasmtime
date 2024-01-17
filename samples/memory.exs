wasm_module_memory = fn min_size ->
  """
  (module $example
    (memory #{min_size})
    (func (export "answer") (result i32)
      (i32.const 42)
    )
    (func (export "answer_loop") (result i32)
      (local $i i32)
      (loop $increment
        (local.get $i)
        (i32.add (i32.const 1))
        (local.tee $i)
        (i32.eq 42)
        (br_if $increment)
      )
      (local.get $i)
    )
  )
  """
end

wasm_1 = wasm_module_memory.(1)
wasm_100 = wasm_module_memory.(100)
wasm_10_000 = wasm_module_memory.(10_000)

alias OrbWasmtime.Wasm

Benchee.run(
  %{
    "(memory 1)" => fn -> Wasm.call(wasm_1, :answer) end,
    "(memory 1) loop" => fn -> Wasm.call(wasm_1, :answer_loop) end,
    "(memory 1) x 2" => fn -> Wasm.call(wasm_1, :answer); Wasm.call(wasm_1, :answer) end,
    "(memory 100)" => fn -> Wasm.call(wasm_100, :answer) end,
    "(memory 100) x 2" => fn -> Wasm.call(wasm_100, :answer); Wasm.call(wasm_100, :answer) end,
    "(memory 10,000)" => fn -> Wasm.call(wasm_10_000, :answer) end,
    "(memory 10,000) x 2" => fn -> Wasm.call(wasm_10_000, :answer); Wasm.call(wasm_10_000, :answer) end,
  },
  memory_time: 2
)
