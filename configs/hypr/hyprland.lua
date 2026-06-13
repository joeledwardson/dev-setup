-- Hyprland 0.55+ Lua config
---@module 'hl'

local HOME = os.getenv 'HOME'

--###############
--## MONITORS ###
--###############

hl.monitor {
  output = '',
  mode = 'preferred',
  position = 'auto',
  scale = 'auto',
}

--### VARIABLES ###

local terminal = 'kitty'
local fileManager = 'dolphin'
local menu = 'fuzzel'
local active_colour = { colors = { 'rgba(b5e853ee)', 'rgba(b5e853ee)' }, angle = 45 }
local groupbar_active_colour = 'rgba(b5e853ff)'
-- string form of active_colour, for set_prop (which only accepts strings)
local active_colour_str = table.concat(active_colour.colors, ' ') .. ' ' .. active_colour.angle .. 'deg'
local flash_colour = 'rgba(ff0000ff)'
local mainMod = 'SUPER'
local resizeStep = 40

--#####################
--## ENVIRONMENT VARS ##
--#####################

hl.env('XCURSOR_SIZE', 24)
hl.env('HYPRCURSOR_SIZE', 24)
hl.env('ELECTRON_OZONE_PLATFORM_HINT', 'auto')
hl.env('GTK_THEME', 'Tokyonight-Dark')
hl.env('GDK_SCALE', 1)

-- Mitigations for NVIDIA 595.x Wayland freeze/segfault regression.
-- Hardware cursors and direct scanout are two Nvidia/Wayland interaction
-- points that break under this driver series.
hl.env('WLR_NO_HARDWARE_CURSORS', 1)
hl.env('HYPRLAND_NO_DIRECT_SCANOUT', 1)

--##################
--## PERMISSIONS ###
--##################

hl.config {
  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },
}

--####################
--## LOOK AND FEEL ###
--####################

hl.config {
  general = {
    gaps_in = 5,
    gaps_out = 20,
    border_size = 5,
    ['col.active_border'] = active_colour,
    ['col.inactive_border'] = 'rgba(595959aa)',
    resize_on_border = false,
    allow_tearing = false,
    layout = 'dwindle',
    no_focus_fallback = true,
  },
}

hl.config {
  decoration = {
    rounding = 10,
    rounding_power = 2,
    active_opacity = 1.0,
    inactive_opacity = 0.9,
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = 'rgba(1a1a1aee)',
    },
    blur = {
      enabled = true,
      size = 3,
      passes = 1,
      vibrancy = 0.1696,
    },
  },
}

hl.config {
  animations = {
    enabled = true,
    bezier = {
      'easeOutQuint,0.23,1,0.32,1',
      'easeInOutCubic,0.65,0.05,0.36,1',
      'linear,0,0,1,1',
      'almostLinear,0.5,0.5,0.75,1.0',
      'quick,0.15,0,0.1,1',
    },
    animation = {
      'global, 1, 10, default',
      'border, 1, 5.39, easeOutQuint',
      'windows, 1, 4.79, easeOutQuint',
      'windowsIn, 1, 4.1, easeOutQuint, popin 87%',
      'windowsOut, 1, 1.49, linear, popin 87%',
      'fadeIn, 1, 1.73, almostLinear',
      'fadeOut, 1, 1.46, almostLinear',
      'fade, 1, 3.03, quick',
      'layers, 1, 3.81, easeOutQuint',
      'layersIn, 1, 4, easeOutQuint, fade',
      'layersOut, 1, 1.5, linear, fade',
      'fadeLayersIn, 1, 1.79, almostLinear',
      'fadeLayersOut, 1, 1.39, almostLinear',
      'workspaces, 1, 1.94, almostLinear, fade',
      'workspacesIn, 1, 1.21, almostLinear, fade',
      'workspacesOut, 1, 1.94, almostLinear, fade',
    },
  },
}

