defmodule OrbWasmtime.Instance.ImportTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Instance

  test "passing 32-bit integers" do
    pid = self()

    inst =
      Instance.run(wat(), [
        {:log, :int32,
         fn value ->
           Process.send(pid, {:logi32, value}, [])
           42
         end},
        {:log, :float32,
         fn value ->
           Process.send(pid, {:logf32, value}, [])
           12.5
         end},
        {:math, :powf32,
         fn a, b ->
           Float.pow(a, b)
         end},
        {:log, :ping,
         fn ->
           nil
         end}
      ])

    f = Instance.capture(inst, :test, 0)

    f.()
    assert_receive({:logi32, 1})
    assert_receive({:logi32, 42})
    assert_receive({:logf32, 1.5})
    assert_receive({:logf32, 12.5})
    assert_receive({:logf32, 8.0})
  end

  defp wat() do
    """
    (module
      (import "log" "int32" (func $logi32 (param i32) (result i32)))
      (import "log" "float32" (func $logf32 (param f32) (result f32)))
      (import "math" "powf32" (func $powf32 (param f32 f32) (result f32)))
      (import "log" "ping" (func $ping))
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

        (call $powf32 (f32.const 2.0) (f32.const 3.0))
        (call $logf32)
        drop

        (call $ping)
      )
    )
    """
  end
end
