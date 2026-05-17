-- could do with some types cleanup, like time as mixed int/string below
-- no idea where ya.readable_size comes from? on their docs page here https://yazi-rs.github.io/docs/configuration/yazi/
-- but cant find it in any types pages, probs in their source somewhere

-- Linemode setup:
--   `size`     = yazi built-in, unchanged. Fast. Dirs show child count.
--   `dirsize`  = ours. Recursive bytes via the folder-size fetcher's `du -sb`
--                (custom-plugins/folder-size.yazi). Cache: _G.YAZI_FOLDER_SIZE_CACHE.
--   `mtime` / `btime` = ours. Show `file:size()` for files and `-` for dirs
--                — strict size view, no recursive fallback. Use `dirsize` for that.

local function format_time(time)
  time = math.floor(time or 0)
  if time == 0 then return '' end
  if os.date('%Y', time) == os.date '%Y' then
    return os.date('%b %d %H:%M', time)
  end
  return os.date('%b %d  %Y', time)
end

function Linemode:mtime()
  local n = self._file:size()
  return string.format('%s %s', n and ya.readable_size(n) or '-', format_time(self._file.cha.mtime))
end

function Linemode:btime()
  local n = self._file:size()
  return string.format('%s %s', n and ya.readable_size(n) or '-', format_time(self._file.cha.btime))
end

function Linemode:dirsize()
  local n = self._file:size()
  if n then return ya.readable_size(n) end
  local cache = _G.YAZI_FOLDER_SIZE_CACHE
  local cached = cache and cache[tostring(self._file.url)]
  return cached and ya.readable_size(cached) or '…'
end
require('projects'):setup {
  save = {
    method = 'yazi', -- yazi | lua
    yazi_load_event = '@projects-load', -- event name when loading projects in `yazi` method
    lua_save_path = '', -- path of saved file in `lua` method, comment out or assign explicitly
    -- default value:
    -- windows: "%APPDATA%/yazi/state/projects.json"
    -- unix: "~/.local/state/yazi/projects.json"
  },
  last = {
    update_after_save = true,
    update_after_load = true,
    load_after_start = false,
  },
  merge = {
    event = 'projects-merge',
    quit_after_merge = false,
  },
  event = {
    save = {
      enable = true,
      name = 'project-saved',
    },
    load = {
      enable = true,
      name = 'project-loaded',
    },
    delete = {
      enable = true,
      name = 'project-deleted',
    },
    delete_all = {
      enable = true,
      name = 'project-deleted-all',
    },
    merge = {
      enable = true,
      name = 'project-merged',
    },
  },
  notify = {
    enable = true,
    title = 'Projects',
    timeout = 3,
    level = 'info',
  },
}

-- You can configure your bookmarks by lua language
local bookmarks = {}

local path_sep = package.config:sub(1, 1)
local home_path = ya.target_family() == 'windows' and os.getenv 'USERPROFILE' or os.getenv 'HOME'
if ya.target_family() == 'windows' then
  table.insert(bookmarks, {
    tag = 'Scoop Local',

    path = (os.getenv 'SCOOP' or home_path .. '\\scoop') .. '\\',
    key = 'p',
  })
  table.insert(bookmarks, {
    tag = 'Scoop Global',
    path = (os.getenv 'SCOOP_GLOBAL' or 'C:\\ProgramData\\scoop') .. '\\',
    key = 'P',
  })
end
table.insert(bookmarks, {
  tag = 'Desktop',
  path = home_path .. path_sep .. 'Desktop' .. path_sep,
  key = 'd',
})

require('yamb'):setup {
  -- Optional, the path ending with path seperator represents folder.
  bookmarks = bookmarks,
  -- Optional, recieve notification everytime you jump.
  jump_notify = true,
  -- Optional, the cli of fzf.
  cli = 'fzf',
  -- Optional, a string used for randomly generating keys, where the preceding characters have higher priority.
  keys = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
  -- Optional, the path of bookmarks
  path = (ya.target_family() == 'windows' and os.getenv 'APPDATA' .. '\\yazi\\config\\bookmark') or (os.getenv 'HOME' .. '/.config/yazi/bookmark'),
}

-- ~/.config/yazi/init.lua
require('relative-motions'):setup { show_numbers = 'relative', show_motion = true, enter_mode = 'first' }