hl.config {
  dwindle = {
    preserve_split = true,
  },
}

hl.config {
  master = {
    new_status = 'master',
  },
}

hl.config {
  group = {
    ['col.border_active'] = active_colour,
    ['col.border_inactive'] = 'rgba(595959aa)',
    ['col.border_locked_active'] = { colors = { 'rgba(ff5555ee)', 'rgba(ff5555ee)' }, angle = 45 },
    ['col.border_locked_inactive'] = 'rgba(595959aa)',
    groupbar = {
      enabled = true,
      gradients = true,
      height = 16,
      indicator_height = 3,
      font_family = 'SpaceMono Nerd Font',
      font_size = 14,
      font_weight_active = 'bold',
      text_color = 'rgba(1a1a1aff)',
      text_color_inactive = 'rgba(ffffffff)',
      ['col.active'] = groupbar_active_colour,
      ['col.inactive'] = 'rgba(595959ff)',
      ['col.locked_active'] = 'rgba(ff5555ff)',
      ['col.locked_inactive'] = 'rgba(595959ff)',
    },
  },
}

hl.config {
  misc = {
    force_default_wallpaper = -1,
    disable_hyprland_logo = false,
  },
}

hl.config {
  binds = {
    movefocus_cycles_fullscreen = false,
    window_direction_monitor_fallback = true,
  },
}

--############
--## INPUT ###
--############

hl.config {
  input = {
    kb_layout = 'gb',
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = true,
    },
  },
}

hl.config {
  gestures = {},
}

-- device per-input config not supported in hl.config in 0.55

--##################
--## KEYBINDINGS ###
--##################

hl.bind(mainMod .. '+Return', hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. '+Q', hl.dsp.window.close())
hl.bind(mainMod .. '+SHIFT+Q', hl.dsp.exec_cmd(HOME .. '/.config/hypr/scripts/confirm-exit.sh'))
hl.bind(mainMod .. '+E', hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. '+SHIFT+E', hl.dsp.exec_cmd(terminal .. ' yazi'))
hl.bind(
  mainMod .. '+SHIFT+T',
  hl.dsp.exec_cmd "hyprctl activewindow -j | jq -e '.floating' && hyprctl dispatch cyclenext tiled || hyprctl dispatch cyclenext floating"
)
hl.bind(
  mainMod .. '+O',
  hl.dsp.exec_cmd 'hyprctl -j getoption decoration:inactive_opacity | jq -e ".float > 0.5" && hyprctl keyword decoration:inactive_opacity 0.5 || hyprctl keyword decoration:inactive_opacity 1.0'
)
hl.bind(mainMod .. '+T', hl.dsp.window.float())
hl.bind(mainMod .. '+F', hl.dsp.window.fullscreen())
hl.bind(mainMod .. '+V', hl.dsp.exec_cmd 'cliphist list | fuzzel --dmenu | cliphist decode | wl-copy')
hl.bind(mainMod .. '+space', hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. '+backspace', hl.dsp.exec_cmd(HOME .. '/.config/hypr/scripts/shutdown.sh'))
hl.bind(mainMod .. '+I', hl.dsp.layout 'togglesplit')
hl.bind(mainMod .. '+SHIFT+X', hl.dsp.exec_cmd 'hyprshot -m active -m window --clipboard-only')
hl.bind(mainMod .. '+X', hl.dsp.exec_cmd(HOME .. '/.config/hypr/scripts/screenshot.sh'))
hl.bind(mainMod .. '+R', hl.dsp.exec_cmd "hyprctl reload && notify-send Hyprland 'Reloaded successfully' || notify-send Hyprland 'Reload failed'")
hl.bind('CTRL+ALT+L', hl.dsp.exec_cmd 'swaylock -f')
hl.bind(mainMod .. '+C', hl.dsp.exec_cmd 'swaync-client --close-all')
hl.bind(mainMod .. '+ALT+n', hl.dsp.exec_cmd 'hyprctl dispatch swapnext')
hl.bind(mainMod .. '+TAB', hl.dsp.window.cycle_next())
hl.bind(mainMod .. '+ALT+m', hl.dsp.exec_cmd(HOME .. '/.config/hypr/scripts/window-menu.sh'))
hl.bind(mainMod .. '+slash', hl.dsp.exec_cmd 'rofimoji --action clipboard')

-- Move focus
hl.bind(mainMod .. '+h', hl.dsp.exec_cmd(HOME .. '/.config/hypr/scripts/move-focus.sh l'))
hl.bind(mainMod .. '+l', hl.dsp.exec_cmd(HOME .. '/.config/hypr/scripts/move-focus.sh r'))
hl.bind(mainMod .. '+k', hl.dsp.exec_cmd(HOME .. '/.config/hypr/scripts/move-focus.sh u'))
hl.bind(mainMod .. '+j', hl.dsp.exec_cmd(HOME .. '/.config/hypr/scripts/move-focus.sh d'))

-- Move windows
hl.bind(mainMod .. '+ALT+h', hl.dsp.window.move { direction = 'l' })
hl.bind(mainMod .. '+ALT+l', hl.dsp.window.move { direction = 'r' })
hl.bind(mainMod .. '+ALT+k', hl.dsp.window.move { direction = 'u' })
hl.bind(mainMod .. '+ALT+j', hl.dsp.window.move { direction = 'd' })

-- Groups
hl.bind(mainMod .. '+G', hl.dsp.group.toggle())
hl.bind(mainMod .. '+SHIFT+G', hl.dsp.group.lock_active())
hl.bind(mainMod .. '+P', hl.dsp.group.prev())
hl.bind(mainMod .. '+N', hl.dsp.group.next())
hl.bind(mainMod .. '+SHIFT+P', hl.dsp.group.move_window { forward = false })
hl.bind(mainMod .. '+SHIFT+N', hl.dsp.group.move_window { forward = true })
-- group-menu.sh enters the interactive_group submap and shows the hotkey menu
hl.bind(mainMod .. '+ALT+G', hl.dsp.exec_cmd(HOME .. '/.config/hypr/scripts/group-menu.sh'))

-- Rename current workspace
hl.bind(
  mainMod .. '+SHIFT+R',
  hl.dsp.exec_cmd 'name=$(fuzzel --dmenu --prompt \'rename workspace: \') && [ -n "$name" ] && hyprctl dispatch renameworkspace "$(hyprctl activeworkspace -j | jq -r .id)" "$name"'
)

-- Workspace switching
hl.bind(mainMod .. '+ALT+bracketleft', hl.dsp.window.move { workspace = 'r-1' })
hl.bind(mainMod .. '+ALT+bracketright', hl.dsp.window.move { workspace = 'r+1' })
hl.bind(mainMod .. '+bracketleft', hl.dsp.exec_cmd(HOME .. '/.config/hypr/scripts/move-workspace.sh r-1'))
hl.bind(mainMod .. '+bracketright', hl.dsp.exec_cmd(HOME .. '/.config/hypr/scripts/move-workspace.sh r+1'))

for i = 1, 9 do
  hl.bind(mainMod .. '+' .. i, hl.dsp.focus { workspace = i })
  hl.bind(mainMod .. '+SHIFT+' .. i, hl.dsp.exec_cmd('hyprctl dispatch movetoworkspace ' .. i))
end
hl.bind(mainMod .. '+0', hl.dsp.focus { workspace = 10 })
hl.bind(mainMod .. '+SHIFT+0', hl.dsp.exec_cmd 'hyprctl dispatch movetoworkspace 10')

-- Special workspace
hl.bind(mainMod .. '+S', hl.dsp.workspace.toggle_special 'magic')
hl.bind(mainMod .. '+SHIFT+S', hl.dsp.exec_cmd(HOME .. '/.config/hypr/scripts/toggle-special.sh'))

