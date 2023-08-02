defmodule OrbWasmtime.Instance.ImportCallerTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Instance

  test "can read and write strings" do
    inst =
      Instance.run(wat(), [
        {:test, :write_abc,
         fn caller, memory_offset ->
            len = Instance.Caller.write_string_nul_terminated(caller, memory_offset, "abc")
            assert len === 4
            len
         end},
        {:test, :strlen,
         fn caller, memory_offset ->
           s = Instance.Caller.read_string_nul_terminated(caller, memory_offset)
           assert s === "hello"
           byte_size(s)
         end}
      ])

    f = Instance.capture(inst, :test, 0)

    assert f.() === nil
  end

  defp wat() do
    """
    (module
      (import "test" "write_abc" (func $write_abc (param i32) (result i32)))
      (import "test" "strlen" (func $strlen (param i32) (result i32)))
      (memory (export "memory") 2)
      (data (i32.const 0x100) "hello")
      (func $assert! (param $condition i32)
        (if (local.get $condition)
          (then nop)
          (else unreachable)
        )
      )
      (func (export "test")
        (call $strlen (i32.const 0x100))
        (call $assert! (i32.eq (i32.const 5)))

        (call $write_abc (i32.const 0x200))
        drop
        (call $assert! (i32.eq (i32.load8_u (i32.const 0x200)) (i32.const #{?a})))
      )
    )
    """
  end
end
