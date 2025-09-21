# Dither

This library is a rustler NIF for Elixir which provides support for some basic
image manipulation functions, as well as dithering. Supported functions include:

- load an image from file
- save an image to file
- decode an image from bytes
- encode an image to bytes
- resize an image
- flip an image
- convert an image to grayscale
- dither an image with various algorithms
- ... and more

The dithering functions wrap the excellent
[`dither`](https://gitlab.com/efronlicht/dither) library from Efron Licht.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `dither` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dither, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with
[ExDoc](https://github.com/elixir-lang/ex_doc) and published on
[HexDocs](https://hexdocs.pm). Once published, the docs can be found at
<https://hexdocs.pm/dither>.
