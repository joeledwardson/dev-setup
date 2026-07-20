--- @since 25.5.31
-- copy-path: copy the plain filesystem path of the selected/hovered file(s).
--
-- Yazi's default `copy path` yanks the file's full Url. Inside a search view
-- (fd/rg) the cwd uses the `search://` scheme, so that yank comes out as e.g.
--   search://tmux-cpu:4:4//home/joel/.config/tmux/plugins/tmux-cpu
-- We read `url.path` instead, which is the documented Path portion of the Url
-- (`/home/joel/...`) with no scheme/domain, so it's correct in both normal and
-- search views without any string surgery.

local selected_or_hovered = ya.sync(function(_)
	local tab, paths = cx.active, {}
	for _, url in pairs(tab.selected) do
		paths[#paths + 1] = tostring(url.path)
	end
	if #paths == 0 and tab.current.hovered then
		paths[1] = tostring(tab.current.hovered.url.path)
	end
	return paths
end)

return {
	entry = function()
		local paths = selected_or_hovered()
		if #paths == 0 then
			return ya.notify({ title = "Copy path", content = "No file selected", level = "warn", timeout = 5 })
		end

		ya.clipboard(table.concat(paths, "\n"))

		local msg = #paths == 1 and paths[1] or (#paths .. " paths")
		ya.notify({ title = "Copy path", content = "Copied: " .. msg, level = "info", timeout = 5 })
	end,
}