-- Scroll workspaces
hl.bind(mainMod .. '+mouse_down', hl.dsp.focus { workspace = 'e+1' })
hl.bind(mainMod .. '+mouse_up', hl.dsp.focus { workspace = 'e-1' })

-- Mouse drag/resize
hl.bind(mainMod .. '+mouse:272', hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. '+mouse:273', hl.dsp.window.resize(), { mouse = true })

-- Resize with hjkl
hl.bind(mainMod .. '+SHIFT+h', hl.dsp.window.resize { x = -resizeStep, y = 0, relative = true }, { repeating = true })
hl.bind(mainMod .. '+SHIFT+l', hl.dsp.window.resize { x = resizeStep, y = 0, relative = true }, { repeating = true })
hl.bind(mainMod .. '+SHIFT+k', hl.dsp.window.resize { x = 0, y = -resizeStep, relative = true }, { repeating = true })
hl.bind(mainMod .. '+SHIFT+j', hl.dsp.window.resize { x = 0, y = resizeStep, relative = true }, { repeating = true })

-- Media / volume (locked = works on lockscreen)
hl.bind('XF86AudioRaiseVolume', hl.dsp.exec_cmd 'swayosd-client --output-volume raise', { locked = true })
hl.bind('XF86AudioLowerVolume', hl.dsp.exec_cmd 'swayosd-client --output-volume lower', { locked = true })
hl.bind('XF86AudioMute', hl.dsp.exec_cmd 'swayosd-client --output-volume mute-toggle', { locked = true })
hl.bind('XF86AudioMicMute', hl.dsp.exec_cmd 'swayosd-client --input-volume mute-toggle', { locked = true })
hl.bind('XF86MonBrightnessUp', hl.dsp.exec_cmd 'swayosd-client --brightness raise', { locked = true })
hl.bind('XF86MonBrightnessDown', hl.dsp.exec_cmd 'swayosd-client --brightness lower', { locked = true })
hl.bind('XF86AudioNext', hl.dsp.exec_cmd 'playerctl next', { locked = true })
hl.bind('XF86AudioPause', hl.dsp.exec_cmd 'playerctl play-pause', { locked = true })
hl.bind('XF86AudioPlay', hl.dsp.exec_cmd 'playerctl play-pause', { locked = true })
hl.bind('XF86AudioPrev', hl.dsp.exec_cmd 'playerctl previous', { locked = true })

--#############################
--## WINDOWS AND WORKSPACES ###
--#############################

hl.window_rule {
  name = 'suppress-maximize',
  match = { class = '.*' },
  suppress_event = 'maximize',
}

