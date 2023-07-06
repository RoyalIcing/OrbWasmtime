defmodule OrbWasmtime.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/RoyalIcing/orb_wasmtime"
  @force_build? System.get_env("ORB_WASMTIME_BUILD") in ["1", "true"]

  def project do
    [
      app: :orb_wasmtime,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
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
      {:rustler, "~> 0.29.0", optional: not @force_build?},
      {:rustler_precompiled, "~> 0.6"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
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
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      maintainers: ["Patrick Smith"]
    ]
  end
end
