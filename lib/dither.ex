defmodule Dither do
  @moduledoc """
  An Elixir library for image processing and dithering using a Rust NIF.
  """

  defstruct [:ref, :size, :channels]

  @type t :: %__MODULE__{
          ref: reference(),
          size: {pos_integer(), pos_integer()},
          channels: 1 | 3
        }

  @type dither_algorithm :: :floyd_steinberg | :atkinson | :stucki | :burkes | :jarvis | :sierra
  @type dither_opts :: [algorithm: dither_algorithm(), bit_depth: pos_integer()]
  @type flip_direction :: :horizontal | :vertical | :both

  alias Dither.NIF

  @doc """
  Loads an image from the given file path.
  """
  @spec load(binary()) :: {:ok, t()} | {:error, atom()}
  def load(path) when is_binary(path) do
    cond do
      File.exists?(path) ->
        case NIF.load(path) do
          {:ok, ref} -> {:ok, from_ref(ref)}
          {:error, reason} -> {:error, reason}
        end

      true ->
        {:error, :file_not_found}
    end
  end

  @doc """
  Loads an image from the given file path, raises on error.
  """
  @spec load!(binary()) :: t()
  def load!(path) when is_binary(path) do
    case load(path) do
      {:ok, image} -> image
      {:error, reason} -> raise "unable to load the file at #{inspect(path)}: #{inspect(reason)}"
    end
  end

  @doc """
  Saves the image to the specified file path.
  """
  @spec save(t(), binary()) :: :ok | {:error, atom()}
  def save(%__MODULE__{ref: ref}, path) when is_binary(path) do
    case NIF.save(ref, path) do
      {:ok, :success} -> :ok
      other -> other
    end
  end

  @doc """
  Saves the image to the specified file path, raises on error.
  """
  @spec save!(t(), binary()) :: :ok
  def save!(image, path) when is_binary(path) do
    case save(image, path) do
      :ok ->
        :ok

      {:error, reason} ->
        raise "unable to save image to location #{inspect(path)}: #{inspect(reason)}"
    end
  end

  @doc """
  Decodes an image from binary data.
  """
  @spec decode(binary()) :: {:ok, t()} | {:error, atom()}
  def decode(data) when is_binary(data) do
    case NIF.decode(data) do
      {:ok, ref} -> {:ok, from_ref(ref)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Decodes an image from binary data, raises on error.
  """
  @spec decode!(binary()) :: t()
  def decode!(data) when is_binary(data) do
    case decode(data) do
      {:ok, image} -> image
      {:error, reason} -> raise "decoding error: #{inspect(reason)}"
    end
  end

  @doc """
  Encodes the image into a PNG binary.
  """
  @spec encode(t()) :: {:ok, binary()} | {:error, atom()}
  def encode(%__MODULE__{ref: ref}) do
    NIF.encode(ref)
  end

  @doc """
  Encodes the image into a PNG binary, raises on error.
  """
  @spec encode!(t()) :: binary()
  def encode!(image) do
    case encode(image) do
      {:ok, bytes} ->
        bytes

      {:error, reason} ->
        raise "encoding error: #{inspect(reason)}"
    end
  end

  @doc """
  Creates an image from raw bytes with specified width and height.
  """
  @spec from_raw(binary(), pos_integer(), pos_integer()) :: {:ok, t()} | {:error, atom()}
  def from_raw(data, width, height)
      when is_binary(data) and is_integer(width) and is_integer(height) do
    case NIF.from_raw(data, width, height) do
      {:ok, ref} -> {:ok, from_ref(ref)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Creates an image from raw bytes with specified width and height, raises on error.
  """
  @spec from_raw!(binary(), pos_integer(), pos_integer()) :: t()
  def from_raw!(data, width, height)
      when is_binary(data) and is_integer(width) and is_integer(height) do
    case from_raw(data, width, height) do
      {:ok, image} -> image
      {:error, reason} -> raise "decoding error: #{inspect(reason)}"
    end
  end

  @doc """
  Returns the raw bytes of the image.
  """
  @spec to_raw(t()) :: {:ok, binary()} | {:error, atom()}
  def to_raw(%__MODULE__{ref: ref}) do
    NIF.to_raw(ref)
  end

  @doc """
  Returns the raw bytes of the image, raises on error.
  """
  @spec to_raw!(t()) :: binary()
  def to_raw!(image) do
    case to_raw(image) do
      {:ok, bytes} ->
        bytes

      {:error, reason} ->
        raise "encoding error: #{inspect(reason)}"
    end
  end

  @doc """
  Resizes the image to the specified width and height.
  """
  @spec resize(t(), pos_integer(), pos_integer()) :: {:ok, t()} | {:error, atom()}
  def resize(%__MODULE__{ref: ref}, width, height)
      when is_integer(width) and is_integer(height) do
    case NIF.resize(ref, width, height) do
      {:ok, new_ref} -> {:ok, from_ref(new_ref)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Resizes the image to the specified width and height, raises on error.
  """
  @spec resize!(t(), pos_integer(), pos_integer()) :: t()
  def resize!(image, width, height)
      when is_integer(width) and is_integer(height) do
    case resize(image, width, height) do
      {:ok, image} ->
        image

      {:error, reason} ->
        raise "resizing error: #{inspect(reason)}"
    end
  end

  @doc """
  Converts the image to grayscale.
  """
  @spec grayscale(t()) :: {:ok, t()} | {:error, atom()}
  def grayscale(%__MODULE__{ref: ref}) do
    case NIF.grayscale(ref) do
      {:ok, new_ref} -> {:ok, from_ref(new_ref)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Converts the image to grayscale, raises on error.
  """
  @spec grayscale!(t()) :: t()
  def grayscale!(image) do
    case grayscale(image) do
      {:ok, image} -> image
      {:error, reason} -> raise "grayscale error: #{inspect(reason)}"
    end
  end

  @doc """
  Flips the image in the specified direction.
  """
  @spec flip(t(), flip_direction()) :: {:ok, t()} | {:error, atom()}
  def flip(%__MODULE__{ref: ref}, direction)
      when direction in [:horizontal, :vertical, :both] do
    case NIF.flip(ref, direction) do
      {:ok, new_ref} -> {:ok, from_ref(new_ref)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Flips the image in the specified direction, raises on error.
  """
  @spec flip!(t(), flip_direction()) :: t()
  def flip!(image, direction)
      when direction in [:horizontal, :vertical, :both] do
    case flip(image, direction) do
      {:ok, image} -> image
      {:error, reason} -> raise "flip error: #{inspect(reason)}"
    end
  end

  @doc """
  Applies a dithering algorithm to the image.

  ## Options

    * `:algorithm` - The dithering algorithm to use. One of:
      * `:floyd_steinberg`
      * `:atkinson`
      * `:stucki`
      * `:burkes`
      * `:jarvis`
      * `:sierra` (default)
    * `:bit_depth` - The bit depth for the resulting image (default: `1`).

  """
  @spec dither(t(), dither_opts()) :: {:ok, t()} | {:error, atom()}
  def dither(%__MODULE__{ref: ref}, opts \\ []) do
    algorithm = Keyword.get(opts, :algorithm, :sierra)
    bit_depth = Keyword.get(opts, :bit_depth, 1)

    case NIF.dither(ref, :bw, algorithm, bit_depth) do
      {:ok, new_ref} -> {:ok, from_ref(new_ref)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Applies a dithering algorithm to the image, raises on error.

  See `dither/2` for a list of available options.
  """
  @spec dither!(t(), dither_opts()) :: t()
  def dither!(image, opts \\ []) do
    case dither(image, opts) do
      {:ok, image} ->
        image

      {:error, reason} ->
        raise "dithering error: #{inspect(reason)}"
    end
  end

  @doc """
  Returns the dimensions of the image as a `{width, height}` tuple.
  """
  @spec dimensions(t()) :: {pos_integer(), pos_integer()}
  def dimensions(%__MODULE__{ref: ref}) do
    {:ok, dims} = NIF.dimensions(ref)
    dims
  end

  defp from_ref(ref) do
    {:ok, size} = NIF.dimensions(ref)
    {:ok, channels} = NIF.channels(ref)

    %__MODULE__{
      ref: ref,
      size: size,
      channels: channels
    }
  end
end
