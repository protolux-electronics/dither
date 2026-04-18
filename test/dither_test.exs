defmodule DitherTest do
  use ExUnit.Case, async: true
  alias Dither

  setup_all do
    # Load the real test image and resize it to 800x600 once for all tests
    image = Dither.load!("test/test_image.jpg") |> Dither.resize!(800, 600)
    {width, height} = image.size
    %{image: image, width: width, height: height}
  end

  setup context do
    # Create a unique temporary path for each test to allow async execution
    test_name = Atom.to_string(context.test) |> String.replace(" ", "_")
    tmp_path = Path.join(System.tmp_dir!(), "#{test_name}_image.png")

    on_exit(fn ->
      if File.exists?(tmp_path), do: File.rm(tmp_path)
    end)

    %{tmp_path: tmp_path}
  end

  test "dimensions", %{image: image, width: width, height: height} do
    assert Dither.dimensions(image) == {width, height}
    assert image.size == {width, height}
  end

  test "encode and encode!", %{image: image} do
    assert {:ok, binary} = Dither.encode(image)
    # PNG header in hex
    assert <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _rest::binary>> = binary

    assert <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _rest::binary>> =
             Dither.encode!(image)

    # Test other formats
    assert {:ok, jpeg} = Dither.encode(image, :jpeg)
    assert <<0xFF, 0xD8, 0xFF, _rest::binary>> = jpeg

    assert {:ok, bmp} = Dither.encode(image, :bmp)
    assert <<0x42, 0x4D, _rest::binary>> = bmp

    assert {:ok, webp} = Dither.encode(image, :webp)
    assert <<0x52, 0x49, 0x46, 0x46, _size::32, 0x57, 0x45, 0x42, 0x50, _rest::binary>> = webp
  end

  test "decode and decode!", %{image: image} do
    {:ok, binary} = Dither.encode(image)
    assert {:ok, %Dither{} = decoded} = Dither.decode(binary)
    assert decoded.size == image.size

    assert %Dither{} = Dither.decode!(binary)
  end

  test "save and load", %{image: image, tmp_path: path} do
    assert :ok = Dither.save(image, path)
    assert File.exists?(path)

    assert {:ok, %Dither{} = loaded} = Dither.load(path)
    assert loaded.size == image.size

    assert %Dither{} = Dither.load!(path)
  end

  test "to_raw and to_raw!", %{image: image} do
    assert {:ok, raw} = Dither.to_raw(image)
    {w, h} = image.size
    assert byte_size(raw) == w * h * image.channels

    assert Dither.to_raw!(image) == raw
  end

  test "resize and resize!", %{image: image} do
    assert {:ok, %Dither{} = resized} = Dither.resize(image, 400, 300)
    assert resized.size == {400, 300}

    assert %Dither{} = Dither.resize!(image, 800, 600)
  end

  test "grayscale and grayscale!", %{image: image} do
    assert {:ok, %Dither{} = gray} = Dither.grayscale(image)
    assert gray.channels == 1

    assert %Dither{} = Dither.grayscale!(image)
  end

  test "contrast and contrast!", %{image: image} do
    assert {:ok, %Dither{} = adjusted} = Dither.contrast(image, 2.0)
    assert adjusted.size == image.size

    assert %Dither{} = Dither.contrast!(image, -1.5)
    assert %Dither{} = Dither.contrast!(image, 0)
  end

  test "crop and crop!", %{image: image} do
    assert {:ok, %Dither{} = cropped} = Dither.crop(image, 0, 0, 100, 100)
    assert cropped.size == {100, 100}

    assert %Dither{} = Dither.crop!(image, 10, 10, 50, 50)
  end

  test "center_crop and center_crop!", %{image: image} do
    assert {:ok, %Dither{} = cropped} = Dither.center_crop(image, 100, 100)
    assert cropped.size == {100, 100}

    assert %Dither{} = Dither.center_crop!(image, 200, 200)
    assert {:error, :invalid_crop_area} = Dither.center_crop(image, 1000, 1000)
  end

  test "flip and flip!", %{image: image} do
    assert {:ok, %Dither{} = flipped} = Dither.flip(image, :horizontal)
    assert flipped.size == image.size

    assert %Dither{} = Dither.flip!(image, :vertical)
    assert %Dither{} = Dither.flip!(image, :both)
  end

  test "rotate and rotate!", %{image: image} do
    {w, h} = image.size

    # 90 degrees
    assert {:ok, %Dither{} = r90} = Dither.rotate(image, 90)
    assert r90.size == {h, w}

    # 180 degrees
    assert {:ok, %Dither{} = r180} = Dither.rotate(image, 180)
    assert r180.size == {w, h}

    # 270 degrees
    assert %Dither{} = r270 = Dither.rotate!(image, 270)
    assert r270.size == {h, w}
  end

  test "dither and dither!", %{image: image} do
    # Image must be grayscale for bit_depth dithering
    gray = Dither.grayscale!(image)
    assert {:ok, %Dither{} = dithered} = Dither.dither(gray)
    assert dithered.size == gray.size

    assert %Dither{} = Dither.dither!(gray, algorithm: :atkinson)
  end

  test "from_raw and from_raw! with RGB data" do
    # 2x2 RGB image (3 channels): 2 * 2 * 3 = 12 bytes
    data = :crypto.strong_rand_bytes(12)
    width = 2
    height = 2
    assert {:ok, %Dither{} = image} = Dither.from_raw(data, width, height)
    assert image.size == {width, height}
    assert image.channels == 3
  end

  test "from_raw with RGBA data" do
    # 2x2 RGBA image (4 channels): 2 * 2 * 4 = 16 bytes
    data = :crypto.strong_rand_bytes(16)
    width = 2
    height = 2
    assert {:ok, %Dither{} = image} = Dither.from_raw(data, width, height)
    assert image.size == {width, height}
    assert image.channels == 4

    # Dither should fail for RGBA
    assert {:error, :unsupported_channel_count} = Dither.dither(image)

    # Convert to RGB should work
    assert {:ok, %Dither{} = rgb} = Dither.to_rgb(image)
    assert rgb.channels == 3
    assert rgb.size == {width, height}

    # Now dither should work
    assert {:ok, %Dither{} = dithered} = Dither.dither(rgb)
    assert dithered.channels == 1
  end

  test "grayscale/1 converts RGB to grayscale" do
    # 2x2 RGB image: 12 bytes
    data = :crypto.strong_rand_bytes(12)
    width = 2
    height = 2
    {:ok, rgb_image} = Dither.from_raw(data, width, height)
    assert rgb_image.channels == 3

    assert {:ok, %Dither{} = gray_image} = Dither.grayscale(rgb_image)
    assert gray_image.channels == 1
    assert gray_image.size == {width, height}
  end

  test "dither/2 supports all algorithms", %{image: image} do
    gray = Dither.grayscale!(image)

    algorithms = [
      :floyd_steinberg,
      :atkinson,
      :stucki,
      :burkes,
      :jarvis,
      :sierra
    ]

    for algo <- algorithms do
      assert {:ok, %Dither{} = dithered} = Dither.dither(gray, algorithm: algo)
      assert dithered.size == gray.size
      assert dithered.channels == 1
    end
  end

  test "dither/2 with custom palette (color dithering)", %{image: image} do
    # Dither to just Red and Black
    palette = ["#FF0000", "#000000"]

    assert {:ok, %Dither{} = dithered} = Dither.dither(image, palette: palette)
    assert dithered.size == image.size
    assert dithered.channels == 3

    # Check some raw bytes to see if it's restricted to our palette
    raw = Dither.to_raw!(dithered)

    # Every 3 bytes should be either [255, 0, 0] or [0, 0, 0]
    for <<r, g, b <- raw>> do
      assert {r, g, b} in [{255, 0, 0}, {0, 0, 0}]
    end
  end

  test "dither bit_depth correctly limits unique colors", %{image: image} do
    gray = Dither.grayscale!(image)

    # bit_depth: 1 => 2^1 = 2 colors
    d1 = Dither.dither!(gray, bit_depth: 1)
    colors1 = Dither.to_raw!(d1) |> :binary.bin_to_list() |> Enum.uniq()
    assert length(colors1) == 2

    # bit_depth: 2 => 2^2 = 4 colors
    d2 = Dither.dither!(gray, bit_depth: 2)
    colors2 = Dither.to_raw!(d2) |> :binary.bin_to_list() |> Enum.uniq()
    assert length(colors2) == 4

    # bit_depth: 3 => 2^3 = 8 colors
    d3 = Dither.dither!(gray, bit_depth: 3)
    colors3 = Dither.to_raw!(d3) |> :binary.bin_to_list() |> Enum.uniq()
    assert length(colors3) == 8
  end

  test "load error when file not found" do
    assert {:error, :file_not_found} = Dither.load("non_existent_file.png")
  end
end
