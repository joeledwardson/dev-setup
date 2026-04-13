--- @since 25.5.31
-- Copy selected (or hovered) file(s) to clipboard:
--   * single image  → copy raw image bytes (paste into chat / paint apps)
--   * anything else → copy file:// URI list (paste into file managers)

-- ya.sync runs in sync context where `cx` is available
local get_paths = ya.sync(function()
	local tab = cx.active
	local paths = {}
	for _, url in pairs(tab.selected) do paths[#paths + 1] = tostring(url) end
	if #paths == 0 then
		local h = tab.current.hovered
		if h then paths[#paths + 1] = tostring(h.url) end
	end
	return paths
end)

local function shell_quote(s) return "'" .. s:gsub("'", "'\\''") .. "'" end

local function get_mime(path)
	local fh = io.popen("file --brief --mime-type " .. shell_quote(path))
	if not fh then return nil end
	local out = fh:read("*a")
	fh:close()
	return (out:gsub("%s+$", ""))
end

local function wl_copy(mime, data)
	local fh = io.popen("wl-copy -t " .. shell_quote(mime), "w")
	if not fh then return false end
	fh:write(data)
	fh:close()
	return true
end

return {
	entry = function()
		local paths = get_paths()
		if #paths == 0 then
			ya.notify({ title = "Clipboard", content = "No file selected or hovered", timeout = 3, level = "warn" })
			return
		end

		-- Single image → copy as image data (pasteable into chat/paint apps)
		if #paths == 1 then
			local mime = get_mime(paths[1])
			if mime and mime:find("^image/") then
				local fh = io.open(paths[1], "rb")
				if fh then
					local data = fh:read("*a")
					fh:close()
					if wl_copy(mime, data) then
						local name = paths[1]:match("[^/]+$") or paths[1]
						ya.notify({ title = "Clipboard", content = "Copied image: " .. name, timeout = 3, level = "info" })
						return
					end
				end
			end
		end

		-- Otherwise → file:// URI list (pasteable into file managers)
		local lines = {}
		for _, p in ipairs(paths) do lines[#lines + 1] = "file://" .. p end
		if not wl_copy("text/uri-list", table.concat(lines, "\n")) then return end

		local msg = #paths == 1 and (paths[1]:match("[^/]+$") or paths[1]) or (#paths .. " files")
		ya.notify({ title = "Clipboard", content = "Copied: " .. msg, timeout = 3, level = "info" })
	end,
}
