-- Language servers. Binaries come from flake.nix (no Mason); definitions (cmd, filetypes,
-- root markers) come from nvim-lspconfig's lsp/*.lua; overrides below are merged on top
-- via vim.lsp.config. Completion and signature help are the built-in ones:
--   insert mode <C-s>  signature help (nvim default)
--   typing             LSP completion menu, docs in a popup ('completeopt' in init.lua)
--   <Tab>              accept the selected item, or jump to the next snippet field
--   <C-n> / <C-x><C-f> buffer words / file paths, as ever
--   <C-x><C-o>         omnifunc, e.g. vim-dadbod-completion in sql buffers

require('fidget').setup { notification = { override_vim_notify = true } }

local servers = {
  basedpyright = {},
  vtsls = {},
  marksman = {},
  postgres_lsp = {
    cmd = { 'postgres-language-server', 'lsp-proxy' },
    filetypes = { 'sql' },
    root_markers = { 'postgres-language-server.jsonc' },
  },
  jsonls = {
    settings = {
      json = {
        schemas = require('schemastore').json.schemas(),
        validate = { enable = true },
      },
    },
  },
  yamlls = {
    settings = {
      yaml = {
        schemaStore = {
          enable = false,
          url = '',
        },
        schemas = require('schemastore').yaml.schemas(),
      },
    },
  },
  lua_ls = {
    reuse_client = function(client, config)
      return client.name == config.name and client.root_dir == config.root_dir
    end,
    on_init = function(client)
      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then
          return
        end
      end
      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = { version = 'LuaJIT' },
        workspace = {
          checkThirdParty = false,
          -- What lazydev did behind the scenes, written out: lua_ls only knows the
          -- files you point it at. VIMRUNTIME holds the nvim API annotations,
          -- ${3rd}/luv/library the vim.uv types, and the pack dir every plugin's
          -- source so require('telescope') resolves and its functions complete.
          library = {
            vim.env.VIMRUNTIME,
            '${3rd}/luv/library',
            vim.fn.stdpath 'data' .. '/site/pack/core/opt',
          },
        },
      })
    end,
    settings = {
      Lua = {
        completion = {
          callSnippet = 'Replace',
        },
        diagnostics = {
          severity = {
            ['undefined-field'] = 'Warning',
            ['missing-fields'] = 'Warning',
            ['undefined-doc-class'] = 'Warning',
          },
          groupSeverity = {
            ['strong'] = 'Warning',
            ['strict'] = 'Warning',
            ['type-check'] = 'Warning',
          },
          neededFileStatus = {
            ['type-check'] = 'Any',
          },
        },
        type = {
          checkTableShape = true,
          weakNilCheck = false,
        },
      },
    },
  },
  bashls = {
    filetypes = { 'sh', 'zsh' },
  },
  svelte = {},
  cssls = {
    settings = {
      css = { lint = { unknownAtRules = 'ignore' } },
      scss = { lint = { unknownAtRules = 'ignore' } },
      less = { lint = { unknownAtRules = 'ignore' } },
    },
  },
  tailwindcss = {
    filetypes = { 'css', 'html', 'svelte' },
  },
  just = {},
  biome = {},
  mdx_analyzer = {},
  ruff = {},
  gopls = {},
  ansiblels = {},
  systemd_ls = {},
  terraformls = {
    on_attach = function(client, _)
      client.server_capabilities.signatureHelpProvider = nil
    end,
  },
  atlas = {
    filetypes = { 'atlas-schema-postgresql' },
    root_markers = { 'schema.pg.hcl' },
  },
}

