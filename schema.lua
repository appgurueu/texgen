local palettes = {}
for _, filename in ipairs(minetest.get_dir_list(modlib.mod.get_resource"palettes", false)) do
	local palette = filename:match"(.+)%.png$"
	if palette then palettes[palette] = true end
end
return {
	type = "table",
	entries = {
		palette = {
			type = "table",
			entries = {
				name = {
					type = "string",
					description = "Name of the palette to use (without extension)",
					values = palettes,
					default = "apollo"
				},
				dithering = {
					type = "string",
					description = "Dithering method to use",
					values = texgen.dithering_methods,
					default = "floyd_steinberg"
				}
			}
		},
		saturate = {
			type = "number",
			description = "Increase or decrease saturation by a factor",
			range = {min = 0.1, max = 10},
			default = 1
		},
		monochrome = {
			type = "boolean",
			description = "Convert RGB to monochrome (greyscale)",
			default = false
		},
		invert = {
			type = "boolean",
			description = "Invert the RGB colors",
			default = false
		},
		average = {
			type = "boolean",
			description = "Replace each texture with a single pixel of its weighted average RGB color",
			default = false,
		}
	}
}
