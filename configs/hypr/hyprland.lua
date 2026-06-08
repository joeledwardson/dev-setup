-- Converted from hyprland.conf for Hyprland 0.55+ Lua config
---@module 'hl'

local HOME = os.getenv 'HOME'
local ensureService = HOME .. '/.config/hypr/scripts/ensure-service.sh'

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
      ['col.active'] = 'rgba(b5e853ff)',
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
hl.bind('CTRL+ALT+L', hl.dsp.exec_cmd 'hyprlock')
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
hl.bind(mainMod .. '+SHIFT+G', hl.dsp.group.lock())
hl.bind(mainMod .. '+P', hl.dsp.group.next { forward = false })
hl.bind(mainMod .. '+N', hl.dsp.group.next())
hl.bind(mainMod .. '+SHIFT+P', hl.dsp.group.move_window { forward = false })
hl.bind(mainMod .. '+SHIFT+N', hl.dsp.group.move_window { forward = true })
hl.bind(mainMod .. '+ALT+G', hl.dsp.exec_cmd(HOME .. '/.config/hypr/scripts/group-menu.sh'))
hl.bind(mainMod .. '+ALT+G', hl.dsp.submap 'group')

-- Rename current workspace
hl.bind(
  mainMod .. '+SHIFT+R',
  hl.dsp.exec_cmd 'name=$(fuzzel --dmenu --prompt \'rename workspace: \') && [ -n "$name" ] && hyprctl dispatch renameworkspace "$(hyprctl activeworkspace -j | jq -r .id)" "$name"'
)

-- Workspace switching
hl.bind(mainMod .. '+ALT+bracketleft', hl.dsp.exec_cmd 'hyprctl dispatch movetoworkspace r-1')
hl.bind(mainMod .. '+ALT+bracketright', hl.dsp.exec_cmd 'hyprctl dispatch movetoworkspace r+1')
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
hl.bind(mainMod .. '+SHIFT+h', hl.dsp.window.resize { x = -resizeStep, y = 0, relative = true }, { repeat_ = true })
hl.bind(mainMod .. '+SHIFT+l', hl.dsp.window.resize { x = resizeStep, y = 0, relative = true }, { repeat_ = true })
hl.bind(mainMod .. '+SHIFT+k', hl.dsp.window.resize { x = 0, y = -resizeStep, relative = true }, { repeat_ = true })
hl.bind(mainMod .. '+SHIFT+j', hl.dsp.window.resize { x = 0, y = resizeStep, relative = true }, { repeat_ = true })

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

--## SUBMAP: group mode ##

hl.define_submap('group', function()
  hl.bind('T', hl.dsp.group.toggle())
  hl.bind('T', hl.dsp.submap 'reset')
  hl.bind('L', hl.dsp.exec_cmd 'hyprctl dispatch lockactivegroup toggle')
  hl.bind('L', hl.dsp.submap 'reset')
  hl.bind('h', hl.dsp.exec_cmd 'hyprctl dispatch moveintogroup l')
  hl.bind('h', hl.dsp.submap 'reset')
  hl.bind('l', hl.dsp.exec_cmd 'hyprctl dispatch moveintogroup r')
  hl.bind('l', hl.dsp.submap 'reset')
  hl.bind('k', hl.dsp.exec_cmd 'hyprctl dispatch moveintogroup u')
  hl.bind('k', hl.dsp.submap 'reset')
  hl.bind('j', hl.dsp.exec_cmd 'hyprctl dispatch moveintogroup d')
  hl.bind('j', hl.dsp.submap 'reset')
  hl.bind('U', hl.dsp.exec_cmd 'hyprctl dispatch moveoutofgroup')
  hl.bind('U', hl.dsp.submap 'reset')
  hl.bind('N', hl.dsp.group.next())
  hl.bind('N', hl.dsp.submap 'reset')
  hl.bind('P', hl.dsp.group.next { forward = false })
  hl.bind('P', hl.dsp.submap 'reset')
  hl.bind('comma', hl.dsp.group.move_window { forward = false })
  hl.bind('comma', hl.dsp.submap 'reset')
  hl.bind('period', hl.dsp.group.move_window { forward = true })
  hl.bind('period', hl.dsp.submap 'reset')
  hl.bind('escape', hl.dsp.submap 'reset')
  hl.bind('Q', hl.dsp.submap 'reset')
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
  hl.exec_cmd(ensureService .. " udiskie 'udiskie --tray --notify'")
  hl.exec_cmd(ensureService .. ' hyprpaper hyprpaper')
  hl.exec_cmd(ensureService .. ' swayosd-server swayosd-server')
  hl.exec_cmd 'wl-paste --watch cliphist store'
  hl.exec_cmd('sleep 1 && ' .. HOME .. '/.config/hypr/scripts/randomise-wallpaper.sh')
end)

-- per-machine config — falls back silently if file doesn't exist
pcall(require, 'hyprland_monitors')
pcall(require, 'hyprland_custom')
