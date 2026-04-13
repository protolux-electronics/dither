defmodule Dither.Palette do
  @moduledoc """
  Helpers for defining and normalizing color palettes for dithering.
  """

  @type rgb :: {byte(), byte(), byte()}
  @type color :: rgb() | String.t() | atom()

  @doc """
  Normalizes a palette or a list of colors into a list of RGB tuples `[{r, g, b}]`.

  Supported input formats:
  - List of RGB tuples: `[{255, 255, 255}, {0, 0, 0}]`
  - List of Hex strings: `["#FFFFFF", "#000000"]` (with or without `#`)
  - Predefined palette atoms: `:cga`, `:websafe`
  """
  @spec normalize(color() | [color()]) :: [rgb()]
  def normalize(palette) when is_list(palette) do
    Enum.map(palette, &normalize_color/1)
  end

  def normalize(:cga), do: cga()
  def normalize(:websafe), do: websafe()
  def normalize(:crayon), do: crayon()

  @doc """
  The 16-color CGA palette.
  """
  def cga do
    [
      {0, 0, 0},
      {0, 0, 170},
      {0, 170, 0},
      {0, 170, 170},
      {170, 0, 0},
      {170, 0, 170},
      {170, 85, 0},
      {170, 170, 170},
      {85, 85, 85},
      {85, 85, 255},
      {85, 255, 85},
      {85, 255, 255},
      {255, 85, 85},
      {255, 85, 255},
      {255, 255, 85},
      {255, 255, 255}
    ]
  end

  @doc """
  The 216-color Web Safe palette.
  """
  def websafe do
    for r <- [0x00, 0x33, 0x66, 0x99, 0xCC, 0xFF],
        g <- [0x00, 0x33, 0x66, 0x99, 0xCC, 0xFF],
        b <- [0x00, 0x33, 0x66, 0x99, 0xCC, 0xFF],
        do: {r, g, b}
  end

  @doc """
  A crayon-like palette with 25 colors, mostly based on a 24-pack of Crayola crayons.
  """
  def crayon do
    [
      # Yellow
      "#FCE883",
      # Blue
      "#1F75FE",
      # Black
      "#232323",
      # Violet (Purple)
      "#926EAE",
      # Blue Green
      "#199EBD",
      # Red Violet
      "#C0448F",
      # Red Orange
      "#FF5349",
      # Yellow Green
      "#C5E384",
      # Red
      "#EE204D",
      # Orange
      "#FF7538",
      # Dandelion
      "#FDDB6D",
      # Cerulean
      "#1DACD6",
      # White
      "#EDEDED",
      # Violet Red
      "#F75394",
      # Gray
      "#95918C",
      # Indigo
      "#5D76CB",
      # Apricot
      "#FDD9B5",
      # Carnation Pink
      "#FFAACC",
      # Scarlet
      "#FC2847",
      # Green
      "#1CAC78",
      # Blue Violet
      "#7366BD",
      # Brown
      "#B4674D",
      # Green Yellow
      "#F0E891",
      # True Black
      "#000000",
      # True White
      "#FFFFFF"
    ]
    |> normalize()
  end

  defp normalize_color({r, g, b}) when r in 0..255 and g in 0..255 and b in 0..255, do: {r, g, b}

  defp normalize_color("#" <> hex), do: normalize_color(hex)

  defp normalize_color(hex) when is_binary(hex) and byte_size(hex) == 6 do
    <<r::8, g::8, b::8>> = Base.decode16!(hex, case: :mixed)
    {r, g, b}
  end

  defp normalize_color(atom) when is_atom(atom) do
    # Simple color atoms
    case atom do
      :black -> {0, 0, 0}
      :white -> {255, 255, 255}
      :red -> {255, 0, 0}
      :green -> {0, 255, 0}
      :blue -> {0, 0, 255}
      :yellow -> {255, 255, 0}
      :cyan -> {0, 255, 255}
      :magenta -> {255, 0, 255}
      _ -> raise ArgumentError, "unknown color atom: #{inspect(atom)}"
    end
  end
end
