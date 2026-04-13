defmodule DitherIntegrationTest do
  use ExUnit.Case
  alias Dither

  @test_image "test/test_image.jpg"

  setup do
    tmp_dir = System.tmp_dir!()
    tmp_path = Path.join(tmp_dir, "dither_integration_output.png")

    on_exit(fn ->
      if File.exists?(tmp_path), do: File.rm(tmp_path)
    end)

    %{tmp_path: tmp_path}
  end

  test "full workflow: load, resize, grayscale, dither, and save", %{tmp_path: tmp_path} do
    # 1. Load
    assert %Dither{} = image = Dither.load!(@test_image)
    {w, h} = image.size
    assert w > 0
    assert h > 0

    # 2. Resize (to 100px width, preserving aspect ratio would be better but NIF resize is to fill)
    # Let's just resize to 100x100 for a quick test
    assert %Dither{} = resized = Dither.resize!(image, 100, 100)
    assert resized.size == {100, 100}

    # 3. Grayscale
    assert %Dither{} = gray = Dither.grayscale!(resized)
    assert gray.channels == 1

    # 4. Dither (Grayscale)
    assert %Dither{} = dithered_bw = Dither.dither!(gray, algorithm: :atkinson)
    assert dithered_bw.channels == 1

    # 5. Save
    assert :ok = Dither.save(dithered_bw, tmp_path)
    assert File.exists?(tmp_path)
    assert File.stat!(tmp_path).size > 0
  end

  test "color dithering workflow with predefined palette", %{tmp_path: tmp_path} do
    # 1. Load and Resize
    image =
      Dither.load!(@test_image)
      |> Dither.resize!(200, 200)

    # 2. Dither to CGA palette
    assert %Dither{} = dithered_cga = Dither.dither!(image, palette: :cga)
    assert dithered_cga.channels == 3
    assert dithered_cga.size == {200, 200}

    # 3. Encode to binary
    assert binary = Dither.encode!(dithered_cga)
    # Check PNG header
    assert <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _rest::binary>> = binary

    # 4. Decode back
    assert %Dither{} = decoded = Dither.decode!(binary)
    assert decoded.size == {200, 200}
    assert decoded.channels == 3

    # 5. Save
    assert :ok = Dither.save(dithered_cga, tmp_path)
  end

  test "raw byte manipulation on real image" do
    image = Dither.load!(@test_image) |> Dither.resize!(50, 50)
    {w, h} = image.size

    # 1. To Raw
    assert raw = Dither.to_raw!(image)
    # 50 * 50 * 3 channels = 7500 bytes
    assert byte_size(raw) == w * h * 3

    # 2. From Raw
    assert %Dither{} = from_raw = Dither.from_raw!(raw, w, h)
    assert from_raw.size == {w, h}
    assert from_raw.channels == 3
  end

  test "flipping real image" do
    image = Dither.load!(@test_image) |> Dither.resize!(100, 100)

    assert %Dither{} = flipped = Dither.flip!(image, :both)
    assert flipped.size == {100, 100}
  end
end
