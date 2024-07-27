defmodule OrbWasmtime.MixProject do
  use Mix.Project

  @version "0.1.14"
  @source_url "https://github.com/RoyalIcing/orb_wasmtime"
  @force_build? System.get_env("ORB_WASMTIME_BUILD") in ["1", "true"]

  def project do
    [
      app: :orb_wasmtime,
      name: "Orb Wasmtime",
      description: "Run WebAssembly in Elixir via Wasmtime",
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      preferred_cli_env: [
        docs: :docs,
        "hex.publish": :docs
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.31.2", only: :docs, runtime: false},
      {:rustler, "~> 0.33.0", optional: not @force_build?},
      {:rustler_precompiled, "~> 0.7.2"},
      {:benchee, "~> 1.0", only: :dev}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp docs do
    [
      main: "OrbWasmtime",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "LICENSE"
        # "notebooks/pretrained.livemd"
      ]
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "native",
        "checksum-*.exs",
        "mix.exs",
        # ,
        "README.md"
        # "LICENSE"
      ],
      licenses: ["BSD-3-Clause"],
      links: %{"GitHub" => @source_url},
      maintainers: ["Patrick Smith"]
    ]
  end
end
