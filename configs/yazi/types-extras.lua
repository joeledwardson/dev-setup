---@meta
-- Type augmentations for yazi APIs that exist at runtime but are missing from
-- the bundled types.yazi (as of v26). Loaded by lua_ls via workspace.library
-- in .luarc.json.
--
-- Submitted upstream: https://github.com/yazi-rs/plugins (PR in flight).
-- Once merged + `ya pkg upgrade`'d, this file can be deleted.

---@class ya
---@field readable_size fun(bytes: integer): string
