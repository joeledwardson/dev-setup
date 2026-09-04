local dap = require 'dap'
local dapui = require 'dapui'

dap.set_log_level 'DEBUG'

-- `js-debug` is the vscode-js-debug DAP server from flake.nix (Mason called it js-debug-adapter).
dap.adapters = {
  ['pwa-node'] = {
    type = 'server',
    host = '::1',
    port = '${port}',
    executable = {
      command = 'js-debug',
      args = {
        '${port}',
      },
    },
  },
}

dap.configurations['javascript'] = {
  {
    type = 'pwa-node',
    request = 'launch',
    name = 'Launch JS file',
    program = '${file}',
    cwd = '${workspaceFolder}',
    sourceMaps = true,
    smartStep = true,
    skipFiles = { '<node_internals>/**', 'node_modules/**' },
  },
}
dap.configurations['typescript'] = {
  {
    type = 'pwa-node',
    request = 'launch',
    name = 'Launch TS file',
    program = '${file}',
    cwd = '${workspaceFolder}',
    runtimeExecutable = 'npx',
    runtimeArgs = { 'ts-node', '${file}' },
    sourceMaps = true,
    smartStep = true,
    skipFiles = { '<node_internals>/**', 'node_modules/**' },
    outputCapture = 'std',
  },
}

dapui.setup {
  icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
  controls = {
    icons = {
      pause = '⏸',
      play = '▶',
      step_into = '⏎',
      step_over = '⏭',
      step_out = '⏮',
      step_back = 'b',
      run_last = '▶▶',
      terminate = '⏹',
      disconnect = '⏏',
    },
  },
}

vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<leader>B', function()
  dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
end, { desc = 'Debug: Set Breakpoint' })
vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })
