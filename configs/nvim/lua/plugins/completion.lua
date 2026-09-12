local cmp = require 'blink.cmp'

cmp.setup {
  keymap = {
    preset = 'default',
    -- enter key to select suggestion
    ['<CR>'] = { 'accept', 'fallback' },
    -- prioritise snippets with tab first, otherwise accept suggestion
    ['<Tab>'] = { 'snippet_forward', 'select_and_accept', 'fallback' },
    ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },
  },
  fuzzy = { implementation = 'rust' },
  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
  },
  cmdline = {
    -- map to command line and use tab to accept
    keymap = { ['<Tab>'] = { 'show', 'accept' } },
    completion = { menu = { auto_show = true } },
  },
}
