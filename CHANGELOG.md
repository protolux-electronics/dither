# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[unreleased]: https://github.com/protolux-electronics/dither/compare/v0.1.0...HEAD
[0.1.1]: https://github.com/protolux-electronics/dither/releases/tag/v0.1.1

## [0.1.0] - 2025-09-21

Initial release!

[0.1.1]: https://github.com/protolux-electronics/dither/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/protolux-electronics/dither/releases/tag/v0.1.0
