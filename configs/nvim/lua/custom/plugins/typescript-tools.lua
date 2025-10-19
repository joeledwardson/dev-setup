return {
  'pmizio/typescript-tools.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  ft = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'vue' },
  opts = {
    settings = {
      -- tsserver_logs = 'verbose',
      -- This exposes ALL TypeScript refactors as code actions!
      expose_as_code_action = 'all',

      -- This adds parentheses when completing functions
      -- complete_function_calls = true,

      -- This shows reference counts above functions
      code_lens = 'off',
    },
  },
  config = function(_, opts)
    -- Initialize TypeScript Tools
    require('typescript-tools').setup(opts)

    -- Custom TypeScript Watch command
    vim.api.nvim_create_user_command('TypeScriptWatch', function()
      -- Create a new tab
      vim.cmd 'tabnew'

      -- Open a terminal with TypeScript compiler in watch mode
      vim.cmd 'terminal npx tsc --watch'

      -- Set the buffer name to make it identifiable
      vim.api.nvim_buf_set_name(0, 'TypeScript Watch')

      -- Set buffer-local options for handling file links
      local bufnr = vim.api.nvim_get_current_buf()

      -- Enable terminal-normal mode with <Esc>
      vim.api.nvim_buf_set_keymap(bufnr, 't', '<Esc>', '<C-\\><C-n>', { noremap = true, silent = true })

      -- Configure the buffer to recognize TypeScript error paths
      -- This allows using the built-in 'gf', 'Ctrl-W f', etc. commands
      vim.cmd [[
        " Set the 'errorformat' for this buffer to recognize TypeScript errors
        setlocal errorformat=%f(%l\\,%c):\ %m
        
        " Set the 'suffixesadd' to automatically try .ts, .tsx extensions
        setlocal suffixesadd=.ts,.tsx,.js,.jsx

        " Enable 'includeexpr' to convert TypeScript error paths to file paths
        setlocal includeexpr=substitute(v:fname,'^.*[/\\\\]\\ze[^/\\\\]\\+$','','')
        
        " Function to handle opening files with line and column numbers
        function! TSOpenFileUnderCursor()
          let line = getline('.')
          let matches = matchlist(line, '\(\S\+\)(\(\d\+\),\(\d\+\))')
          if len(matches) > 3
            let file = matches[1]
            let lnum = matches[2]
            let col = matches[3]
            execute 'tabnew ' . file
            call cursor(lnum, col)
            return 1
          endif
          " Fall back to built-in gf if no TypeScript error format is found
          normal! gf
          return 0
        endfunction
      ]]

      -- Map Enter and Ctrl+] to open file links under cursor
      vim.api.nvim_buf_set_keymap(bufnr, 'n', '<CR>', ':call TSOpenFileUnderCursor()<CR>', { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-]>', ':call TSOpenFileUnderCursor()<CR>', { noremap = true, silent = true })

      -- Also enable the built-in file navigation commands for this buffer
      vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gf', ':call TSOpenFileUnderCursor()<CR>', { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-W>f', '<C-W>v:call TSOpenFileUnderCursor()<CR>', { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-W>gf', ':tabnew<CR>:call TSOpenFileUnderCursor()<CR>', { noremap = true, silent = true })

      -- Start in insert mode to interact with the terminal
      vim.cmd 'startinsert'
    end, {})

    -- Add a keymap for the TypeScriptWatch command
    vim.keymap.set('n', '<leader>tw', ':TypeScriptWatch<CR>', { silent = true, desc = 'TypeScript Watch mode' })
  end,
}
