defmodule OrbWasmtime.Instance.IntTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Instance

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
end
