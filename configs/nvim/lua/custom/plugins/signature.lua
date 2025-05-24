return {
  'ray-x/lsp_signature.nvim',
  event = 'InsertEnter',
  opts = {
    bind = true,
    handler_opts = {
      border = 'rounded',
    },
    floating_window_above_cur_line = false,
    toggle_key = '<C-x>',
  },
  config = function(_, opts)
    require('lsp_signature').setup(opts)
  end,
}
