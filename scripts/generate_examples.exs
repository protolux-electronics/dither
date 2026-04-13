# scripts/generate_examples.exs

source_path = "test/test_image.jpg"
target_size = 1200

# 1. Load and Resize
IO.puts("Loading and resizing source image...")
original = Dither.load!(source_path) |> Dither.resize!(target_size, target_size)
Dither.save!(original, "assets/original_resized.png")

# 2. Grayscale, 1-bit, Jarvis
IO.puts("Generating Grayscale (Jarvis, 1-bit)...")
original
|> Dither.grayscale!()
|> Dither.dither!(algorithm: :jarvis, bit_depth: 1)
|> Dither.save!("assets/grayscale_jarvis_1bit.png")

# 3. Grayscale, 4-bit, Stucki
IO.puts("Generating Grayscale (Stucki, 4-bit)...")
original
|> Dither.grayscale!()
|> Dither.dither!(algorithm: :stucki, bit_depth: 4)
|> Dither.save!("assets/grayscale_stucki_4bit.png")

# 4. Color, CGA, Atkinson
IO.puts("Generating Color (CGA Palette, Atkinson)...")
original
|> Dither.dither!(algorithm: :atkinson, palette: :cga)
|> Dither.save!("assets/color_cga_atkinson.png")

# 5. Color, Websafe, Sierra
IO.puts("Generating Color (Websafe Palette, Sierra)...")
original
|> Dither.dither!(algorithm: :sierra, palette: :websafe)
|> Dither.save!("assets/color_websafe_sierra.png")

# 6. Color, Crayon, Floyd-Steinberg
IO.puts("Generating Color (Crayon, Floyd-Steinberg)...")
original
|> Dither.dither!(algorithm: :floyd_steinberg, palette: :crayon)
|> Dither.save!("assets/color_crayon_floyd.png")

IO.puts("All examples generated in assets/ directory.")
