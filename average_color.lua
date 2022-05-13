-- Average color, weighted by alpha and calculated in linear RGB colorspace
return function(png)
	-- TODO make colorspecs extend vectors
	local avg_color = modlib.vector.new{r = 0, g = 0, b = 0}
	local total_alpha = 0
	for _, color in ipairs(png.data) do
		color = modlib.minetest.colorspec.from_number(color)
		-- Squared average
		avg_color = modlib.vector.add(avg_color, modlib.vector.multiply_scalar(
			modlib.vector.pow_scalar({r = color.r, g = color.g, b = color.b}, 2), color.a))
		total_alpha = total_alpha + color.a
	end
	if total_alpha == 0 then total_alpha = 1 end -- Avoid division by zero
	-- Round & convert back to colorspec
	avg_color = modlib.minetest.colorspec.new(avg_color:divide_scalar(total_alpha)
		:apply(math.sqrt):add_scalar(0.5):floor())
	return avg_color
end