-- Point nixd's options provider at THIS host's evaluated flake config. Without it,
-- hover/completion only knows base nixpkgs options — options from flake inputs
-- (agenix `age.secrets`, nixarr, hermes) and our own modules hover as empty/"missing
-- type". flake_dir is derived from the nvim config symlink (…/dev-setup/configs/nvim-min
-- -> repo root) so it works on every host; hostname matches the nixosConfigurations key.
-- NB: category nodes (e.g. `fonts`, `age`) have no type of their own and always hover
-- as "missing type" — hover a leaf option like `fonts.packages`.
local flake_dir = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.stdpath 'config'), ':h:h')
local nix_hostname = vim.uv.os_gethostname()
servers.nixd = {
  settings = {
    nixd = {
      options = {
        nixos = {
          expr = string.format('(builtins.getFlake "%s").nixosConfigurations."%s".options', flake_dir, nix_hostname),
        },
      },
    },
  },
}

for server_name, server_config in pairs(servers) do
  vim.lsp.config(server_name, server_config)
end
vim.lsp.enable(vim.tbl_keys(servers))

-- atlas HCL dialects
vim.filetype.add {
  filename = {
    ['atlas.hcl'] = 'atlas-config',
  },
  pattern = {
    ['.*/*.my.hcl'] = 'atlas-schema-mysql',
    ['.*/*.pg.hcl'] = 'atlas-schema-postgresql',
    ['.*/*.lt.hcl'] = 'atlas-schema-sqlite',
    ['.*/*.ch.hcl'] = 'atlas-schema-clickhouse',
    ['.*/*.ms.hcl'] = 'atlas-schema-mssql',
    ['.*/*.rs.hcl'] = 'atlas-schema-redshift',
    ['.*/*.test.hcl'] = 'atlas-test',
    ['.*/*.plan.hcl'] = 'atlas-plan',
    ['.*/*.rule.hcl'] = 'atlas-rule',
  },
}
for _, atlas_filetype in ipairs {
  'atlas-config',
  'atlas-schema-mysql',
  'atlas-schema-postgresql',
  'atlas-schema-sqlite',
  'atlas-schema-clickhouse',
  'atlas-schema-mssql',
  'atlas-schema-redshift',
  'atlas-test',
  'atlas-plan',
  'atlas-rule',
} do
  vim.treesitter.language.register('hcl', atlas_filetype)
end

-- <Tab> accepts the highlighted completion (the first one if none is highlighted, like
-- blink's select_and_accept did), or moves to the next snippet field, else is a tab.
vim.keymap.set('i', '<Tab>', function()
  if vim.fn.pumvisible() == 1 then
    local nothing_selected = vim.fn.complete_info({ 'selected' }).selected == -1
    return nothing_selected and '<C-n><C-y>' or '<C-y>'
  end
  if vim.snippet.active { direction = 1 } then
    return '<Cmd>lua vim.snippet.jump(1)<CR>'
  end
  return '<Tab>'
end, { expr = true, desc = 'accept completion / next snippet field' })
vim.keymap.set({ 'i', 's' }, '<S-Tab>', function()
  if vim.snippet.active { direction = -1 } then
    return '<Cmd>lua vim.snippet.jump(-1)<CR>'
  end
  return '<S-Tab>'
end, { expr = true, desc = 'previous snippet field' })

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end
    local builtin = require 'telescope.builtin'
    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
    map('grr', builtin.lsp_references, '[G]oto [R]eferences')
    map('gri', builtin.lsp_implementations, '[G]oto [I]mplementation')
    map('grd', builtin.lsp_definitions, '[G]oto [D]efinition')
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    map('gO', builtin.lsp_document_symbols, 'Open Document Symbols')
    map('gW', builtin.lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')
    map('grt', builtin.lsp_type_definitions, '[G]oto [T]ype Definition')
    map('K', vim.lsp.buf.hover, 'Hover Documentation')

    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- Built-in completion. Servers only auto-trigger on their own characters
    -- (".", ":" ...); adding every word character makes it fire as you type.
    -- See :h lsp-autocompletion.
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_completion) then
      local word_characters = vim.split('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_', '')
      client.server_capabilities.completionProvider.triggerCharacters = word_characters
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    end

    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
      local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })
      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, '[T]oggle Inlay [H]ints')
    end
  end,
})
