local cmp = require 'blink.cmp'

cmp.setup {
  keymap = {
    preset = 'default',
    -- <CR> is deliberately unmapped: Enter always means newline, never accept. Tab accepts.
    ['<Tab>'] = { 'select_and_accept', 'fallback' },
    ['<S-Tab>'] = { 'select_prev', 'fallback' },
    -- snippet jumps get their own keys so they never fight Tab-accept; outside a snippet they fall back to window nav
    ['<C-l>'] = { 'snippet_forward', 'fallback' },
    ['<C-h>'] = { 'snippet_backward', 'fallback' },
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
