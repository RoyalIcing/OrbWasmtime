# OrbWasmtime

Run WebAssembly modules in Elixir via Rust & Wasmtime.

**Note: this project is in alpha and will change. For another WebAssembly runner for Elixir [check out Wasmex](https://github.com/tessi/wasmex).**

## Installation

Add `orb_wasmtime` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:orb_wasmtime, "~> 0.1.0"}
  ]
end
```

## About

OrbWasmtime lets you run a WebAssembly module and interact with it. You can call functions, list exports, pass imports, get/set globals, and read/write memory.

```elixir
defmodule Example do
  alias OrbWasmtime.Instance

  def run() do
    inst = Instance.run(example_wat())
    add = Instance.capture(inst, :add, 2)
    add.(2, 3) # 5
    add.(4, 5) # 9
  end

  defp example_wat() do
    """
    (module $Add
      (func (export "add") (param $a i32) (param $b i32) (result i32)
        (i32.add (local.get $a) (local.get $b))
      )
    )
    """
  end
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/orb_wasmtime>.
