defmodule Dither do
  @moduledoc """
  Documentation for `Dither`.
  """

  alias Dither.NIF

  def load(path) when is_binary(path) do
    cond do
      File.exists?(path) ->
        NIF.load(path)

      true ->
        {:error, :file_not_found}
    end
  end

  def load!(path) when is_binary(path) do
    case load(path) do
      {:ok, image} -> image
      {:error, reason} -> raise "unable to load the file at #{inspect(path)}: #{inspect(reason)}"
    end
  end

  def save(image, path) when is_reference(image) and is_binary(path) do
    case NIF.save(image, path) do
      {:ok, :success} -> :ok
      other -> other
    end
  end

  def save!(image, path) when is_reference(image) and is_binary(path) do
    case save(image, path) do
      :ok ->
        :ok

      {:error, reason} ->
        raise "unable to save image to location #{inspect(path)}: #{inspect(reason)}"
    end
  end

  def decode(data) when is_binary(data) do
    NIF.decode(data)
  end

  def decode!(data) when is_binary(data) do
    case decode(data) do
      {:ok, image} -> image
      {:error, reason} -> raise "decoding erorr: #{inspect(reason)}"
    end
  end

  def encode(image) when is_reference(image) do
    NIF.encode(image)
  end

  def encode!(image) when is_reference(image) do
    case encode(image) do
      {:ok, bytes} ->
        bytes

      {:error, reason} ->
        raise "encoding error: #{inspect(reason)}"
    end
  end

  def from_raw(data, width, height)
      when is_binary(data) and is_integer(width) and is_integer(height) do
    NIF.from_raw(data, width, height)
  end

  def from_raw!(data, width, height)
      when is_binary(data)
      when is_binary(data) and is_integer(width) and is_integer(height) do
    case from_raw(data, width, height) do
      {:ok, image} -> image
      {:error, reason} -> raise "decoding erorr: #{inspect(reason)}"
    end
  end

  def to_raw(image) when is_reference(image) do
    NIF.to_raw(image)
  end

  def to_raw!(image) when is_reference(image) do
    case to_raw(image) do
      {:ok, bytes} ->
        bytes

      {:error, reason} ->
        raise "encoding error: #{inspect(reason)}"
    end
  end

  def resize(image, width, height)
      when is_reference(image) and is_integer(width) and is_integer(height) do
    NIF.resize(image, width, height)
  end

  def resize!(image, width, height)
      when is_reference(image) and is_integer(width) and is_integer(height) do
    case resize(image, width, height) do
      {:ok, image} ->
        image

      {:error, reason} ->
        raise "resizing error: #{inspect(reason)}"
    end
  end

  def dither(image, opts \\ []) when is_reference(image) do
    algorithm = Keyword.get(opts, :algorithm, :sierra)
    bit_depth = Keyword.get(opts, :bit_depth, 1)

    NIF.dither(image, :bw, algorithm, bit_depth)
  end

  def dither!(image, opts \\ []) when is_reference(image) do
    case dither(image, opts) do
      {:ok, image} ->
        image

      {:error, reason} ->
        raise "dithering error: #{inspect(reason)}"
    end
  end

  def dimensions(image) when is_reference(image) do
    {:ok, dims} = NIF.dimensions(image)
    dims
  end
end
