---@type LazyPluginSpec
return {
  '3rd/image.nvim',
  lazy = false,
  build = false, -- Don't run build commands
  opts = {
    backend = 'kitty', -- or "ueberzug"
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        download_remote_images = true,
      },
    },
    max_width = nil,
    max_height = nil,
    max_width_window_percentage = nil,
    max_height_window_percentage = 50,
  },
  dependencies = {
    -- Don't include luarocks dependencies since we have them via Nix
  },
}
