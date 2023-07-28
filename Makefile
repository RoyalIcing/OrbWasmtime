.PHONY: force_build
force_build:
	ORB_WASMTIME_BUILD=1 mix compile

.PHONY: cargo_check
cargo_check:
	cd native/orb_wasmtime && cargo check && cargo clean

.PHONY: test
test:
	mix format --check-formatted
	ORB_WASMTIME_BUILD=1 mix test

.PHONY: rustler_precompiled_download
rustler_precompiled_download:
	mix rustler_precompiled.download OrbWasmtime.Rust --all --print --ignore-unavailable

checksum-Elixir.OrbWasmtime.Rust.exs: mix.exs
	$(MAKE) rustler_precompiled_download
