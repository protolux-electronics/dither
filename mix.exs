defmodule Dither.MixProject do
  use Mix.Project

  @source_url "https://github.com/protolux-electronics/dither"
  @version "0.1.0"

  @nerves_rust_target_triple_mapping %{
    "armv6-nerves-linux-gnueabihf": "arm-unknown-linux-gnueabihf",
    "armv7-nerves-linux-gnueabihf": "armv7-unknown-linux-gnueabihf",
    "aarch64-nerves-linux-gnu": "aarch64-unknown-linux-gnu",
    "x86_64-nerves-linux-musl": "x86_64-unknown-linux-musl"
  }

  def project do
    if is_binary(System.get_env("NERVES_SDK_SYSROOT")) do
      components =
        System.get_env("CC")
        |> tap(&System.put_env("RUSTFLAGS", "-C linker=#{&1}"))
        |> Path.basename()
        |> String.split("-")

      target_triple =
        components
        |> Enum.slice(0, Enum.count(components) - 1)
        |> Enum.join("-")

      mapping = Map.get(@nerves_rust_target_triple_mapping, String.to_atom(target_triple))

      if is_binary(mapping) do
        System.put_env("RUSTLER_TARGET", mapping)
      end
    end

    [
      app: :dither,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      source_url: @source_url
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
      {:rustler, "~> 0.36.2", optional: true},
      {:rustler_precompiled, "~> 0.8"}
    ]
  end

  defp description do
    "A rustler NIF for basic image processing and dithering"
  end

  defp package do
    [
      files: [
        "lib",
        "native",
        "checksum-*.exs",
        "mix.exs",
        "CHANGELOG.md",
        "README.md",
        "LICENSE"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/v#{@version}/CHANGELOG.md"
      },
      maintainers: ["Gus Workman"]
    ]
  end
end
