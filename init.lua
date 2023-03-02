local modname = "texgen"
local modpath = minetest.get_modpath(modname)

-- Rewrite mod.conf on startup; register_on_mods_loaded does not work
do
	local conf = Settings(modpath .. "/mod.conf")
	conf:set("name", modname)
	conf:set("description", "Dynamically generated texture packs")
	conf:set("depends", "modlib")
	local to_depend = {}
	local to_dep_list = {}
	for _, modname in pairs(minetest.get_modnames()) do to_depend[modname] = true end -- luacheck: ignore
	local opt_dep_str = conf:get"optional_depends" or ""
	for opt_depend in opt_dep_str:gmatch"[^%s,]+" do
		table.insert(to_dep_list, opt_depend)
		to_depend[opt_depend] = nil
	end
	to_depend.texgen = nil -- no circular dependency
	to_depend.modlib = nil -- modlib is already a hard dependency
	if next(to_depend) or not modlib then
		for dep in pairs(to_depend) do table.insert(to_dep_list, dep) end
		conf:set("optional_depends", table.concat(to_dep_list, ", "))
		conf:write()
		error"mod.conf updated to optionally depend on all enabled mods, please restart the game"
	end
end

assert(modlib.version >= 96, "update modlib to version rolling-96 or newer")

local texture_path = modpath .. "/textures/"
if minetest.rmdir then
	-- Clear texture directory on startup
	minetest.rmdir(texture_path, true)
end
minetest.mkdir(texture_path)

local media = modlib.minetest.media

local function get_path(filename)
	local path
	local mod = media.mods[filename]
	if mod == modname then -- media overridden by this mod
		local overridden_paths = media.overridden_paths[filename]
		if not overridden_paths then return end
		path = overridden_paths[#overridden_paths]
	else
		path = media.paths[filename]
	end
	return path
end

texgen = {} -- HACK only use the mod namespace to expose the dithering methods to the schema...

local dithering = modlib.mod.include"dithering.lua" -- sets texgen.dithering_methods

local conf, schema = modlib.mod.configuration()

-- Register palette downloading command if HTTP API is available; this reloads the schema
local insecure_env, http = minetest.request_insecure_environment(), minetest.request_http_api()
if insecure_env and http then
	assert(loadfile(modlib.mod.get_resource"download_palette.lua"))(insecure_env, http, schema)
end

texgen = nil -- ...delete it afterwards

local palette, dither
if conf.palette.name then
	palette = modlib.mod.include"palette.lua"(conf.palette.name)
	dither = dithering(conf.palette.dithering)
end
local saturate, monochrome, invert = conf.saturate, conf.monochrome, conf.invert
local average
if conf.average then
	average = modlib.mod.include"average_color.lua"
end

local function read_convert_png(path)
	local file = assert(io.open(path, "rb"))
	local png = modlib.minetest.decode_png(file)
	assert(not file:read(1), "EOF expected")
	file:close()
	modlib.minetest.convert_png_to_argb8(png)
	return png
end

local clamp = modlib.math.clamp
local function transform_png(filename, path)
	local png = read_convert_png(path)
	if palette then
		dither(png, palette)
	end
	modlib.table.map(png.data, function(color_num)
		local color = modlib.minetest.colorspec.from_number(color_num)
		if saturate ~= 1 then
			-- See https://alienryderflex.com/saturation.html
			local P = math.sqrt(0.299 * color.r^2 + 0.587 * color.g^2 + 0.114 * color.b^2)
			local res = modlib.vector.apply({
				r = clamp((color.r - P) * saturate + P + 0.5, 0, 255),
				g = clamp((color.g - P) * saturate + P + 0.5, 0, 255),
				b = clamp((color.b - P) * saturate + P + 0.5, 0, 255),
			}, math.floor)
			color.r, color.g, color.b = res.r, res.g, res.b
		end
		if invert then
			color.r, color.g, color.b = 255 - color.r, 255 - color.g, 255 - color.b
		end
		if monochrome then
			local brightness = math.floor(0.299 * color.r + 0.587 * color.g + 0.114 * color.b + 0.5)
			color.r, color.g, color.b = brightness, brightness, brightness
		end
		return color:to_number()
	end)
	local width, height, data = png.width, png.height, png.data
	if average then
		width, height, data = 1, 1, {average(png):to_number()}
	end
	modlib.file.write(modlib.file.concat_path{modpath, "textures", filename},
		modlib.minetest.encode_png(width, height, data))
end

for filename in pairs(media.paths) do
	local _, ext = modlib.file.get_extension(filename)
	if ext == "png" then
		local path = get_path(filename)
		-- May be (only) overridden media from this mod, which does not have a path (as it was deleted)
		if path then transform_png(filename, path) end
	end
end
-- Builtin textures aren't provided by mods and are thus unknown to modlib; provide them through this mod
for _, filename in ipairs(minetest.get_dir_list(modlib.file.concat_path{modpath, "minetest"}, false)) do
	-- Don't override builtin overrides by other mods
	if filename:match"%.png$" and not (media.paths[filename] and media.overridden_paths[filename]) then
		transform_png(filename, modlib.file.concat_path{modpath, "minetest", filename})
	end
end
