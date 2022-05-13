-- Simple error diffusion dithering
-- TODO use HSV/HSL for dithering closer to human perception

local matrices = {
	none = {
		fraction = 0
	},
	floyd_steinberg = {
		fraction = 1/16,
		{x_off = 1,         7};
		{x_off = -1,  3, 5, 1};
	},
	jarvis_judice_ninke = {
		fraction = 1/48,
		{x_off = 1,            7, 5};
		{x_off = -2,  3, 5, 7, 5, 3};
		{x_off = -2,  1, 3, 5, 3, 1};
	},
	stucke = {
		fraction = 1/42,
		{x_off = 1,            8, 4};
		{x_off = -2,  2, 4, 8, 4, 2};
		{x_off = -2,  1, 2, 4, 2, 1};
	},
	atkinson = {
		fraction = 1/8,
		{x_off = 1,         1, 1};
		{x_off = -1,  1, 1, 1   };
		{x_off = 0,      1      };
	},
	burkes = {
		fraction = 1/42,
		{x_off = 1,            8, 4};
		{x_off = -2,  2, 4, 8, 4, 2};
	},
	sierra = {
		fraction = 1/16,
		{x_off = 1,            4, 3};
		{x_off = -2,  1, 2, 3, 2, 1};
	},
	sierra_lite = {
		fraction = 1/4,
		{x_off = 1,         2},
		{x_off = -1,  1, 1   },
	},
	two_row_sierra = {
		fraction = 1/32,
		{x_off = 1,            5, 3},
		{x_off = -2,  2, 4, 5, 4, 2},
		{x_off = -1,     2, 3, 2   },
	},
}
texgen.dithering_methods = matrices

local clamp = modlib.math.clamp
return function(method)
	local matrix = assert(matrices[method])
	return function(png, closest_color)
		local width = png.width
		local diffused_errors = {}
		local zero_err = {r = 0, g = 0, b = 0}
		for index, color in ipairs(png.data) do
			local x, y = (index - 1) % width, math.floor((index - 1) / width)
			color = modlib.minetest.colorspec.from_number(color)
			local diff_err = diffused_errors[index] or zero_err
			diffused_errors[index] = nil
			local col_err = {
				r = clamp(color.r + diff_err.r, 0, 255),
				g = clamp(color.g + diff_err.g, 0, 255),
				b = clamp(color.b + diff_err.b, 0, 255)
			}
			local new_color = closest_color(col_err)
			png.data[index] = modlib.minetest.colorspec.new{
				r = new_color.r,
				g = new_color.g,
				b = new_color.b,
				a = color.a -- keep alpha
			}:to_number()
			-- Diffuse error
			local weight = matrix.fraction * color.a / 255
			if weight > 0 then
				local err = {
					r = weight * (new_color.r - col_err.r),
					g = weight * (new_color.g - col_err.g),
					b = weight * (new_color.b - col_err.b)
				}
				for y_off, row in ipairs(matrix) do
					local ey = y + y_off - 1
					for x_off, factor in ipairs(row) do
						local ex = x + row.x_off + x_off - 1
						local idx = ey * width + ex
						local derr = diffused_errors[idx] or {r = 0, g = 0, b = 0}
						derr.r = derr.r + factor * err.r
						derr.g = derr.g + factor * err.g
						derr.b = derr.b + factor * err.b
						diffused_errors[idx] = derr
					end
				end
			end
		end
	end
end
