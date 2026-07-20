-- could do with some types cleanup, like time as mixed int/string below
-- no idea where ya.readable_size comes from? on their docs page here https://yazi-rs.github.io/docs/configuration/yazi/
-- but cant find it in any types pages, probs in their source somewhere

-- Linemode setup:
--   `size`    = yazi built-in, unchanged. Fast. Dirs show child count.
--   `mtime` / `btime` = ours. Show `file:size()` for files and `-` for dirs

local function format_time(time)
  time = math.floor(time or 0)
  if time == 0 then
    return ''
  end
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

require('relative-motions'):setup { show_numbers = 'relative', show_motion = true, enter_mode = 'first' }
require('git'):setup {
  -- Order of status signs showing in the linemode
  order = 1500,
}

-- Small custom keybind actions, invoked from keymap.toml via yazi's inline `lua`
-- action (see the `CustomPlugins.*` bindings there). Keeping them here as a global
-- table instead of separate plugin packages removes the per-plugin `plugins/*.yazi`
-- dirs and their `install.conf.yaml` symlinks.
--
-- Inline `lua` runs SYNCHRONOUSLY, so:
--   * sync fns (only `cx` + `ya.emit`) are called directly:
--       lua 'CustomPlugins.first_file()'
--   * fns using a yielding API (`ya.clipboard`, `ya.input`) must be handed to the
--     runtime with `ya.async`, else they error "attempt to yield from outside a
--     coroutine". `cx` isn't reachable from the async task, so we read it in the
--     sync part and pass the values in:
--       lua 'ya.async(CustomPlugins.copy_path, CustomPlugins.gather_paths()) return'
--     The trailing `return` discards ya.async's task handle (unserialisable → the
--     dispatcher would otherwise log a "Call dispatch error" on every press).
CustomPlugins = {}

-- first-file: move the cursor to the first non-directory in the current dir. Sync.
function CustomPlugins.first_file()
  local tab = cx.active
  local files = tab.current.files
  for i = 1, #files do
    local file = files[i]
    if file and not file.cha.is_dir then
      -- lua is 1-indexed; yazi's `arrow` moves relative to the current cursor
      ya.emit('arrow', { (i - 1) - tab.current.cursor })
      return
    end
  end
end

-- copy-path: collect the plain filesystem path(s) of the selected/hovered file(s).
-- Reads `url.path` (not the Url) so it's correct inside `search://` views too.
-- Runs in the sync context, so it can touch `cx` directly.
function CustomPlugins.gather_paths()
  local tab, paths = cx.active, {}
  for _, url in pairs(tab.selected) do
    paths[#paths + 1] = tostring(url.path)
  end
  if #paths == 0 and tab.current.hovered then
    paths[1] = tostring(tab.current.hovered.url.path)
  end
  return paths
end

-- copy-path (async half): write the gathered paths to the clipboard. `ya.clipboard`
-- yields, so this must run under `ya.async`.
function CustomPlugins.copy_path(paths)
  if not paths or #paths == 0 then
    return ya.notify { title = 'Copy path', content = 'No file selected', level = 'warn', timeout = 5 }
  end
  ya.clipboard(table.concat(paths, '\n'))
  local msg = #paths == 1 and paths[1] or (#paths .. ' paths')
  ya.notify { title = 'Copy path', content = 'Copied: ' .. msg, level = 'info', timeout = 5 }
end

-- open-with-cmd: prompt for a command and run it (blocking) against the current
-- file(s). `ya.input` yields, so this must run under `ya.async`.
function CustomPlugins.open_with_cmd()
  local value, event = ya.input {
    title = 'Open with:',
    pos = { 'hovered', y = 1, w = 50 },
  }
  if event ~= 1 then
    return
  end
  local suffix = ya.target_family() == 'windows' and ' %*' or ' "$@"'
  ya.emit('shell', { value .. suffix, block = true, orphan = false })
end
