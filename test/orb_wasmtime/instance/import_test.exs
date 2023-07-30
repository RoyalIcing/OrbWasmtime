defmodule OrbWasmtime.Instance.ImportTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Instance

  test "passing 32-bit integers" do
    pid = self()

    inst =
      Instance.run(wat(), [
        {:log, :int32,
         fn value ->
           Process.send(pid, {:received, value}, [])
           42
         end},
        {:log, :float32,
         fn value ->
           Process.send(pid, {:received, value}, [])
           12.5
         end}
      ])

    f = Instance.capture(inst, :test, 0)

    f.()
    assert_receive({:received, 1})
    assert_receive({:received, 42})
    assert_receive({:received, 1.5})
    assert_receive({:received, 12.5})
  end

  defp wat() do
    """
    (module
      (import "log" "int32" (func $logi32 (param i32) (result i32)))
      (import "log" "float32" (func $logf32 (param f32) (result f32)))
      (func (export "test")
        (local $i i32)
        (local $f f32)
        (call $logi32 (i32.const 1))
        (local.set $i)
        (call $logi32 (local.get $i))
        drop

        (call $logf32 (f32.const 1.5))
        (local.set $f)
        (call $logf32 (local.get $f))
        drop
      )
    )
    """
  end
end
