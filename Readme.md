# Texture Generator (`texgen`)

Dynamically generates a texture pack for your current game in the `textures` directory.

## Features

* Compatible with virtually all mods and games
* Easy texture pack generation, no complex installation
* Server-side (mod-based) texture pack; textures can be accessed by other mods

## Instructions

Just fire up the mod and configure it to your liking. It might throw an error message as it updates its `mod.conf` to depend on all enabled mods. Simply retry after that.

### Downloading palettes

You can use the `/download_palette <url>` chatcommand to download a PNG palette file, for example `/download_palette https://lospec.com/palette-list/zughy-32-1x.png`.

See `/help download_palette` for details on its usage.

Requires the `server` priv. Only available if `texgen` is added to `secure.http_mods`.

**WARNING: Enabling this feature poses a minor security risk.**

## Configuration

<!--modlib:conf:2-->
### `average`

Replace each texture with a single pixel of its weighted average RGB color

* Type: boolean
* Default: `false`

### `invert`

Invert the RGB colors

* Type: boolean
* Default: `false`

### `monochrome`

Convert RGB to monochrome (greyscale)

* Type: boolean
* Default: `false`

### `palette`

#### `dithering`

Dithering method to use

* Type: string
* Default: `floyd_steinberg`
* Possible values:
  * sierra
  * stucke
  * sierra_lite
  * jarvis_judice_ninke
  * floyd_steinberg
  * none
  * two_row_sierra
  * burkes
  * atkinson

#### `name`

Name of the palette to use (without extension)

* Type: string
* Default: `apollo`
* Possible values:
  * soggy-newspapers
  * apollo
  * zughy-32
  * aap-64
  * pico-8
  * resurrect-64


### `saturate`

Increase or decrease saturation by a factor

* Type: number
* Default: `1`
* &gt;= `0.1`
* &lt;= `10`
<!--modlib:conf-->

## Links

* [GitHub](https://github.com/appgurueu/texgen) - sources, issue tracking, contributing
* [Discord](https://discord.gg/ysP74by) - discussion, chatting
* [Minetest Forum](https://forum.minetest.net/viewtopic.php?f=9&t=28115) - (more organized) discussion
* [ContentDB](https://content.minetest.net/packages/LMD/texgen) - releases (downloading from GitHub is recommended)

## License

Code written by Lars Müller (appgurueu) and licensed under the MIT license; builtin Minetest media licensed under various free Creative Commons licenses as well as the Apache 2 license (see `LICENSE.txt` in the `builtin` folder for details and attribution).

The palettes are (for copyright reasons shuffled) versions of palettes available on [Lospec](https://lospec.com/):

* Adigun A. Polack's "AAP-64"
* AdamCYounis' "Apollo"
* Lexaloffle Games' "PICO-8"
* Kerrie Lake's "Resurrect 64"
* Walking's "Soggy Newspapers"
* Zughy's "Zughy 32"
