defmodule OrbWasmtime.Rust do
  # if false and Mix.env() == :dev do
  # use Rustler, otp_app: :components_guide, crate: :componentsguide_rustler_math

  # Inspired by https://github.com/tessi/wasmex

  mix_config = Mix.Project.config()
  version = mix_config[:version]
  github_url = mix_config[:package][:links]["GitHub"]
  # Since Rustler 0.27.0, we need to change manually the mode for each env.
  # We want "debug" in dev and test because it's faster to compile.
  mode = if Mix.env() in [:dev, :test], do: :debug, else: :release

  use RustlerPrecompiled,
    otp_app: :orb_wasmtime,
    base_url: "#{github_url}/releases/download/v#{version}",
    version: version,
    targets: ~w(
			aarch64-apple-darwin
			aarch64-unknown-linux-gnu
			aarch64-unknown-linux-musl
			riscv64gc-unknown-linux-gnu
			x86_64-apple-darwin
			x86_64-pc-windows-gnu
			x86_64-pc-windows-msvc
			x86_64-unknown-linux-gnu
			x86_64-unknown-linux-musl
		),
    mode: mode,
    force_build: System.get_env("ORB_WASMTIME_BUILD") in ["1", "true"]

  defp error, do: :erlang.nif_error(:nif_not_loaded)

  def add(_, _), do: error()
  def reverse_string(_), do: error()

  def strlen(_), do: error()

  def wasm_list_exports(_), do: error()
  def wasm_list_imports(_), do: error()

  def wasm_call(_, _, _), do: error()
  def wasm_call_void(_, _), do: error()
  def wasm_call_i32_string(_, _, _), do: error()

  def wasm_steps(_, _), do: error()

  def wasm_run_instance(_, _, _, _), do: error()
  def wasm_instance_get_global_i32(_, _), do: error()
  def wasm_instance_set_global_i32(_, _, _), do: error()
  def wasm_instance_call_func(_, _, _), do: error()
  def wasm_instance_call_func_i32(_, _, _), do: error()
  def wasm_instance_call_func_i32_string(_, _, _), do: error()
  def wasm_instance_cast_func_i32(_, _, _), do: error()
  def wasm_instance_write_i32(_, _, _), do: error()
  def wasm_instance_write_i64(_, _, _), do: error()
  def wasm_instance_write_memory(_, _, _), do: error()
  def wasm_instance_write_string_nul_terminated(_, _, _), do: error()
  def wasm_instance_read_memory(_, _, _), do: error()
  def wasm_instance_read_string_nul_terminated(_, _), do: error()
  def wasm_call_out_reply(_, _), do: error()
  def wasm_caller_read_string_nul_terminated(_, _), do: error()

  def wat2wasm(_), do: error()
  def validate_module_definition(_), do: error()
end
