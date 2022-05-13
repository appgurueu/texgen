local function relative_color_distance(color, other_color)
	-- See https://www.compuphase.com/cmetric.htm
	local redmean = (color.r + other_color.r) / 2
	-- Omits the square root as this only has to be relative
	return (2 + redmean/256) * (color.r-other_color.r)^2
		+ 4 * (color.g-other_color.g)^2
		+ (2 + (255 - redmean)/256) * (color.b-other_color.b)^2
end
local palettes = modlib.mod.get_resource"palettes"
return function(name)
	local path = modlib.file.concat_path{palettes, name .. ".png"}
	local file = assert(io.open(path, "rb"))
	local png = modlib.minetest.decode_png(file)
	assert(not file:read(1), "EOF expected")
	file:close()
	modlib.minetest.convert_png_to_argb8(png)
	local colors = {}
	for _, color in pairs(png.data) do
		-- TODO ignore colors with alpha 0?
		local rgb = color % 0x1000000
		colors[rgb] = true
	end
	local palette_colors = {}
	for colornum in pairs(colors) do
		table.insert(palette_colors, modlib.minetest.colorspec.from_number(colornum))
	end
	return function(color)
		-- Find closest color using a linear search; a k-d-tree can't be employed here because the metric isn't euclidean
		local closest_color = palette_colors[1]
		local closest_distance = relative_color_distance(color, closest_color)
		for i = 2, #palette_colors do
			local palette_color = palette_colors[i]
			local distance = relative_color_distance(color, palette_color)
			-- TODO deal with same distances through random choice?
			if distance < closest_distance then
				closest_color = palette_color
				closest_distance = distance
			end
		end
		return closest_color
	end
end