hl.window_rule {
  name = 'xwayland-drag-fix',
  match = { class = '^$', title = '^$', xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true,
}

--## BORDER FLASH ##
-- Briefly flash the active window's border red, then restore. Global so shell
-- scripts can trigger it via `hyprctl eval "FlashActiveBorder()"` — used by
-- move-focus.sh/move-workspace.sh on a failed move and by the tmux nav binds.
-- Restore colour is derived from active_colour above — one source of truth.
-- hl.timer does the delay so nothing blocks. The real trigger (failed focus)
-- leaves the active window unchanged, so restoring the active window is correct.
function FlashActiveBorder()
  if not hl.get_active_window() then return end
  hl.dispatch(hl.dsp.window.set_prop { prop = 'active_border_color', value = flash_colour })
  hl.timer(function()
    if hl.get_active_window() then
      hl.dispatch(hl.dsp.window.set_prop { prop = 'active_border_color', value = active_colour_str })
    end
  end, { timeout = 300, type = 'oneshot' })
end

--## SUBMAP: group mode ##
-- Entered via group-menu.sh (SUPER+ALT+G), persistent until escape/q.
-- Borders turn purple while the mode is active, restored on exit.
-- Note: `hyprctl keyword` is rejected under the lua config, and runtime
-- hl.config changes don't repaint the focused window until its focus state
-- changes — the per-window active_border_color prop does repaint immediately,
-- so every colour change also pokes the active window with set_prop.

local group_mode_colour = 'rgba(c678ddff)'

local function apply_border_colours(gradient, groupbar_colour, prop_value)
  hl.config {
    general = { ['col.active_border'] = gradient },
    group = {
      ['col.border_active'] = gradient,
      groupbar = { ['col.active'] = groupbar_colour },
    },
  }
  if hl.get_active_window() then
    hl.dispatch(hl.dsp.window.set_prop { prop = 'active_border_color', value = prop_value })
  end
end

hl.on('keybinds.submap', function(name)
  if name == 'interactive_group' then
    apply_border_colours(group_mode_colour, group_mode_colour, group_mode_colour)
  else
    apply_border_colours(active_colour, groupbar_active_colour, active_colour_str)
  end
end)

-- runs the action then re-pokes the (possibly new) active window so the
-- purple stays visible while the mode persists
local function group_action(dispatcher)
  return function()
    hl.dispatch(dispatcher)
    if hl.get_active_window() then
      hl.dispatch(hl.dsp.window.set_prop { prop = 'active_border_color', value = group_mode_colour })
    end
  end
end

hl.define_submap('interactive_group', function()
  hl.bind('t', group_action(hl.dsp.group.toggle()))
  hl.bind('SHIFT+l', group_action(hl.dsp.group.lock_active()))
  hl.bind('h', group_action(hl.dsp.window.move { into_group = 'l' }))
  hl.bind('l', group_action(hl.dsp.window.move { into_group = 'r' }))
  hl.bind('k', group_action(hl.dsp.window.move { into_group = 'u' }))
  hl.bind('j', group_action(hl.dsp.window.move { into_group = 'd' }))
  hl.bind('u', group_action(hl.dsp.window.move { out_of_group = true }))
  hl.bind('n', group_action(hl.dsp.group.next()))
  hl.bind('p', group_action(hl.dsp.group.prev()))
  hl.bind('comma', group_action(hl.dsp.group.move_window { forward = false }))
  hl.bind('period', group_action(hl.dsp.group.move_window { forward = true }))
  hl.bind('escape', hl.dsp.submap 'reset')
  hl.bind('q', hl.dsp.submap 'reset')
end)

--## AUTOSTART ##

hl.on('hyprland.start', function()
  hl.exec_cmd 'dconf write /org/gnome/desktop/interface/color-scheme "\'prefer-dark\'"'
  hl.exec_cmd 'dconf write /org/gnome/desktop/interface/gtk-theme "\'Tokyonight-Dark\'"'
  hl.exec_cmd 'dconf write /org/gnome/desktop/interface/icon-theme "\'Flat-Remix-Blue-Dark\'"'
  hl.exec_cmd 'dconf write /org/gnome/desktop/interface/document-font-name "\'SpaceMono Nerd Font Regular 11\'"'
  hl.exec_cmd 'dconf write /org/gnome/desktop/interface/font-name "\'SpaceMono Nerd Font Regular 11\'"'
  hl.exec_cmd 'dconf write /org/gnome/desktop/interface/monospace-font-name "\'SpaceMono Nerd Font Mono Regular 11\'"'
end)

hl.on('config.reloaded', function()
  -- Activate graphical-session.target so waybar/hypridle/nm-applet systemd
  -- user services start. Without UWSM this target is never activated otherwise.
  hl.exec_cmd 'systemctl --user start graphical-session.target'
  -- udiskie, hyprpaper, swayosd-server, cliphist managed by systemd user services
  hl.exec_cmd('sleep 1 && ' .. HOME .. '/.config/hypr/scripts/randomise-wallpaper.sh')
end)

-- per-machine config — falls back silently if file doesn't exist
pcall(require, 'hyprland_monitors')
pcall(require, 'hyprland_custom')
