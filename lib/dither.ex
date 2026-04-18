defmodule Dither do
  @moduledoc """
  An Elixir library for image processing and dithering using a Rust NIF.
  """

  defstruct [:ref, :size, :channels]

  @type t :: %__MODULE__{
          ref: reference(),
          size: {pos_integer(), pos_integer()},
          channels: 1 | 3 | 4
        }

  @type dither_algorithm :: :floyd_steinberg | :atkinson | :stucki | :burkes | :jarvis | :sierra
  @type dither_opts :: [
          algorithm: dither_algorithm(),
          bit_depth: pos_integer(),
          palette: Dither.Palette.color() | [Dither.Palette.color()]
        ]
  @type flip_direction :: :horizontal | :vertical | :both
  @type rotation_degrees :: 90 | 180 | 270
  @type image_format ::
          :avif
          | :bmp
          | :exr
          | :ff
          | :farbfeld
          | :gif
          | :hdr
          | :ico
          | :jpeg
          | :png
          | :pnm
          | :qoi
          | :tga
          | :tiff
          | :webp

  alias Dither.NIF
  alias Dither.Palette

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
  Encodes the image into a binary of the specified format. Default is `:png`.
  """
  @spec encode(t(), image_format()) :: {:ok, binary()} | {:error, atom()}
  def encode(%__MODULE__{ref: ref}, format \\ :png) do
    NIF.encode(ref, format)
  end

  @doc """
  Encodes the image into a binary of the specified format, raises on error.
  """
  @spec encode!(t(), image_format()) :: binary()
  def encode!(image, format \\ :png) do
    case encode(image, format) do
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
  Converts the image to RGB8 (3 channels).
  """
  @spec to_rgb(t()) :: {:ok, t()} | {:error, atom()}
  def to_rgb(%__MODULE__{ref: ref}) do
    case NIF.to_rgb(ref) do
      {:ok, new_ref} -> {:ok, from_ref(new_ref)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Converts the image to RGB8 (3 channels), raises on error.
  """
  @spec to_rgb!(t()) :: t()
  def to_rgb!(image) do
    case to_rgb(image) do
      {:ok, image} -> image
      {:error, reason} -> raise "conversion error: #{inspect(reason)}"
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
  Adjusts the contrast of the image.

  `factor` is the amount to adjust the contrast by. Negative values decrease
  the contrast and positive values increase the contrast.
  """
  @spec contrast(t(), float()) :: {:ok, t()} | {:error, atom()}
  def contrast(%__MODULE__{ref: ref}, factor) when is_number(factor) do
    case NIF.contrast(ref, factor * 1.0) do
      {:ok, new_ref} -> {:ok, from_ref(new_ref)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Adjusts the contrast of the image, raises on error.
  """
  @spec contrast!(t(), float()) :: t()
  def contrast!(image, factor) when is_number(factor) do
    case contrast(image, factor) do
      {:ok, image} -> image
      {:error, reason} -> raise "contrast error: #{inspect(reason)}"
    end
  end

  @doc """
  Rotates the image clockwise by the specified degrees (90, 180, or 270).
  """
  @spec rotate(t(), rotation_degrees()) :: {:ok, t()} | {:error, atom()}
  def rotate(%__MODULE__{ref: ref}, degrees) when degrees in [90, 180, 270] do
    case NIF.rotate(ref, degrees) do
      {:ok, new_ref} -> {:ok, from_ref(new_ref)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Rotates the image clockwise by the specified degrees (90, 180, or 270), raises on error.
  """
  @spec rotate!(t(), rotation_degrees()) :: t()
  def rotate!(image, degrees) when degrees in [90, 180, 270] do
    case rotate(image, degrees) do
      {:ok, image} -> image
      {:error, reason} -> raise "rotation error: #{inspect(reason)}"
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
    * `:palette` - A custom color palette. If provided, `bit_depth` is ignored and the image is dithered to these colors.
      Accepted formats:
      * List of RGB tuples: `[{255, 0, 0}, ...]`
      * List of hex strings: `["#FF0000", ...]`
      * Predefined palette atoms: `:cga`, `:gameboy`, `:websafe`

  """
  @spec dither(t(), dither_opts()) :: {:ok, t()} | {:error, atom()}
  def dither(%__MODULE__{ref: ref, channels: channels}, opts \\ []) do
    algorithm = Keyword.get(opts, :algorithm, :sierra)
    bit_depth = Keyword.get(opts, :bit_depth, 1)

    cond do
      channels == 1 or channels == 3 ->
        case Keyword.get(opts, :palette) do
          nil ->
            case NIF.dither(ref, :bw, algorithm, bit_depth) do
              {:ok, new_ref} -> {:ok, from_ref(new_ref)}
              {:error, reason} -> {:error, reason}
            end

          palette_input ->
            palette = Palette.normalize(palette_input)

            case NIF.dither(ref, {:color, palette}, algorithm, bit_depth) do
              {:ok, new_ref} -> {:ok, from_ref(new_ref)}
              {:error, reason} -> {:error, reason}
            end
        end

      true ->
        {:error, :unsupported_channel_count}
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
