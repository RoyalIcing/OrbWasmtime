defmodule OrbWasmtime.Instance.IntTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Instance
  alias OrbWasmtime.Wasm

  test "passing 32-bit integers" do
    inst = Instance.run(wat())
    identity_i32 = Instance.capture(inst, :u32, :identity_i32, 1)

    assert identity_i32.(0x0000_0000) === 0x0000_0000
    assert identity_i32.(0x0000_0001) === 0x0000_0001
    assert identity_i32.(0x00AB_CDEF) === 0x00AB_CDEF
    assert identity_i32.(0x7FFF_FFFF) === 0x7FFF_FFFF
    assert identity_i32.(0x8FFF_FFFF) === 0x8FFF_FFFF
    assert identity_i32.(0x9FFF_FFFF) === 0x9FFF_FFFF
    assert identity_i32.(0xEFFF_FFFF) === 0xEFFF_FFFF
    assert identity_i32.(0xFFFF_FFFF) === 0xFFFF_FFFF
  end

  defp wat() do
    """
    (module
      (func $identity_i32 (export "identity_i32") (param $a i32) (result i32)
        (local.get $a)
      )
    )
    """
  end

  @mathI64 ~S"""
  (module $MathI64
    (func $math (export "math") (param $a i64) (param $b i64) (result i64)
      (local $denominator i64)
      (i64.sub (i64.add (i64.const 4) (local.get $a)) (local.get $b))
      (local.set $denominator)
      (i64.div_s (i64.mul (local.get $a) (local.get $b)) (local.get $denominator))
    )
  )
  """

  test "call with i64" do
    assert @mathI64 |> Wasm.call(:math, {:i64, 11}, {:i64, 7}) === 9
  end
end
