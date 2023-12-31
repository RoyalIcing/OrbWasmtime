defmodule OrbWasmtime.Wat2WasmTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Wasm

  @tag :skip
  test "works" do
    wasm = Wasm.to_wasm(wat())
    assert is_binary(wasm)
  end

  @wat ~S"""
    (module $LabSwatch
    (import "math" "powf32" (func $powf32 (param f32 f32) (result f32)))
    (import "format" "f32" (func $format_f32 (param f32 i32) (result i32)))
    (memory (export "memory") 2)
    (global $bump_offset (mut i32) (i32.const 65536))
    (global $bump_mark (mut i32) (i32.const 0))
    (global $bump_write_level (mut i32) (i32.const 0))
    (data (i32.const 255) "<linearGradient id=\"")
    (data (i32.const 276) "lab-l-gradient")
    (data (i32.const 291) "\" gradientTransform=\"scale(1.414) rotate(45)\">\n")
    (data (i32.const 340) "</linearGradient>\n")
    (data (i32.const 360) "<stop offset=\"")
    (data (i32.const 375) "\" stop-color=\"")
    (data (i32.const 390) "rgba(")
    (data (i32.const 396) ",")
    (data (i32.const 398) ",1)")
    (data (i32.const 402) "\" />\n")
    (func $bump_alloc (param $size i32) (result i32)
      (global.get $bump_offset)
      (i32.add (global.get $bump_offset) (local.get $size))
      (global.set $bump_offset)
    )
    (func $memcpy (param $dest i32) (param $src i32) (param $byte_count i32)
      (local $i i32)
      (loop $EachByte
        (i32.eq (local.get $i) (local.get $byte_count))
        (if
          (then
            return
          )
        )
        (i32.store8 (i32.add (local.get $dest) (local.get $i)) (i32.load8_u (i32.add (local.get $src) (local.get $i))))
        (i32.add (local.get $i) (i32.const 1))
        (local.set $i)
        br $EachByte
      )
    )
    (func $memset (param $dest i32) (param $u8 i32) (param $byte_count i32)
      (local $i i32)
      (loop $EachByte
        (i32.eq (local.get $i) (local.get $byte_count))
        (if
          (then
            return
          )
        )
        (i32.store8 (i32.add (local.get $dest) (local.get $i)) (local.get $u8))
        (i32.add (local.get $i) (i32.const 1))
        (local.set $i)
        br $EachByte
      )
    )
    (func $streq (param $address_a i32) (param $address_b i32) (result i32)
      (local $i i32)
      (local $byte_a i32)
      (local $byte_b i32)
      (loop $EachByte (result i32)
        (i32.load8_u (i32.add (local.get $address_a) (local.get $i)))
        (local.set $byte_a)
        (i32.load8_u (i32.add (local.get $address_b) (local.get $i)))
        (local.set $byte_b)
        (i32.eqz (local.get $byte_a))
        (if
          (then
            (return (i32.eqz (local.get $byte_b)))
          )
        )
        (i32.eq (local.get $byte_a) (local.get $byte_b))
        (if
          (then
            (i32.add (local.get $i) (i32.const 1))
            (local.set $i)
            br $EachByte
          )
        )
        (return (i32.const 0))
      )
    )
    (func $strlen (param $string_ptr i32) (result i32)
      (local $count i32)
      (loop $EachChar
        (i32.load8_u (i32.add (local.get $string_ptr) (local.get $count)))
        (if
          (then
            (i32.add (local.get $count) (i32.const 1))
            (local.set $count)
            br $EachChar
          )
        )
      )
      (local.get $count)
    )
    (func $u32toa_count (param $value i32) (result i32)
      (local $digit_count i32)
      (local $digit i32)
      (loop $Digits
        (i32.add (local.get $digit_count) (i32.const 1))
        (local.set $digit_count)
        (i32.rem_u (local.get $value) (i32.const 10))
        (local.set $digit)
        (i32.div_u (local.get $value) (i32.const 10))
        (local.set $value)
        (i32.gt_u (local.get $value) (i32.const 0))
        br_if $Digits
      )
      (local.get $digit_count)
    )
    (func $u32toa (param $value i32) (param $end_offset i32) (result i32)
      (local $working_offset i32)
      (local $digit i32)
      (local.get $end_offset)
      (local.set $working_offset)
      (loop $Digits
        (i32.sub (local.get $working_offset) (i32.const 1))
        (local.set $working_offset)
        (i32.rem_u (local.get $value) (i32.const 10))
        (local.set $digit)
        (i32.div_u (local.get $value) (i32.const 10))
        (local.set $value)
        (i32.store8 (local.get $working_offset) (i32.add (i32.const 48) (local.get $digit)))
        (i32.gt_u (local.get $value) (i32.const 0))
        br_if $Digits
      )
      (local.get $working_offset)
    )
    (func $write_u32 (param $value i32) (param $str_ptr i32) (result i32)
      (local $working_offset i32)
      (local $last_offset i32)
      (local $digit i32)
      (i32.add (local.get $str_ptr) (call $u32toa_count (local.get $value)))
      (local.set $last_offset)
      (local.get $last_offset)
      (local.set $working_offset)
      (loop $Digits
        (i32.sub (local.get $working_offset) (i32.const 1))
        (local.set $working_offset)
        (i32.rem_u (local.get $value) (i32.const 10))
        (local.set $digit)
        (i32.div_u (local.get $value) (i32.const 10))
        (local.set $value)
        (i32.store8 (local.get $working_offset) (i32.add (i32.const 48) (local.get $digit)))
        (i32.gt_u (local.get $value) (i32.const 0))
        br_if $Digits
      )
      (local.get $last_offset)
    )
    (func $bump_write_start
      (i32.eqz (global.get $bump_write_level))
      (if
        (then
          (global.get $bump_offset)
          (global.set $bump_mark)
        )
      )
      (i32.add (global.get $bump_write_level) (i32.const 1))
      (global.set $bump_write_level)
    )
    (func $bump_write_done (result i32)
      (global.get $bump_write_level)
      (if
        (then
          nop
        )
        (else
          unreachable
        )
      )
      (i32.sub (global.get $bump_write_level) (i32.const 1))
      (global.set $bump_write_level)
      (i32.eqz (global.get $bump_write_level))
      (if
        (then
          (i32.store8 (global.get $bump_offset) (i32.const 0))
          (i32.add (global.get $bump_offset) (i32.const 1))
          (global.set $bump_offset)
        )
      )
      (global.get $bump_mark)
    )
    (func $bump_write_str (param $str_ptr i32)
      (local $len i32)
      (i32.eq (local.get $str_ptr) (global.get $bump_mark))
      (if
        (then
          return
        )
      )
      (call $strlen (local.get $str_ptr))
      (local.set $len)
      (call $memcpy (global.get $bump_offset) (local.get $str_ptr) (local.get $len))
      (i32.add (global.get $bump_offset) (local.get $len))
      (global.set $bump_offset)
    )
    (func $pow (param $base f32) (param $exponent f32) (result f32)
      (local $out f32)
      (local $index f32)
      (f32.const 1.0)
      (local.set $out)
      (f32.const 1.0)
      (local.set $index)
      (block $Outer
        (loop $Inner
          (f32.mul (local.get $out) (local.get $base))
          (local.set $out)
          (f32.add (local.get $index) (f32.const 1.0))
          (local.set $index)
          (f32.gt (local.get $index) (local.get $exponent))
          br_if $Outer
          br $Inner
        )
      )
      (local.get $out)
    )
    (func $lab_to_xyz_component (param $v f32) (result f32)
      (local $cubed f32)
      (call $pow (local.get $v) (f32.const 3.0))
      (local.set $cubed)
      (f32.gt (local.get $cubed) (f32.const 0.008856451679035631))
      (if (result f32)
        (then
          (local.get $cubed)
        )
        (else
          (f32.div (f32.sub (f32.mul (f32.const 116.0) (local.get $v)) (f32.const 16.0)) (f32.const 903.2962962962963))
        )
      )
    )
    (func $lab_to_xyz (param $l f32) (param $a f32) (param $b f32) (result f32 f32 f32)
      (local $fy f32)
      (local $fx f32)
      (local $fz f32)
      (f32.div (f32.add (local.get $l) (f32.const 16.0)) (f32.const 116.0))
      (local.set $fy)
      (f32.add (f32.div (local.get $a) (f32.const 500.0)) (local.get $fy))
      (local.set $fx)
      (f32.sub (local.get $fy) (f32.div (local.get $b) (f32.const 200.0)))
      (local.set $fz)
      (f32.mul (call $lab_to_xyz_component (local.get $fx)) (f32.const 0.96422))
      (f32.mul (call $lab_to_xyz_component (local.get $fy)) (f32.const 1.0))
      (f32.mul (call $lab_to_xyz_component (local.get $fz)) (f32.const 0.82521))
    )
    (func $xyz_to_lab_component (param $c f32) (result f32)
      (f32.gt (local.get $c) (f32.const 0.008856451679035631))
      (if (result f32)
        (then
          (call $powf32 (local.get $c) (f32.div (f32.const 1.0) (f32.const 3.0)))
        )
        (else
          (f32.div (f32.add (f32.mul (f32.const 903.2962962962963) (local.get $c)) (f32.const 16.0)) (f32.const 116.0))
        )
      )
    )
    (func $xyz_to_lab (param $x f32) (param $y f32) (param $z f32) (result f32 f32 f32)
      (local $f0 f32)
      (local $f1 f32)
      (local $f2 f32)
      (call $xyz_to_lab_component (f32.div (local.get $x) (f32.const 0.96422)))
      (local.set $f0)
      (call $xyz_to_lab_component (f32.div (local.get $y) (f32.const 1.0)))
      (local.set $f1)
      (call $xyz_to_lab_component (f32.div (local.get $z) (f32.const 0.82521)))
      (local.set $f2)
      (f32.sub (f32.mul (f32.const 116.0) (local.get $f1)) (f32.const 16.0))
      (f32.mul (f32.const 500.0) (f32.sub (local.get $f0) (local.get $f1)))
      (f32.mul (f32.const 200.0) (f32.sub (local.get $f1) (local.get $f2)))
    )
    (func $linear_rgb_to_srgb (param $r f32) (param $g f32) (param $b f32) (result f32 f32 f32)
      (call $linear_rgb_to_srgb_component (local.get $r))
      (call $linear_rgb_to_srgb_component (local.get $g))
      (call $linear_rgb_to_srgb_component (local.get $b))
    )
    (func $linear_rgb_to_srgb_component (param $c f32) (result f32)
      (f32.gt (local.get $c) (f32.const 0.0031308))
      (if (result f32)
        (then
          (f32.sub (f32.mul (f32.const 1.055) (call $powf32 (local.get $c) (f32.div (f32.const 1.0) (f32.const 2.4)))) (f32.const 0.055))
        )
        (else
          (f32.mul (f32.const 12.92) (local.get $c))
        )
      )
    )
    (func $srgb_to_linear_rgb (param $r f32) (param $g f32) (param $b f32) (result f32 f32 f32)
      (call $srgb_to_linear_rgb_component (local.get $r))
      (call $srgb_to_linear_rgb_component (local.get $g))
      (call $srgb_to_linear_rgb_component (local.get $b))
    )
    (func $srgb_to_linear_rgb_component (param $c f32) (result f32)
      (f32.lt (local.get $c) (f32.const 0.04045))
      (if (result f32)
        (then
          (f32.div (local.get $c) (f32.const 12.92))
        )
        (else
          (call $powf32 (f32.div (f32.add (local.get $c) (f32.const 0.055)) (f32.const 1.055)) (f32.const 2.4))
        )
      )
    )
    (func $xyz_to_linear_rgb (param $x f32) (param $y f32) (param $z f32) (result f32 f32 f32)
      (f32.sub (f32.sub (f32.mul (local.get $x) (f32.const 3.1338561)) (f32.mul (local.get $y) (f32.const 1.6168667))) (f32.mul (f32.const 0.4906146) (local.get $z)))
      (f32.add (f32.add (f32.mul (local.get $x) (f32.const -0.9787684)) (f32.mul (local.get $y) (f32.const 1.9161415))) (f32.mul (f32.const 0.033454) (local.get $z)))
      (f32.add (f32.sub (f32.mul (local.get $x) (f32.const 0.0719453)) (f32.mul (local.get $y) (f32.const 0.2289914))) (f32.mul (f32.const 1.4052427) (local.get $z)))
    )
    (func $xyz_to_srgb (param $x f32) (param $y f32) (param $z f32) (result f32 f32 f32)
      (call $xyz_to_linear_rgb (local.get $x) (local.get $y) (local.get $z))
      (call $linear_rgb_to_srgb)
    )
    (func $linear_srgb_to_xyz (param $r f32) (param $g f32) (param $b f32) (result f32 f32 f32)
      (f32.add (f32.add (f32.mul (f32.const 0.4360747) (local.get $r)) (f32.mul (f32.const 0.3850649) (local.get $g))) (f32.mul (f32.const 0.1430804) (local.get $b)))
      (f32.add (f32.add (f32.mul (f32.const 0.2225045) (local.get $r)) (f32.mul (f32.const 0.7168786) (local.get $g))) (f32.mul (f32.const 0.0606169) (local.get $b)))
      (f32.add (f32.add (f32.mul (f32.const 0.0139322) (local.get $r)) (f32.mul (f32.const 0.0971045) (local.get $g))) (f32.mul (f32.const 0.7141733) (local.get $b)))
    )
    (func $srgb_to_xyz (param $r f32) (param $g f32) (param $b f32) (result f32 f32 f32)
      (call $srgb_to_linear_rgb (local.get $r) (local.get $g) (local.get $b))
      (call $linear_srgb_to_xyz)
    )
    (func $lab_to_srgb (param $l f32) (param $a f32) (param $b f32) (result f32 f32 f32)
      (call $lab_to_xyz (local.get $l) (local.get $a) (local.get $b))
      (call $xyz_to_srgb)
    )
    (func $srgb_to_lab (param $r f32) (param $g f32) (param $b f32) (result f32 f32 f32)
      (call $srgb_to_xyz (local.get $r) (local.get $g) (local.get $b))
      (call $xyz_to_lab)
    )
    (func $to_svg (export "to_svg") (result i32)
      (call $bump_write_start)
      (call $do_linear_gradient)
      drop
      (call $bump_write_done)
    )
    (func $do_linear_gradient (result i32)
      (local $i i32)
      (call $bump_write_start)
      (call $bump_write_str (i32.const 255))
      (call $bump_write_str (i32.const 276))
      (call $bump_write_str (i32.const 291))
      (loop $Stops
        (i32.add (local.get $i) (i32.const 1))
        (local.set $i)
        (i32.lt_s (local.get $i) (i32.const 20))
        br_if $Stops
      )
      (call $do_linear_gradient_stop (f32.const 0.0) (f32.const 0.0) (f32.const 0.0) (f32.const 0.0))
      drop
      (call $do_linear_gradient_stop (f32.const 1.0) (f32.const 1.0) (f32.const 1.0) (f32.const 1.0))
      drop
      (call $bump_write_str (i32.const 340))
      (call $bump_write_done)
    )
    (func $do_linear_gradient_stop (param $fraction f32) (param $r f32) (param $g f32) (param $b f32) (result i32)
      (call $bump_write_start)
      (call $bump_write_str (i32.const 360))
      (i32.add (call $format_f32 (f32.mul (local.get $fraction) (f32.const 100.0)) (global.get $bump_offset)) (global.get $bump_offset))
      (global.set $bump_offset)
      (call $bump_write_str (i32.const 375))
      (call $bump_write_str (i32.const 390))
      (i32.add (call $format_f32 (f32.nearest (f32.mul (local.get $r) (f32.const 255.0))) (global.get $bump_offset)) (global.get $bump_offset))
      (global.set $bump_offset)
      (call $bump_write_str (i32.const 396))
      (i32.add (call $format_f32 (f32.nearest (f32.mul (local.get $g) (f32.const 255.0))) (global.get $bump_offset)) (global.get $bump_offset))
      (global.set $bump_offset)
      (call $bump_write_str (i32.const 396))
      (i32.add (call $format_f32 (f32.nearest (f32.mul (local.get $b) (f32.const 255.0))) (global.get $bump_offset)) (global.get $bump_offset))
      (global.set $bump_offset)
      (call $bump_write_str (i32.const 398))
      (call $bump_write_str (i32.const 402))
      (call $bump_write_done)
    )
  )
  """

  def wat(), do: @wat
end
