# scripts/generate_examples.exs

source_path = "test/test_image.jpg"
target_size = 1200

# 1. Load and Resize
IO.puts("Loading and resizing source image...")
original = Dither.load!(source_path) |> Dither.resize!(target_size, target_size)
Dither.save!(original, "assets/original_resized.png")

# 2. Grayscale, 1-bit, Atkinson
IO.puts("Generating Grayscale (Atkinson, 1-bit)...")
original
|> Dither.grayscale!()
|> Dither.dither!(algorithm: :atkinson, bit_depth: 1)
|> Dither.save!("assets/grayscale_atkinson_1bit.png")

# 3. Grayscale, 4-bit, Floyd-Steinberg
IO.puts("Generating Grayscale (Floyd-Steinberg, 4-bit)...")
original
|> Dither.grayscale!()
|> Dither.dither!(algorithm: :floyd_steinberg, bit_depth: 4)
|> Dither.save!("assets/grayscale_floyd_4bit.png")

# 4. Color, CGA, Sierra
IO.puts("Generating Color (CGA Palette, Sierra)...")
original
|> Dither.dither!(algorithm: :sierra, palette: :cga)
|> Dither.save!("assets/color_cga_sierra.png")

# 5. Color, Game Boy, Stucki
IO.puts("Generating Color (Game Boy Palette, Stucki)...")
original
|> Dither.dither!(algorithm: :stucki, palette: :gameboy)
|> Dither.save!("assets/color_gameboy_stucki.png")

# 6. Color, Websafe, Burkes
IO.puts("Generating Color (Websafe Palette, Burkes)...")
original
|> Dither.dither!(algorithm: :burkes, palette: :websafe)
|> Dither.save!("assets/color_websafe_burkes.png")

IO.puts("All examples generated in assets/ directory.")
