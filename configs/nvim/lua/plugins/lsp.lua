-- replace regular vim notifications with fidget
require('fidget').setup { notification = { override_vim_notify = true } }

-- Configurations supplied by nvim-lspconfig that need no local overrides.
vim.lsp.enable {
  'basedpyright',
  'marksman',
  'svelte',
  'just',
  'biome',
  'mdx_analyzer',
  'ruff',
  'gopls',
  'ansiblels',
  'systemd_ls',
}

vim.lsp.config('vtsls', {
    ---@type lspconfig.settings.vtsls
    settings = {
      vtsls = { autoUseWorkspaceTsdk = true },
    },
})
vim.lsp.enable 'vtsls'

vim.lsp.config('postgres_lsp', {
    cmd = { 'postgres-language-server', 'lsp-proxy' },
    filetypes = { 'sql' },
    root_markers = { 'postgres-language-server.jsonc' },
})
vim.lsp.enable 'postgres_lsp'

vim.lsp.config('jsonls', {
    ---@type lspconfig.settings.jsonls
    settings = {
      json = {
        schemas = require('schemastore').json.schemas(),
        validate = { enable = true },
      },
    },
})
vim.lsp.enable 'jsonls'

vim.lsp.config('yamlls', {
    ---@type lspconfig.settings.yamlls
    settings = {
      yaml = {
        schemaStore = {
          enable = false,
          url = '',
        },
        schemas = require('schemastore').yaml.schemas(),
      },
    },
})
vim.lsp.enable 'yamlls'

vim.lsp.config('lua_ls', {
    reuse_client = function(client, config)
      return client.name == config.name and client.root_dir == config.root_dir
    end,
    on_init = function(client)
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
    ---@type lspconfig.settings.lua_ls
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
})
vim.lsp.enable 'lua_ls'

vim.lsp.config('bashls', {
    filetypes = { 'sh', 'zsh' },
})
vim.lsp.enable 'bashls'

vim.lsp.config('cssls', {
    ---@type lspconfig.settings.cssls
    settings = {
      css = { lint = { unknownAtRules = 'ignore' } },
      scss = { lint = { unknownAtRules = 'ignore' } },
      less = { lint = { unknownAtRules = 'ignore' } },
    },
})
vim.lsp.enable 'cssls'

vim.lsp.config('tailwindcss', {
    filetypes = { 'css', 'html', 'svelte' },
})
vim.lsp.enable 'tailwindcss'

vim.lsp.config('terraformls', {
    on_attach = function(client, _)
      client.server_capabilities.signatureHelpProvider = nil
    end,
})
vim.lsp.enable 'terraformls'

vim.lsp.config('atlas', {
    filetypes = { 'atlas-schema-postgresql' },
    root_markers = { 'schema.pg.hcl' },
})
vim.lsp.enable 'atlas'

vim.lsp.config('nixd', {
  ---@type lspconfig.settings.nixd
  settings = {
    nixd = {
      options = {
        nixos = {
          expr = string.format(
            '(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.%q.options',
            vim.uv.os_gethostname()
          ),
        },
      },
    },
  },
})
vim.lsp.enable 'nixd'

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

-- Per-buffer setup, run once for every server that attaches -------------------
local methods = vim.lsp.protocol.Methods

-- Ours to drive: there is no `vim.lsp.document_highlight.enable()`, unlike inlay hints.
local highlight_group = vim.api.nvim_create_augroup('lsp-highlight', { clear = true })

--- Highlights other occurrences of the symbol under the cursor, after `updatetime` of idle.
--- @param bufnr integer
local function enable_reference_highlights(bufnr)
  -- Clear first, so a second server attaching does not double the requests per idle.
  vim.api.nvim_clear_autocmds { group = highlight_group, buffer = bufnr }

  vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
    buffer = bufnr,
    group = highlight_group,
    callback = vim.lsp.buf.document_highlight,
  })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    buffer = bufnr,
    group = highlight_group,
    callback = vim.lsp.buf.clear_references,
  })
end

--- Buffer-scoped keymap options, with the 'LSP: ' which-key prefix applied.
--- @param bufnr integer
--- @param desc string
--- @return vim.keymap.set.Opts
local function lsp_opts(bufnr, desc)
  return { buffer = bufnr, desc = 'LSP: ' .. desc }
end

--- (see `:help gr-default`), so the maps below either swap in a Telescope picker for core's
--- quickfix list, or cover a request core leaves unmapped.
--- @param bufnr integer
--- @param client vim.lsp.Client
local function set_lsp_keymaps(bufnr, client)
  local builtin = require 'telescope.builtin'

  vim.keymap.set('n', 'grr', builtin.lsp_references, lsp_opts(bufnr, '[G]oto [R]eferences'))
  vim.keymap.set('n', 'gri', builtin.lsp_implementations, lsp_opts(bufnr, '[G]oto [I]mplementation'))
  vim.keymap.set('n', 'grd', builtin.lsp_definitions, lsp_opts(bufnr, '[G]oto [D]efinition'))
  vim.keymap.set('n', 'grD', vim.lsp.buf.declaration, lsp_opts(bufnr, '[G]oto [D]eclaration'))
  vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, lsp_opts(bufnr, 'Open Document Symbols'))
  vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, lsp_opts(bufnr, 'Open Workspace Symbols'))
  vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, lsp_opts(bufnr, '[G]oto [T]ype Definition'))

  if client:supports_method(methods.textDocument_inlayHint) then
    vim.keymap.set('n', '<leader>th', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr })
    end, lsp_opts(bufnr, '[T]oggle Inlay [H]ints'))
  end
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then
      return
    end

    set_lsp_keymaps(event.buf, client)

    if client:supports_method(methods.textDocument_documentHighlight) then
      enable_reference_highlights(event.buf)
    end
  end,
})

-- Registered once here, rather than rebuilt on every attach as it was before.
vim.api.nvim_create_autocmd('LspDetach', {
  group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
  callback = function(event)
    vim.lsp.buf.clear_references()
    vim.api.nvim_clear_autocmds { group = highlight_group, buffer = event.buf }
  end,
})
