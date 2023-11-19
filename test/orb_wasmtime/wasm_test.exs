defmodule OrbWasmtime.Wasm.Test do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Wasm

  test "wasm_list_exports/1 single func" do
    wasm_source = """
    (module $single_func
      (func (export "answer") (result i32)
       i32.const 42
      )
    )
    """

    assert Wasm.list_exports({:wat, wasm_source}) == [{:func, "answer"}]
  end

  test "wasm_list_exports/1 two funcs" do
    wasm_source = """
    (module $two_funcs
      (func (export "answer") (result i32)
        i32.const 42
      )
      (memory (export "mem") 1)
      (func (export "get_pi") (result f32)
        f32.const 3.14
      )
      (func $internal (result f32)
        f32.const 99
      )
    )
    """

    assert Wasm.list_exports({:wat, wasm_source}) == [
             {:func, "answer"},
             {:memory, "mem"},
             {:func, "get_pi"}
           ]
  end

  test "call/2" do
    wasm_source = """
    (module $single_func
      (func (export "answer") (result i32)
       i32.const 42
      )
    )
    """

    assert Wasm.call(wasm_source, "answer") == 42
  end

  test "call/2 i64" do
    wasm_source = """
    (module $single_func
      (func (export "answer") (result i64)
       i64.const 42
      )
    )
    """

    assert Wasm.call(wasm_source, "answer") == 42
  end

  test "instance_call/2" do
    wasm_source = """
    (module $single_func
      (func (export "answer") (result i32)
       i32.const 42
      )
    )
    """

    instance = Wasm.run_instance(wasm_source)
    assert Wasm.instance_call(instance, "answer") == 42
  end

  test "instance_call/2 i64" do
    wasm_source = """
    (module $single_func
      (func (export "answer") (result i64)
       i64.const 42
      )
    )
    """

    instance = Wasm.run_instance(wasm_source)
    assert Wasm.instance_call(instance, "answer") == 42
  end

  test "run_instance with wasm" do
    wat_source = """
    (module $single_func
      (func (export "answer") (result i32)
       i32.const 42
      )
    )
    """

    wasm_source = wat_source |> Wasm.to_wasm()

    instance = Wasm.run_instance(wasm_source)
    assert Wasm.instance_call(instance, "answer") == 42
  end

  test "call/2 uninitialized local" do
    wasm_source = """
    (module $single_func
      (func (export "answer") (result i32)
        (local $a i32)
        local.get $a
      )
    )
    """

    assert Wasm.call(wasm_source, "answer") == 0
  end

  test "call/2 mutating a param" do
    wasm_source = """
    (module $single_func
      (func (export "answer") (param $a i32) (result i32)
        (i32.const 42)
        (local.set $a)
        (local.get $a)
      )
    )
    """

    assert Wasm.call(wasm_source, "answer", 17) === 42
  end

  test "call/4 adding two numbers" do
    wasm_source = """
    (module $add_func
      (func $add (param $a i32) (param $b i32) (result i32)
        (local.get $a)
        (local.get $b)
        (i32.add)
      )
      (export "add" (func $add))
    )
    """

    assert Wasm.call(wasm_source, "add", 7, 5) === 12
  end

  test "call/4 multiplying two i32s" do
    wasm_source = """
    (module $multiply_func
      (func $multiply (param $a i32) (param $b i32) (result i32)
        (local.get $a)
        (local.get $b)
        (i32.mul)
      )
      (export "multiply" (func $multiply))
    )
    """

    assert Wasm.call(wasm_source, "multiply", 7, 5) === 35
  end

  test "call/4 swapping two i32s" do
    wasm_source = """
    (module
      (func $swap (param $a i32) (param $b i32) (result i32 i32)
        (local.get $b)
        (local.get $a)
      )
      (export "swap" (func $swap))
    )
    """

    assert Wasm.call(wasm_source, "swap", 7, 5) === {5, 7}
  end

  test "call/4 multiplying two f32s" do
    wasm_source = """
    (module $multiply_func
      (func $multiply (param $a f32) (param $b f32) (result f32)
        (local.get $a)
        (local.get $b)
        (f32.mul)
      )
      (export "multiply" (func $multiply))
    )
    """

    assert Wasm.call(wasm_source, "multiply", 7.0, 5.0) === 35.0
  end

  test "call/4 swapping two f32s" do
    wasm_source = """
    (module
      (func $swap (param $a f32) (param $b f32) (result f32 f32)
        (local.get $b)
        (local.get $a)
      )
      (export "swap" (func $swap))
    )
    """

    assert Wasm.call(wasm_source, "swap", 7.0, 5.0) === {5.0, 7.0}
  end

  test "call/3 checking a number is within a range" do
    wasm_source = """
    (module $range_func
      (func $validate (param $num i32) (result i32)
        (local $lt i32)
        (local $gt i32)
        (i32.lt_s (local.get $num) (i32.const 1))
        (local.set $lt)
        (i32.gt_s (local.get $num) (i32.const 255))
        (local.set $gt)
        (i32.or (local.get $lt) (local.get $gt))
        (i32.eqz)
      )
      (export "validate" (func $validate))
    )
    """

    validate = &Wasm.call(wasm_source, "validate", &1)
    assert validate.(-1) === 0
    assert validate.(0) === 0
    assert validate.(1) === 1
    assert validate.(2) === 1
    assert validate.(10) === 1
    assert validate.(13) === 1
    assert validate.(255) === 1
    assert validate.(256) === 0
    assert validate.(257) === 0
    assert validate.(2000) === 0

    instance = Wasm.run_instance(wasm_source)
    # validate = Wasm.instance_get_func_i32(validate: 1)
    validate = &Wasm.instance_call(instance, "validate", &1)
    assert validate.(0) === 0
    assert validate.(1) === 1
    assert validate.(255) === 1
    assert validate.(256) === 0
  end

  test "wasm_string/2 spits out string" do
    wasm_source = """
    (module $string_start_end
      (import "env" "buffer" (memory 1))
      (data (i32.const 256) "Know the length of this string")
      (func (export "main") (result i32 i32)
        (i32.const 256) (i32.const 30)
      )
    )
    """

    assert Wasm.call(wasm_source, "main") == {256, 30}
    assert Wasm.call_string(wasm_source, "main") == "Know the length of this string"
  end

  test "wasm_string/2 spits out null-terminated string" do
    wasm_source = """
    (module $string_null_terminated
      (import "env" "buffer" (memory 1))
      (data (i32.const 256) "No need to know the length of this string")
      (func (export "main") (result i32)
        (i32.const 256)
      )
    )
    """

    assert Wasm.call(wasm_source, "main") == 256
    assert Wasm.call_string(wasm_source, "main") == "No need to know the length of this string"
  end

  test "wasm_string/2 spits out HTML strings" do
    wasm_source = """
    (module $string_html
      (import "env" "buffer" (memory 1))
      (global $doctype (mut i32) (i32.const 65536))
      (data (i32.const 65536) "<!doctype html>")
      (func (export "main") (result i32 i32)
        (get_global $doctype) (i32.const 15)
      )
    )
    """

    assert Wasm.call(wasm_source, "main") == {65536, 15}
    assert Wasm.call_string(wasm_source, "main") == "<!doctype html>"
  end

  test "wasm_string/2 looks up HTTP status" do
    wasm_source = ~s"""
    (module $string_html
      (import "env" "buffer" (memory 1))
      (data (i32.const #{200 * 24}) "OK\\00")
      (data (i32.const #{201 * 24}) "Created\\00")
      (data (i32.const #{204 * 24}) "No Content\\00")
      (data (i32.const #{205 * 24}) "Reset Content\\00")
      (data (i32.const #{301 * 24}) "Moved Permanently\\00")
      (data (i32.const #{302 * 24}) "Found\\00")
      (data (i32.const #{303 * 24}) "See Other\\00")
      (data (i32.const #{304 * 24}) "Not Modified\\00")
      (data (i32.const #{307 * 24}) "Temporary Redirect\\00")
      (data (i32.const #{400 * 24}) "Bad Request\\00")
      (data (i32.const #{401 * 24}) "Unauthorized\\00")
      (data (i32.const #{403 * 24}) "Forbidden\\00")
      (data (i32.const #{404 * 24}) "Not Found\\00")
      (data (i32.const #{405 * 24}) "Method Not Allowed\\00")
      (data (i32.const #{409 * 24}) "Conflict\\00")
      (data (i32.const #{412 * 24}) "Precondition Failed\\00")
      (data (i32.const #{413 * 24}) "Payload Too Large\\00")
      (data (i32.const #{422 * 24}) "Unprocessable Entity\\00")
      (data (i32.const #{429 * 24}) "Too Many Requests\\00")
      (func (export "lookup") (param $status i32) (result i32)
        (local.get $status)
        (i32.const 24)
        (i32.mul)
      )
    )
    """

    assert Wasm.call_string(wasm_source, "lookup", 200) == "OK"
    assert Wasm.call_string(wasm_source, "lookup", 201) == "Created"
    assert Wasm.call_string(wasm_source, "lookup", 204) == "No Content"
    assert Wasm.call_string(wasm_source, "lookup", 205) == "Reset Content"
    assert Wasm.call_string(wasm_source, "lookup", 301) == "Moved Permanently"
    assert Wasm.call_string(wasm_source, "lookup", 302) == "Found"
    assert Wasm.call_string(wasm_source, "lookup", 303) == "See Other"
    assert Wasm.call_string(wasm_source, "lookup", 304) == "Not Modified"
    assert Wasm.call_string(wasm_source, "lookup", 307) == "Temporary Redirect"
    assert Wasm.call_string(wasm_source, "lookup", 401) == "Unauthorized"
    assert Wasm.call_string(wasm_source, "lookup", 403) == "Forbidden"
    assert Wasm.call_string(wasm_source, "lookup", 404) == "Not Found"
    assert Wasm.call_string(wasm_source, "lookup", 405) == "Method Not Allowed"
    assert Wasm.call_string(wasm_source, "lookup", 409) == "Conflict"
    assert Wasm.call_string(wasm_source, "lookup", 412) == "Precondition Failed"
    assert Wasm.call_string(wasm_source, "lookup", 413) == "Payload Too Large"
    assert Wasm.call_string(wasm_source, "lookup", 422) == "Unprocessable Entity"
    assert Wasm.call_string(wasm_source, "lookup", 429) == "Too Many Requests"
    assert Wasm.call_string(wasm_source, "lookup", 100) == ""
    # Crashes:
    # assert Wasm.call_string(wasm_source, "lookup", -1) == ""
  end

  @wasm_calculate_mean """
  (module $CalculateMean
    (import "env" "buffer" (memory 1))
    (global $count (mut i32) (i32.const 0))
    (global $tally (mut i32) (i32.const 0))
    (func $insert (export "insert") (param $element i32)
      (i32.add (global.get $count) (i32.const 1))
      (global.set $count)
      (i32.add (global.get $tally) (local.get $element))
      (global.set $tally)
    )
    (func $calculate_mean (export "calculate_mean") (result i32)
      (i32.div_u (global.get $tally) (global.get $count))
    )
  )
  """

  test "steps/2 global calculates mean" do
    [nil, nil, nil, result] =
      Wasm.steps(@wasm_calculate_mean, [
        {:call, "insert", [5]},
        {:call, "insert", [7]},
        {:call, "insert", [9]},
        {:call, "calculate_mean", []}
      ])

    assert result == 7
  end

  defmodule FileNameSafe do
    def to_wat() do
      """
      (module $FileNameSafe
        (memory (export "memory") 2)
        (func $get_is_valid (export "get_is_valid") (result i32)
          (local $str i32)
          (local $char i32)
          (i32.const 1024)
          (local.set $str)
          (loop $EachChar (result i32)
            (i32.load8_u (local.get $str))
            (local.set $char)
            (i32.eq (local.get $char) (i32.const 47))
            (if
              (then
                (return (i32.const 0))
              )
            )
            (i32.eqz (local.get $char))
            (if
              (then
                (return (i32.const 1))
              )
            )
            (i32.add (local.get $str) (i32.const 1))
            (local.set $str)
            br $EachChar
          )
        )
      )
      """
    end
  end

  test "returns if a string is file name safe" do
    [result] =
      Wasm.steps(FileNameSafe, [
        {:write_string_nul_terminated, 1024, "good", true},
        {:call, "get_is_valid", []}
      ])

    assert result == 1

    [result] =
      Wasm.steps(FileNameSafe, [
        {:write_string_nul_terminated, 1024, "has/slashes", true},
        {:call, "get_is_valid", []}
      ])

    assert result == 0
  end

  defmodule CopyString do
    def to_wat() do
      """
      (module $CopyString
        (import "env" "buffer" (memory 2))
        (func $do_copy (export "do_copy") (result i32)
          (local $read_offset i32)
          (local $char i32)
          (i32.const 1024)
          (local.set $read_offset)
          (loop $EachChar (result i32)
            (block $Outer
              (i32.load8_u (local.get $read_offset))
              (local.set $char)
              (i32.store8 (i32.add (local.get $read_offset) (i32.const 1024)) (local.get $char))
              (local.get $char)
              br_if $Outer
              (i32.sub (local.get $read_offset) (i32.const 1024))
              return
            )
            (i32.add (local.get $read_offset) (i32.const 1))
            (local.set $read_offset)
            br $EachChar
          )
        )
      )
      """
    end
  end

  test "copies string bytes" do
    [len, result] =
      Wasm.steps(CopyString, [
        {:write_string_nul_terminated, 1024, "good", true},
        {:call, "do_copy", []},
        {:read_memory, 2048, 4}
      ])

    assert len == 4
    assert result == "good"
  end

  defmodule EscapeHTML do
    def to_wat() do
      """
      (module $EscapeHTML
        (import "env" "buffer" (memory 2))
        (func $escape_html (export "escape_html") (result i32)
          (local $read_offset i32)
          (local $write_offset i32)
          (local $char i32)
          (i32.const 1024)
          (local.set $read_offset)
          (i32.const 2048)
          (local.set $write_offset)
          (loop $EachChar (result i32)
            (block $Outer
              (i32.load8_u (local.get $read_offset))
              (local.set $char)
              (i32.eq (local.get $char) (i32.const 38))
              (if
                (then
                  (i32.store8 (local.get $write_offset) (i32.const 38))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 1)) (i32.const 97))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 2)) (i32.const 109))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 3)) (i32.const 112))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 4)) (i32.const 59))
                  (i32.add (local.get $write_offset) (i32.const 4))
                  (local.set $write_offset)
                  br $Outer
                )
              )
              (i32.eq (local.get $char) (i32.const 60))
              (if
                (then
                  (i32.store8 (local.get $write_offset) (i32.const 38))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 1)) (i32.const 108))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 2)) (i32.const 116))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 3)) (i32.const 59))
                  (i32.add (local.get $write_offset) (i32.const 3))
                  (local.set $write_offset)
                  br $Outer
                )
              )
              (i32.eq (local.get $char) (i32.const 62))
              (if
                (then
                  (i32.store8 (local.get $write_offset) (i32.const 38))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 1)) (i32.const 103))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 2)) (i32.const 116))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 3)) (i32.const 59))
                  (i32.add (local.get $write_offset) (i32.const 3))
                  (local.set $write_offset)
                  br $Outer
                )
              )
              (i32.eq (local.get $char) (i32.const 34))
              (if
                (then
                  (i32.store8 (local.get $write_offset) (i32.const 38))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 1)) (i32.const 113))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 2)) (i32.const 117))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 3)) (i32.const 111))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 4)) (i32.const 116))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 5)) (i32.const 59))
                  (i32.add (local.get $write_offset) (i32.const 5))
                  (local.set $write_offset)
                  br $Outer
                )
              )
              (i32.eq (local.get $char) (i32.const 39))
              (if
                (then
                  (i32.store8 (local.get $write_offset) (i32.const 38))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 1)) (i32.const 35))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 2)) (i32.const 51))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 3)) (i32.const 57))
                  (i32.store8 (i32.add (local.get $write_offset) (i32.const 4)) (i32.const 59))
                  (i32.add (local.get $write_offset) (i32.const 4))
                  (local.set $write_offset)
                  br $Outer
                )
              )
              (i32.store8 (local.get $write_offset) (local.get $char))
              (local.get $char)
              br_if $Outer
              (i32.sub (local.get $write_offset) (i32.const 2048))
              return
            )
            (i32.add (local.get $read_offset) (i32.const 1))
            (local.set $read_offset)
            (i32.add (local.get $write_offset) (i32.const 1))
            (local.set $write_offset)
            br $EachChar
          )
        )
      )
      """
    end
  end

  test "escapes html" do
    # dbg(EscapeHTML.to_wat())

    [count, result] =
      Wasm.steps(EscapeHTML, [
        {:write_string_nul_terminated, 1024, "hello", true},
        {:call, "escape_html", []},
        {:read_memory, 2048, 5}
      ])

    assert count == 5
    assert result == "hello"

    [count, result] =
      Wasm.steps(EscapeHTML, [
        {:write_string_nul_terminated, 1024, "Hall & Oates like M&Ms", true},
        {:call, "escape_html", []},
        {:read_memory, 2048, 40}
      ])

    result = String.trim_trailing(result, <<0>>)

    assert count == 30
    assert result == "Hall &amp; Oates like M&amp;Ms"

    [count, result] =
      Wasm.steps(EscapeHTML, [
        {:write_string_nul_terminated, 1024, ~s[1 < 2 & 2 > 1 "double quotes" 'single quotes'],
         true},
        {:call, "escape_html", []},
        {:read_memory, 2048, 100}
      ])

    result = String.trim_trailing(result, <<0>>)

    assert count == 73
    assert result == "1 &lt; 2 &amp; 2 &gt; 1 &quot;double quotes&quot; &#39;single quotes&#39;"
  end
end
