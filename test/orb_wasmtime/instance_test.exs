defmodule OrbWasmtime.Instance.Test do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Wasm
  alias OrbWasmtime.Instance

  test "url_encoded_count" do
    inst = Instance.run(url_encoded_wat())
    count = Instance.capture(inst, :url_encoded_count, 1)

    assert count.("") == 0
    assert count.("a") == 1
    assert count.("a&") == 1
    assert count.("a&&") == 1
    assert count.("&a&") == 1
    assert count.("&&a&&") == 1
    assert count.("a=1") == 1
    assert count.("a=1&") == 1
    assert count.("a=1&&") == 1
    assert count.("&&a=1&&") == 1
    assert count.("a=1&b=2") == 2
    assert count.("a=1&&b=2") == 2
    assert count.("a=1&&b=2&") == 2
    assert count.("a=1&&b=2&&") == 2
    assert count.("&&a=1&&b=2&&") == 2
  end

  test "url_encoded_empty?" do
    inst = Instance.run(url_encoded_wat())
    empty? = Instance.capture(inst, :url_encoded_empty?, 1)

    assert empty?.("") == 1
    assert empty?.("a") == 0
    assert empty?.("a&") == 0
    assert empty?.("a&&") == 0
    assert empty?.("&a&") == 0
    assert empty?.("&&a&&") == 0
    assert empty?.("a=1") == 0
    assert empty?.("a=1&") == 0
    assert empty?.("a=1&&") == 0
    assert empty?.("&&a=1&&") == 0
    assert empty?.("a=1&b=2") == 0
    assert empty?.("a=1&&b=2") == 0
    assert empty?.("a=1&&b=2&") == 0
    assert empty?.("a=1&&b=2&&") == 0
    assert empty?.("&&a=1&&b=2&&") == 0
  end

  test "url_encoded_first_value_offset" do
    inst = Instance.run(url_encoded_wat())

    first_value_offset =
      Instance.capture(inst, :url_encoded_first_value_offset, 1)

    first_value =
      Instance.capture(inst, String, :url_encoded_first_value_offset, 1)

    assert first_value_offset.("") == 0
    assert first_value_offset.("a") == 0
    assert first_value_offset.("a&") == 0
    assert first_value_offset.("a&&") == 0
    assert first_value_offset.("&a&") == 0
    assert first_value_offset.("&&a&&") == 0
    assert first_value_offset.("a=") == 0
    assert first_value_offset.("a=1") > 0
    assert first_value_offset.("a=1&") > 0
    assert first_value_offset.("a=1&&") > 0
    assert first_value_offset.("&&a=1&&") > 0
    assert first_value_offset.("a=1&b=2") > 0
    assert first_value_offset.("a=1&&b=2") > 0
    assert first_value_offset.("a=1&&b=2&") > 0
    assert first_value_offset.("a=1&&b=2&&") > 0
    assert first_value_offset.("&&a=1&&b=2&&") > 0
    assert first_value_offset.("urls%5B%5D=https%3A") > 0

    assert first_value.("") == ""
    assert first_value.("a") == ""
    assert first_value.("a&") == ""
    assert first_value.("a&&") == ""
    assert first_value.("&a&") == ""
    assert first_value.("&&a&&") == ""
    assert first_value.("a=") == ""
    assert first_value.("a=1") == "1"
    assert first_value.("a=1&") == "1&"
    assert first_value.("a=1&&") == "1&&"
    assert first_value.("&&a=1&&") == "1&&"
    assert first_value.("a=1&b=2") == "1&b=2"
    assert first_value.("a=1&&b=2") == "1&&b=2"
    assert first_value.("a=1&&b=2&") == "1&&b=2&"
    assert first_value.("a=1&&b=2&&") == "1&&b=2&&"
    assert first_value.("&&a=1&&b=2&&") == "1&&b=2&&"
    assert first_value.("urls%5B%5D=https%3A") == "https%3A"
  end

  test "url_encoded_clone_first" do
    inst = Instance.run(url_encoded_wat())

    clone_first =
      Instance.capture(inst, String, :url_encoded_clone_first, 1)

    assert clone_first.("") == ""
    assert clone_first.("a") == "a"
    assert clone_first.("a&") == "a"
    assert clone_first.("a&&") == "a"
    assert clone_first.("&a&") == "a"
    assert clone_first.("&&a&&") == "a"
    assert clone_first.("a=1") == "a=1"
    assert clone_first.("a=1&") == "a=1"
    assert clone_first.("a=1&&") == "a=1"
    assert clone_first.("&&a=1&&") == "a=1"
    assert clone_first.("a=1&b=2") == "a=1"
    assert clone_first.("a=1&&b=2") == "a=1"
    assert clone_first.("a=1&&b=2&") == "a=1"
    assert clone_first.("a=1&&b=2&&") == "a=1"
    assert clone_first.("&&a=1&&b=2&&") == "a=1"
  end

  test "url_encoded_rest" do
    inst = Instance.run(url_encoded_wat())

    rest =
      Instance.capture(inst, String, :url_encoded_rest, 1)

    assert rest.("") == ""
    assert rest.("&") == ""
    assert rest.("a") == ""
    assert rest.("a&") == "&"
    assert rest.("a&&") == "&&"
    assert rest.("&a&") == "&"
    assert rest.("&&a&&") == "&&"
    assert rest.("a=") == ""
    assert rest.("a=&") == "&"
    assert rest.("a=1") == ""
    assert rest.("a=1&") == "&"
    assert rest.("a=1&&") == "&&"
    assert rest.("&&a=1&&") == "&&"
    assert rest.("a=1&b=2") == "&b=2"
    assert rest.("a=1&&b=2") == "&&b=2"
    assert rest.("a=1&&b=2&") == "&&b=2&"
    assert rest.("a=1&&b=2&&") == "&&b=2&&"
    assert rest.("&&a=1&&b=2&&") == "&&b=2&&"
  end

  test "url_encode_rfc3986" do
    inst = Instance.run(url_encoded_wat())
    url_encode = Instance.capture(inst, String, :url_encode_rfc3986, 1)

    assert url_encode.("0123456789") == "0123456789"
    assert url_encode.("abcxyzABCXYZ") == "abcxyzABCXYZ"
    assert url_encode.("two words") == "two%20words"
    assert url_encode.("TWO WORDS") == "TWO%20WORDS"
    assert url_encode.("`") == "%60"
    assert url_encode.("<>`") == "%3C%3E%60"
    assert url_encode.("put it+й") == "put%20it+%D0%B9"

    assert url_encode.("ftp://s-ite.tld/?value=put it+й") ==
             "ftp://s-ite.tld/?value=put%20it+%D0%B9"

    assert url_encode.("ftp://s-ite.tld/?value=put it+й") ==
             URI.encode("ftp://s-ite.tld/?value=put it+й")

    assert url_encode.(":/?#[]@!$&\'()*+,;=~_-.") == ":/?#[]@!$&\'()*+,;=~_-."
    assert url_encode.(":/?#[]@!$&\'()*+,;=~_-.") == URI.encode(":/?#[]@!$&\'()*+,;=~_-.")

    assert url_encode.("😀") == "%F0%9F%98%80"
    assert url_encode.("💪🏾") == "%F0%9F%92%AA%F0%9F%8F%BE"
  end

  test "url_encode_www_form" do
    inst = Instance.run(url_encoded_wat())
    url_encode = Instance.capture(inst, String, :url_encode_www_form, 1)

    assert url_encode.("0123456789") == "0123456789"
    assert url_encode.("abcxyzABCXYZ") == "abcxyzABCXYZ"
    assert url_encode.("two words") == "two+words"
    assert url_encode.("TWO WORDS") == "TWO+WORDS"
    assert url_encode.("+") == "%2B"
    assert url_encode.("`") == "%60"
    assert url_encode.("<>`") == "%3C%3E%60"
    assert url_encode.("put it+й") == "put+it%2B%D0%B9"

    assert url_encode.("ftp://s-ite.tld/?value=put it+й") ==
             "ftp%3A%2F%2Fs-ite.tld%2F%3Fvalue%3Dput+it%2B%D0%B9"

    assert url_encode.("ftp://s-ite.tld/?value=put it+й") ==
             URI.encode_www_form("ftp://s-ite.tld/?value=put it+й")

    assert url_encode.(":/?#[]@!$&\'()*,;=~_-.") ==
             "%3A%2F%3F%23%5B%5D%40%21%24%26%27%28%29%2A%2C%3B%3D~_-."

    assert url_encode.(":/?#[]@!$&\'()*,;=~_-.") ==
             URI.encode_www_form(":/?#[]@!$&\'()*,;=~_-.")

    assert url_encode.("😀") == "%F0%9F%98%80"
    assert url_encode.("💪🏾") == "%F0%9F%92%AA%F0%9F%8F%BE"
  end

  @tag :skip
  test "append_url_encode_query_pair_www_form" do
    inst = Instance.run(url_encoded_wat())
    append_query = Instance.capture(inst, String, :append_url_encode_query_pair_www_form, 2)
    build_start = Instance.capture(inst, :bump_write_start, 0)
    build_done = Instance.capture(inst, String, :bump_write_done, 0)

    a = Instance.alloc_string(inst, "a")
    b = Instance.alloc_string(inst, "b")

    build_start.()
    append_query.(a, b)
    s = build_done.()

    assert s == "&a=b"
  end

  @tag :skip
  test "url_encode_query_www_form" do
    inst = Instance.run(url_encoded_wat())
    url_encode_query = Instance.capture(inst, String, :url_encode_query_www_form, 1)

    # {list, bytes, list_bytes} = Instance.alloc_list(inst, [["a", "1"], ["b", "2"]])
    # assert list == [[<<97, 0>>, <<49, 0>>], [<<98, 0>>, <<50, 0>>]]
    # assert bytes == <<97, 0, 49, 0, 98, 0, 50, 0>>
    # assert list_bytes == <<65540::little-size(32), 65552::little-size(32)>>
    list_ptr = Instance.alloc_list(inst, [["a", "1"], ["b", "2"]])
    assert url_encode_query.(list_ptr) == "a=1&b=2"

    # result = Instance.call(
    #   URLEncoded.url_encode_query_www_form([
    #     a: 1,
    #     b: 1,
    #   ])
    # )
  end

  @tag :skip
  test "wasm byte size" do
    assert byte_size(Wasm.to_wasm(url_encoded_wat())) == 1985
  end

  defp url_encoded_wat() do
    """
    (module $URLEncoded
      (memory (export "memory") 2)
      (global $bump_write_level (mut i32) (i32.const 0))
      (global $bump_offset (mut i32) (i32.const 65536))
      (global $bump_mark (mut i32) (i32.const 0))
      (func $alloc (export "alloc") (param $size i32) (result i32)
        (call $bump_alloc (local.get $size))
      )
      (func $free_all (export "free_all")
        (i32.const 65536)
        (global.set $bump_offset)
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
      (func $bump_alloc (param $size i32) (result i32)
        (global.get $bump_offset)
        (i32.add (global.get $bump_offset) (local.get $size))
        (global.set $bump_offset)

      )
      (func $url_encode_rfc3986 (export "url_encode_rfc3986") (param $str_ptr i32) (result i32)
        (local $char i32)
        (local $abc i32)
        (local $__dup_32 i32)
        (call $bump_write_start)
        (loop $EachByte
          (i32.load8_u (local.get $str_ptr))
          (local.set $char)
          (local.get $char)
          (if
            (then
              (i32.or (i32.or (i32.or (i32.and (i32.ge_u (local.get $char) (i32.const 97)) (i32.le_u (local.get $char) (i32.const 122))) (i32.and (i32.ge_u (local.get $char) (i32.const 65)) (i32.le_u (local.get $char) (i32.const 90)))) (i32.and (i32.ge_u (local.get $char) (i32.const 48)) (i32.le_u (local.get $char) (i32.const 57)))) (i32.eq (local.get $char) (i32.const 43))
    (i32.eq (local.get $char) (i32.const 58))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 47))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 63))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 35))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 91))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 93))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 64))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 33))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 36))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 38))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 92))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 39))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 40))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 41))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 42))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 44))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 59))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 61))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 126))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 95))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 45))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 46))
    (i32.or))
              (if
                (then
                  (i32.store8 (global.get $bump_offset) (local.get $char))
                  (i32.add (global.get $bump_offset) (i32.const 1))
                  (global.set $bump_offset)
                )
                (else
                  (i32.store8 (global.get $bump_offset) (i32.const 37))
                  (i32.add (global.get $bump_offset) (i32.const 1))
                  (global.set $bump_offset)
                  (i32.store8 (global.get $bump_offset) (i32.add (i32.shr_u (local.get $char) (i32.const 4)) (i32.le_u (i32.shr_u (local.get $char) (i32.const 4)) (i32.const 9))
    (if (result i32)
      (then
        (i32.const 48)
      )
      (else
        (i32.const 55)
      )
    )))
                  (i32.add (global.get $bump_offset) (i32.const 1))
                  (global.set $bump_offset)
                  (i32.store8 (global.get $bump_offset) (i32.add (i32.and (local.get $char) (i32.const 15)) (i32.le_u (i32.and (local.get $char) (i32.const 15)) (i32.const 9))
    (if (result i32)
      (then
        (i32.const 48)
      )
      (else
        (i32.const 55)
      )
    )))
                  (i32.add (global.get $bump_offset) (i32.const 1))
                  (global.set $bump_offset)
                )
              )
              (i32.add (local.get $str_ptr) (i32.const 1))
              (local.set $str_ptr)
              br $EachByte
            )
          )
        )
        (call $bump_write_done)
      )
      (func $append_url_encode_www_form (export "append_url_encode_www_form") (param $str_ptr i32)
        (local $char i32)
        (local $abc i32)
        (local $__dup_32 i32)
        (loop $EachByte
          (i32.load8_u (local.get $str_ptr))
          (local.set $char)
          (local.get $char)
          (if
            (then
              (i32.eq (local.get $char) (i32.const 32))
              (if
                (then
                  (i32.store8 (global.get $bump_offset) (i32.const 43))
                  (i32.add (global.get $bump_offset) (i32.const 1))
                  (global.set $bump_offset)
                )
                (else
                  (i32.or (i32.or (i32.or (i32.and (i32.ge_u (local.get $char) (i32.const 97)) (i32.le_u (local.get $char) (i32.const 122))) (i32.and (i32.ge_u (local.get $char) (i32.const 65)) (i32.le_u (local.get $char) (i32.const 90)))) (i32.and (i32.ge_u (local.get $char) (i32.const 48)) (i32.le_u (local.get $char) (i32.const 57)))) (i32.eq (local.get $char) (i32.const 126))
    (i32.eq (local.get $char) (i32.const 95))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 45))
    (i32.or)
    (i32.eq (local.get $char) (i32.const 46))
    (i32.or))
                  (if
                    (then
                      (i32.store8 (global.get $bump_offset) (local.get $char))
                      (i32.add (global.get $bump_offset) (i32.const 1))
                      (global.set $bump_offset)
                    )
                    (else
                      (i32.store8 (global.get $bump_offset) (i32.const 37))
                      (i32.add (global.get $bump_offset) (i32.const 1))
                      (global.set $bump_offset)
                      (i32.store8 (global.get $bump_offset) (i32.add (i32.shr_u (local.get $char) (i32.const 4)) (i32.le_u (i32.shr_u (local.get $char) (i32.const 4)) (i32.const 9))
    (if (result i32)
      (then
        (i32.const 48)
      )
      (else
        (i32.const 55)
      )
    )))
                      (i32.add (global.get $bump_offset) (i32.const 1))
                      (global.set $bump_offset)
                      (i32.store8 (global.get $bump_offset) (i32.add (i32.and (local.get $char) (i32.const 15)) (i32.le_u (i32.and (local.get $char) (i32.const 15)) (i32.const 9))
    (if (result i32)
      (then
        (i32.const 48)
      )
      (else
        (i32.const 55)
      )
    )))
                      (i32.add (global.get $bump_offset) (i32.const 1))
                      (global.set $bump_offset)
                    )
                  )
                )
              )
              (i32.add (local.get $str_ptr) (i32.const 1))
              (local.set $str_ptr)
              br $EachByte
            )
          )
        )
      )
      (func $append_url_encode_query_pair_www_form (export "append_url_encode_query_pair_www_form") (param $key i32) (param $value i32)
        (i32.store8 (global.get $bump_offset) (i32.const 38))
        (i32.add (global.get $bump_offset) (i32.const 1))
        (global.set $bump_offset)
        (call $append_url_encode_www_form (local.get $key))
        (i32.store8 (global.get $bump_offset) (i32.const 61))
        (i32.add (global.get $bump_offset) (i32.const 1))
        (global.set $bump_offset)
        (call $append_url_encode_www_form (local.get $value))
      )
      (func $url_encode_www_form (export "url_encode_www_form") (param $str_ptr i32) (result i32)
        (local $char i32)
        (local $abc i32)
        (local $__dup_32 i32)
        (call $bump_write_start)
        (call $append_url_encode_www_form (local.get $str_ptr))
        (call $bump_write_done)
      )
      (func $decode_char_www_form (export "decode_char_www_form") (param $str i32) (result i32)
        (local $c0 i32)
        (local $c1 i32)
        (local $c2 i32)
        (i32.load8_u (local.get $str))
        (local.set $c0)
        (i32.eqz (local.get $c0))
        (if
          (then
            (return (i32.const 0))
          )
        )
        (block $i32_match (result i32)
          (i32.eq (local.get $c0) (i32.const 37))
          (if
            (then
              (i32.load8_u (i32.add (local.get $str) (i32.const 1)))
              (local.set $c1)
              (i32.eqz (local.get $c1))
              (if (result i32)
                (then
                  (i32.const 0)
                )
                (else
                  (i32.load8_u (i32.add (local.get $str) (i32.const 2)))
                  (local.set $c2)
                  (i32.add (i32.shl (i32.add (i32.and (local.get $c1) (i32.const 15)) (i32.mul (i32.shr_u (local.get $c1) (i32.const 6)) (i32.const 9))) (i32.const 4)) (i32.add (i32.and (local.get $c2) (i32.const 15)) (i32.mul (i32.shr_u (local.get $c2) (i32.const 6)) (i32.const 9))))
                )
              )
              br $i32_match
            )
          )
          (local.get $c0)

        )
      )
      (func $url_encoded_count (export "url_encoded_count") (param $url_encoded i32) (result i32)
        (local $char i32)
        (local $count i32)
        (local $pair_char_len i32)
        (loop $EachByte
          (i32.load8_u (local.get $url_encoded))
          (local.set $char)
          (i32.eq (local.get $char) (i32.const 38))
          (i32.eqz (local.get $char))
          (i32.or)
          (if
            (then
              (i32.add (local.get $count) (i32.gt_u (local.get $pair_char_len) (i32.const 0)))
              (local.set $count)
              (i32.const 0)
              (local.set $pair_char_len)
            )
            (else
              (i32.add (local.get $pair_char_len) (i32.const 1))
              (local.set $pair_char_len)
            )
          )
          (i32.add (local.get $url_encoded) (i32.const 1))
          (local.set $url_encoded)
          (local.get $char)
          br_if $EachByte
        )
        (local.get $count)
      )
      (func $url_encoded_empty? (export "url_encoded_empty?") (param $url_encoded i32) (result i32)
        (local $char i32)
        (local $pair_char_len i32)
        (loop $EachByte (result i32)
          (i32.load8_u (local.get $url_encoded))
          (local.set $char)
          (i32.eqz (local.get $char))
          (if
            (then
              (return (i32.const 1))
            )
          )
          (i32.eqz (i32.eq (local.get $char) (i32.const 38)))
          (if
            (then
              (return (i32.const 0))
            )
          )
          (i32.add (local.get $url_encoded) (i32.const 1))
          (local.set $url_encoded)
          br $EachByte
        )
      )
      (func $url_encoded_clone_first (export "url_encoded_clone_first") (param $url_encoded i32) (result i32)
        (local $char i32)
        (local $len i32)
        (call $bump_write_start)
        (loop $EachByte (result i32)
          (i32.load8_u (local.get $url_encoded))
          (local.set $char)
          (i32.or (i32.eqz (local.get $char)) (i32.and (i32.eq (local.get $char) (i32.const 38)) (i32.gt_u (local.get $len) (i32.const 0))))
          (if
            (then
              (call $bump_write_done)
              return
            )
          )
          (i32.eqz (i32.eq (local.get $char) (i32.const 38)))
          (if
            (then
              (i32.store8 (global.get $bump_offset) (local.get $char))
              (i32.add (global.get $bump_offset) (i32.const 1))
              (global.set $bump_offset)
              (i32.add (local.get $len) (i32.const 1))
              (local.set $len)
            )
          )
          (i32.add (local.get $url_encoded) (i32.const 1))
          (local.set $url_encoded)
          br $EachByte
        )
      )
      (func $url_encoded_rest (export "url_encoded_rest") (param $url_encoded i32) (result i32)
        (local $char i32)
        (local $len i32)
        (loop $EachByte (result i32)
          (i32.load8_u (local.get $url_encoded))
          (local.set $char)
          (i32.or (i32.eqz (local.get $char)) (i32.and (i32.eq (local.get $char) (i32.const 38)) (i32.gt_u (local.get $len) (i32.const 0))))
          (if
            (then
              (local.get $url_encoded)
              return
            )
          )
          (i32.eqz (i32.eq (local.get $char) (i32.const 38)))
          (if
            (then
              (i32.add (local.get $len) (i32.const 1))
              (local.set $len)
            )
          )
          (i32.add (local.get $url_encoded) (i32.const 1))
          (local.set $url_encoded)
          br $EachByte
        )
      )
      (func $url_encoded_decode_first_value_www_form (export "url_encoded_decode_first_value_www_form") (param $url_encoded i32) (param $key i32) (result i32)
        (i32.const 0)
      )
      (func $url_encoded_first_value_offset (export "url_encoded_first_value_offset") (param $url_encoded i32) (result i32)
        (local $char i32)
        (local $len i32)
        (loop $EachByte (result i32)
          (i32.load8_u (local.get $url_encoded))
          (local.set $char)
          (i32.or (i32.eqz (local.get $char)) (i32.and (i32.eq (local.get $char) (i32.const 38)) (i32.gt_u (local.get $len) (i32.const 0))))
          (if
            (then
              (i32.const 0)
              return
            )
          )
          (i32.eq (local.get $char) (i32.const 61))
          (if
            (then
              (i32.add (local.get $url_encoded) (i32.const 1))
              (local.set $url_encoded)
              (i32.load8_u (local.get $url_encoded))
              (local.set $char)
              (i32.eqz (local.get $char))
              (i32.eq (local.get $char) (i32.const 38))
              (i32.or)
              (if (result i32)
                (then
                  (i32.const 0)
                )
                (else
                  (local.get $url_encoded)
                )
              )
              return
            )
          )
          (i32.eqz (i32.eq (local.get $char) (i32.const 38)))
          (if
            (then
              (i32.add (local.get $len) (i32.const 1))
              (local.set $len)
            )
          )
          (i32.add (local.get $url_encoded) (i32.const 1))
          (local.set $url_encoded)
          br $EachByte
        )
      )
      (func $_url_encoded_value_next_char (export "_url_encoded_value_next_char") (param $ptr i32) (result i32)
        (local $next i32)
        (local $next_char i32)
        (i32.add (i32.eq (i32.load8_u (local.get $ptr)) (i32.const 37))
    (if (result i32)
      (then
        (i32.const 3)
      )
      (else
        (i32.const 1)
      )
    ) (local.get $ptr))
        (local.set $next)
        (i32.load8_u (local.get $next))
        (local.set $next_char)
        (i32.eqz (local.get $next_char))
        (i32.eq (local.get $next_char) (i32.const 38))
        (i32.or)
        (if (result i32)
          (then
            (i32.const 0)
          )
          (else
            (local.get $next)
          )
        )
      )
    )
    """
  end
end
