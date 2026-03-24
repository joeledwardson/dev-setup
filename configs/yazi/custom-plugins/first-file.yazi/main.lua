--- @sync entry

-- custom function to iterate through items and go to first file (if found)
local function entry()
  local tab = cx.active
  local files = tab.current.files
  for i = 1, #files do
    local file = files[i]
    if file and not file.cha.is_dir then
      -- lua is 1 index convert to 0 index for yazi
      -- arrow event moves cursor down: https://yazi-rs.github.io/docs/configuration/keymap/#mgr.arrow
      ya.emit('arrow', { (i - 1) - tab.current.cursor })
      return
    end
  end
end

return { entry = entry }
