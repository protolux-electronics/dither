defmodule Dither.PaletteTest do
  use ExUnit.Case
  alias Dither.Palette

  test "normalize hex strings" do
    assert Palette.normalize(["#FF0000", "00FF00"]) == [{255, 0, 0}, {0, 255, 0}]
  end

  test "normalize RGB tuples" do
    assert Palette.normalize([{255, 255, 255}, {0, 0, 0}]) == [{255, 255, 255}, {0, 0, 0}]
  end

  test "normalize predefined atoms" do
    assert Palette.normalize([:red, :black]) == [{255, 0, 0}, {0, 0, 0}]
  end

  test "normalize predefined palettes" do
    cga = Palette.normalize(:cga)
    assert length(cga) == 16
    assert Enum.at(cga, 0) == {0, 0, 0}

    gb = Palette.normalize(:gameboy)
    assert length(gb) == 4

    websafe = Palette.normalize(:websafe)
    assert length(websafe) == 216
  end

  test "normalize raises on unknown atoms" do
    assert_raise ArgumentError, fn ->
      Palette.normalize([:non_existent_color])
    end
  end
end
