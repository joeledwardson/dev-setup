--- @since 26.0.0
---
--- folder-size.yazi — eager fetcher: `du -sb` per directory on enumeration,
--- result stashed in `_G.YAZI_FOLDER_SIZE_CACHE` for `Linemode:dirsize` to read.
---
--- Built-in `size` linemode is left untouched (fast, child-count for dirs).
--- Switch to `dirsize` linemode (keymap `,d`) to see the recursive bytes.
---
--- Registered as a fetcher with `url = "*/"` so it only fires on dirs.

local set_cache = ya.sync(function(_, url, bytes)
  _G.YAZI_FOLDER_SIZE_CACHE = _G.YAZI_FOLDER_SIZE_CACHE or {}
  _G.YAZI_FOLDER_SIZE_CACHE[url] = bytes
end)

---@type UnstableFetcher
-- (alias lives in folder-size.yazi/types.lua, mirroring git.yazi's pattern)
local function fetch(_, job)
  for _, file in ipairs(job.files) do
    if file.cha.is_dir then
      local url = tostring(file.url)
      local out = Command('du'):arg({ '-sb', '--', url }):output()
      if out and out.status and out.status.success then
        local n = tonumber(tostring(out.stdout):match '^(%d+)')
        if n then set_cache(url, n) end
      end
    end
  end
  return false
end

return { fetch = fetch }
