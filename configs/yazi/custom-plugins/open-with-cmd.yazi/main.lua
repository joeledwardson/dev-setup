return {
  entry = function()
    local value, event = ya.input {
      title = 'Open with:',
      pos = { 'hovered', y = 1, w = 50 },
    }

    if event == 1 then
      local s = ya.target_family() == 'windows' and ' %*' or ' "$@"'
      local cmd = value .. s
      ya.err('open-with-cmd: running: ' .. cmd .. ' block=' .. tostring(block))
      -- slightly confusing.. https://yazi-rs.github.io/docs/configuration/keymap/#mgr.shell
      -- yazi emit is an "action" which is actually yazi defined stuff in the `keymap.toml` file - so `shell` is referring to the `shell` from keymap (see link above)
      ya.emit('shell', {
        cmd,
        -- open in a blocking manner (can't see a situation where would want to a file NOT in a blocking manner?)
        block = true,
        -- dont want process open after finish
        orphan = false,
      })
    else
      ya.err('open-with-cmd: cancelled, event=' .. tostring(event))
    end
  end,
}
