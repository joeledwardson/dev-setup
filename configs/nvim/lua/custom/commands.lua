vim.api.nvim_create_autocmd('BufEnter', {
  pattern = { '*.service', '*.socket', '*.mount', '*.device', '*.nspawn', '*.target', '*.timer' },
  callback = function()
    vim.bo.filetype = 'systemd'
    vim.lsp.start {
      name = 'systemd_ls',
      cmd = { 'systemd-lsp' },
      root_dir = vim.fn.getcwd(),
    }
  end,
})
