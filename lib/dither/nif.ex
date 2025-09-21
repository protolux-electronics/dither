defmodule Dither.NIF do
  mix_config =
    Mix.Project.config()

  version = mix_config[:version]

  github_url =
    mix_config[:package][:links]["GitHub"]

  # Since Rustler 0.27.0, we need to change manually the mode for each env.
  # We want "debug" in dev and test because it's faster to compile.
  mode = if Mix.env() in [:dev, :test], do: :debug, else: :release

  use RustlerPrecompiled,
    otp_app: :dither,
    crate: :dither_nif,
    version: version,
    base_url: "#{github_url}/releases/download/v#{version}",
    targets: ~w(
      aarch64-apple-darwin
      aarch64-unknown-linux-gnu
      aarch64-unknown-linux-musl
      x86_64-apple-darwin
      x86_64-pc-windows-msvc
      x86_64-pc-windows-gnu
      x86_64-unknown-linux-gnu
      x86_64-unknown-linux-musl
      x86_64-unknown-freebsd
      arm-unknown-linux-gnueabihf
      armv7-unknown-linux-gnueabihf
    ),
    nif_versions: ["2.15"],
    mode: mode,
    force_build: System.get_env("DITHER_BUILD") in ["1", "true"],
    target: System.get_env("RUSTLER_TARGET")

  def load(_path), do: :erlang.nif_error(:nif_not_loaded)
  def save(_resource, _path), do: :erlang.nif_error(:nif_not_loaded)
  def decode(_binary), do: :erlang.nif_error(:nif_not_loaded)
  def encode(_resource), do: :erlang.nif_error(:nif_not_loaded)
  def from_raw(_binary, _width, _height), do: :erlang.nif_error(:nif_not_loaded)
  def to_raw(_resource), do: :erlang.nif_error(:nif_not_loaded)
  def resize(_resource, _new_width, _new_height), do: :erlang.nif_error(:nif_not_loaded)
  def grayscale(_resource), do: :erlang.nif_error(:nif_not_loaded)
  def flip(_resource, _direction), do: :erlang.nif_error(:nif_not_loaded)
  def dither(_resource, _mode, _algorithm, _bit_depth), do: :erlang.nif_error(:nif_not_loaded)
  def dimensions(_resource), do: :erlang.nif_error(:nif_not_loaded)
end
