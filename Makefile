.PHONY: force_build
force_build:
	ORB_WASMTIME_BUILD=1 mix compile

.PHONY: test
test:
	ORB_WASMTIME_BUILD=1 mix test
