# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.3] - 2026-04-18

Adds contrast adjustment functionality and automatic EXIF orientation.

### Added

- `Dither.contrast/2` and `Dither.contrast!/2` to adjust image contrast.

### Changed

- Images are now automatically rotated according to their EXIF orientation data
  upon loading or decoding.

## [0.2.2] - 2026-04-13

Better support for RGBA images and new rotation utility.

### Added

- Support for loading and decoding RGBA images (4 channels).
- `Dither.to_rgb/1` and `Dither.to_rgb!/1` to convert images to RGB8.
- `Dither.rotate/2` and `Dither.rotate!/2` to rotate images (90, 180, 270
  degrees).
- Explicit channel count check in `Dither.dither/2`.

### Changed

- `Dither.dither/2` now returns `{:error, :unsupported_channel_count}` if an
  RGBA image is provided without conversion.

## [0.2.1] - 2026-04-13

Adds color dithering support and custom color palettes

- Implemented dithering support for RGB images using custom palettes
- Added Dither.Palette module for normalizing colors and providing predefined
  palettes
- Defined several built-in palettes: `:cga`, `:websafe`, and `:crayon`

## [0.2.0] - 2026-04-13

Adds a new %Dither{} struct (replaces the reference returned from `load/1`,
`decode/1`, and `from_raw/3`). Adds metadata to the struct (including image size
and channels). Improves documentation, and adds testing

## [0.1.1] - 2025-12-07

Bug fixes.

### Changed

`Dither.from_raw` previously only accepted a list as the first argument, whereas
it should only allow a binary. This has been fixed.

Proper usage:

```elixir
iex> Dither.from_raw(<<1>>, 1, 1)
{:ok, #Reference<0.253499029.2847801345.146246>}
```

[unreleased]: https://github.com/protolux-electronics/dither/compare/v0.2.3...HEAD
[0.2.3]: https://github.com/protolux-electronics/dither/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/protolux-electronics/dither/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/protolux-electronics/dither/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/protolux-electronics/dither/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/protolux-electronics/dither/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/protolux-electronics/dither/releases/tag/v0.1.0
