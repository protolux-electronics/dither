defmodule Dither.NIF do
  use Rustler,
    otp_app: :dither,
    crate: :dither_nif,
    target: System.get_env("RUSTLER_TARGET")

  def load(_path), do: :erlang.nif_error(:nif_not_loaded)
  def save(_resource, _path), do: :erlang.nif_error(:nif_not_loaded)
  def decode(_binary), do: :erlang.nif_error(:nif_not_loaded)
  def encode(_resource), do: :erlang.nif_error(:nif_not_loaded)
  def from_raw(_binary, _width, _height), do: :erlang.nif_error(:nif_not_loaded)
  def to_raw(_resource), do: :erlang.nif_error(:nif_not_loaded)
  def resize(_resource, _new_width, _new_height), do: :erlang.nif_error(:nif_not_loaded)
  def grayscale(_resource), do: :erlang.nif_error(:nif_not_loaded)
  def dither(_resource, _mode, _algorithm, _bit_depth), do: :erlang.nif_error(:nif_not_loaded)
  def dimensions(_resource), do: :erlang.nif_error(:nif_not_loaded)
end
