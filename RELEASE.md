# Release Instructions

- Update `README.md`, `CHANGELOG.md`, `mix.exs` version number
- Commit and push changes.
- Create release on GitHub.
- Wait for GitHub Actions to finish.
- Download checksum file:
  `DITHER_BUILD=true mix rustler_precompiled.download Dither.NIF --ignore-unavailable --print`
- Remove target directory: `rm -rf native/dither_nif/target/`
- Release to Hex: `mix hex.publish`
