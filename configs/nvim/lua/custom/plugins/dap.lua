return {
  { 'nvim-neotest/nvim-nio' },
  {
    'mfussenegger/nvim-dap',
    config = function()
      local dap = require 'dap'
      dap.adapters['pwa-node'] = {
        type = 'server',
        host = '127.0.0.1',
        port = 8123,
        executable = {
          command = 'js-debug-adapter',
        },
      }

      for _, language in ipairs { 'typescript', 'javascript' } do
        dap.configurations[language] = {
          {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch file',
            program = '${file}',
            cwd = '${workspaceFolder}',
            runtimeExecutable = 'node',
          },
          -- Divider for the launch.json derived configs
          {
            name = '----- ↓ launch.json configs ↓ -----',
            type = '',
            request = 'launch',
          },
        }
      end
      --
      -- vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, link = 'Visual' })
      --
      -- for _, language in ipairs(js_based_languages) do
      --   dap.configurations[language] = {
      --     -- Debug single nodejs files
      --     {
      --       type = 'pwa-node',
      --       request = 'launch',
      --       name = 'Launch file',
      --       program = '${file}',
      --       cwd = vim.fn.getcwd(),
      --       sourceMaps = true,
      --     },
      --     -- Debug nodejs processes (make sure to add --inspect when you run the process)
      --     {
      --       type = 'pwa-node',
      --       request = 'attach',
      --       name = 'Attach',
      --       processId = require('dap.utils').pick_process,
      --       cwd = vim.fn.getcwd(),
      --       sourceMaps = true,
      --     },
      --     -- Debug web applications (client side)
      --     {
      --       type = 'pwa-chrome',
      --       request = 'launch',
      --       name = 'Launch & Debug Chrome',
      --       url = function()
      --         local co = coroutine.running()
      --         return coroutine.create(function()
      --           vim.ui.input({
      --             prompt = 'Enter URL: ',
      --             default = 'http://localhost:3000',
      --           }, function(url)
      --             if url == nil or url == '' then
      --               return
      --             else
      --               coroutine.resume(co, url)
      --             end
      --           end)
      --         end)
      --       end,
      --       nwebRoot = vim.fn.getcwd(),
      --       protocol = 'inspector',
      --       sourceMaps = true,
      --       userDataDir = false,
      --     },
      --     -- Divider for the launch.json derived configs
      --     {
      --       name = '----- ↓ launch.json configs ↓ -----',
      --       type = '',
      --       request = 'launch',
      --     },
      --   }
      -- end
    end,
    keys = {
      {
        '<leader>dO',
        function()
          require('dap').step_out()
        end,
        desc = 'Step Out',
      },
      {
        '<leader>do',
        function()
          require('dap').step_over()
        end,
        desc = 'Step Over',
      },
      {
        '<leader>da',
        function()
          if vim.fn.filereadable '.vscode/launch.json' then
            local dap_vscode = require 'dap.ext.vscode'
            dap_vscode.load_launchjs(nil)
          end
          require('dap').continue()
        end,
        desc = 'Run with Args',
      },
    },
    dependencies = {
      {
        'williamboman/mason.nvim',
        opts = {
          ensure_installed = {
            -- "eslint-lsp",
            'js-debug-adapter',
            -- "prettier",
            -- "typescript-language-server"
          },
        },
      },

      -- Install the vscode-js-debug adapter
      -- {
      --   'microsoft/vscode-js-debug',
      --   -- After install, build it and rename the dist directory to out
      --   build = 'npm install --legacy-peer-deps --no-save && npx gulp vsDebugServerBundle && rm -rf out && mv dist out',
      --   version = '1.*',
      -- },
      -- {
      --   'mxsdev/nvim-dap-vscode-js',
      --   config = function()
      --     ---@diagnostic disable-next-line: missing-fields
      --     require('dap-vscode-js').setup {
      --       -- Path of node executable. Defaults to $NODE_PATH, and then "node"
      --       -- node_path = "node",
      --
      --       -- Path to vscode-js-debug installation.
      --       debugger_path = vim.fn.resolve(vim.fn.stdpath 'data' .. '/lazy/vscode-js-debug'),
      --
      --       -- Command to use to launch the debug server. Takes precedence over "node_path" and "debugger_path"
      --       -- debugger_cmd = { "js-debug-adapter" },
      --
      --       -- which adapters to register in nvim-dap
      --       adapters = {
      --         'chrome',
      --         'pwa-node',
      --         'pwa-chrome',
      --         'pwa-msedge',
      --         'pwa-extensionHost',
      --         'node-terminal',
      --       },
      --
      --       -- Path for file logging
      --       -- log_file_path = "(stdpath cache)/dap_vscode_js.log",
      --
      --       -- Logging level for output to file. Set to false to disable logging.
      --       -- log_file_level = false,
      --
      --       -- Logging level for output to console. Set to false to disable console output.
      --       -- log_console_level = vim.log.levels.ERROR,
      --     }
      --   end,
      -- },
      {
        'Joakker/lua-json5',
        build = './install.sh',
      },
      -- Add nvim-dap-ui with minimal config
      {
        'rcarriga/nvim-dap-ui',
        dependencies = { 'nvim-neotest/nvim-nio' },
        config = function()
          local dap, dapui = require 'dap', require 'dapui'

          dapui.setup()

          -- Auto open/close UI
          dap.listeners.after.event_initialized['dapui_config'] = function()
            dapui.open()
          end
          dap.listeners.before.event_terminated['dapui_config'] = function()
            dapui.close()
          end
          dap.listeners.before.event_exited['dapui_config'] = function()
            dapui.close()
          end
        end,
        keys = {
          {
            '<leader>du',
            function()
              require('dapui').toggle()
            end,
            desc = 'Toggle DAP UI',
          },
          {
            '<leader>de',
            function()
              require('dapui').eval()
            end,
            desc = 'Eval Expression',
          },
        },
      },
    },
  },
}
