local insecure_env, http, schema = ...

local settingtypes_path = modlib.mod.get_resource"settingtypes.txt"

local palettes_path = modlib.mod.get_resource"palettes"

local function write_file(path, content, text)
	local file = insecure_env.io.open(path, text and "w" or "wb")
	file:write(content)
	file:close()
end

minetest.register_chatcommand("download_palette", {
	params = "<url>",
	description = "Download a palette to use for generating textures",
	privs = {server = true},
	func = function(name, url)
		local palette_name = url:match"/([A-Za-z0-9-_]+)%.png$"
		if not (url:match"^https://" and palette_name) then
			return false, "URL must be a valid HTTPS URL with a filename consisting of ASCII letters, digits, hyphens and underscores and ending in a .png extension." -- luacheck: ignore
		end
		http.fetch({
			url = url,
			method = "GET"
		}, function(res)
			local failure = (res.timeout and "Timeout") or (not res.succeeded and ("HTTP Status Code %d"):format(res.code))
			if failure then
				minetest.chat_send_player(name, ("Downloading from URL %s failed: %s"):format(url, failure))
				return
			end
			local stream = modlib.text.inputstream(res.data)
			local status, res_or_err = pcall(modlib.minetest.decode_png, stream)
			if stream:read(1) then
				status, res_or_err = false, "EOF expected"
			end
			if status then
				-- Rewrite & store PNG
				local png = res_or_err
				modlib.minetest.convert_png_to_argb8(png)
				modlib.table.shuffle(png.data) -- for copyright reasons
				write_file(modlib.file.concat_path{palettes_path, palette_name .. ".png"},
					modlib.minetest.encode_png(png.width, png.height, png.data))
				-- Update schema
				schema.entries.palette.entries.name.values[palette_name] = true
				write_file(settingtypes_path, schema:generate_settingtypes(), true)

				minetest.chat_send_player(name, ("Palette %s added to palettes!"):format(palette_name))
			else
				minetest.chat_send_player(name, ("PNG image from URL %s is invalid: %s"):format(url, res_or_err))
			end
		end)
	end
})
