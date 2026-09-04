-- Headless benchmark: for each repo, open a file and check that treesitter
-- highlights it, the expected language servers attach, go-to-definition lands
-- in the expected file, and document/workspace symbols come back.
--
--   nvim --headless -c 'luafile ~/.config/nvim/bench.lua'
--
-- Prints one PASS/FAIL line per check and exits 1 if anything failed.

local home = vim.env.HOME

-- line/character are 0-based, as in the LSP protocol.
local cases = {
  {
    repo = home .. '/dev-setup',
    file = 'flake.nix',
    servers = { 'nixd' },
    definition = { line = 46, character = 24, expect_file = 'flake.nix', symbol = 'mkPkgs' },
    workspace_query = 'mkPkgs',
  },
  {
    repo = home .. '/blackjack-auto',
    file = 'src/main.ts',
    servers = { 'vtsls' },
    definition = { line = 27, character = 9, expect_file = 'src/config.ts', symbol = 'parsedConfig' },
    workspace_query = 'parsedConfig',
  },
  {
    repo = home .. '/decision-server',
    file = 'main.py',
    servers = { 'basedpyright', 'ruff' },
    definition = { line = 20, character = 4, expect_file = 'decision_server/messageprotocol.py', symbol = 'AnimoRouletteBet' },
    workspace_query = 'AnimoRouletteBet',
  },
  {
    repo = home .. '/octane-tools',
    file = 'src/routes/+page.svelte',
    servers = { 'svelte' },
    definition = { line = 3, character = 14, expect_file = 'src/lib/types.ts', symbol = 'Job' },
    workspace_query = 'Job',
  },
  {
    repo = home .. '/octane-tools',
    file = 'src/lib/autotag.ts',
    servers = { 'vtsls', 'biome' },
    definition = { line = 9, character = 14, expect_file = 'src/lib/types.ts', symbol = 'MediaFile' },
    workspace_query = 'MediaFile',
  },
}

local attach_timeout_ms = 60000
local request_timeout_ms = 60000
-- tsserver answers definition requests before its project has loaded (pointing
-- at the import itself), so requests are retried until they succeed or this expires.
local retry_window_ms = 60000
local retry_interval_ms = 1000
local failures = 0

local function report(ok, label, detail)
  local status = ok and 'PASS' or 'FAIL'
  if not ok then
    failures = failures + 1
  end
  io.stdout:write(string.format('%s  %-52s %s\n', status, label, detail or ''))
end

local function skip(label, detail)
  io.stdout:write(string.format('SKIP  %-52s %s\n', label, detail or ''))
end

-- Repeat `attempt` (returns ok, detail) until ok or the retry window closes.
local function retry(attempt)
  local deadline = vim.uv.now() + retry_window_ms
  local ok, detail = attempt()
  while not ok and vim.uv.now() < deadline do
    vim.wait(retry_interval_ms)
    ok, detail = attempt()
  end
  return ok, detail
end

local function attached_client_names(bufnr)
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    table.insert(names, client.name)
  end
  table.sort(names)
  return names
end

local function has_all(actual, expected)
  for _, name in ipairs(expected) do
    if not vim.tbl_contains(actual, name) then
      return false
    end
  end
  return true
end

local function first_client(bufnr, names)
  for _, name in ipairs(names) do
    local clients = vim.lsp.get_clients { bufnr = bufnr, name = name }
    if clients[1] and clients[1]:supports_method 'textDocument/definition' then
      return clients[1]
    end
  end
  return nil
end

-- Result of a request may be Location, Location[] or LocationLink[].
local function location_uris(result)
  local uris = {}
  if result == nil then
    return uris
  end
  if result.uri or result.targetUri then
    result = { result }
  end
  for _, location in ipairs(result) do
    table.insert(uris, location.uri or location.targetUri)
  end
  return uris
end

-- Wait for the treesitter parsers requested in init.lua to finish compiling
-- on a fresh install before opening anything.
require('nvim-treesitter').install({ 'nix', 'typescript', 'python', 'svelte' }):wait(300000)
io.stdout:write '\n' -- installer progress lines have no trailing newline

for _, case in ipairs(cases) do
  local label_prefix = vim.fn.fnamemodify(case.repo, ':t') .. ' ' .. case.file
  vim.cmd.cd(case.repo)
  vim.cmd.edit(case.file)
  local bufnr = vim.api.nvim_get_current_buf()

  local highlighter_active = vim.treesitter.highlighter.active[bufnr] ~= nil
  report(highlighter_active, label_prefix .. ': treesitter highlight', 'filetype=' .. vim.bo[bufnr].filetype)

  vim.wait(attach_timeout_ms, function()
    return has_all(attached_client_names(bufnr), case.servers)
  end, 200)
  local names = attached_client_names(bufnr)
  report(has_all(names, case.servers), label_prefix .. ': lsp attach', table.concat(names, ','))

  local client = first_client(bufnr, case.servers)
  if client == nil then
    report(false, label_prefix .. ': definition', 'no client supports definition')
  else
    local params = {
      textDocument = { uri = vim.uri_from_bufnr(bufnr) },
      position = { line = case.definition.line, character = case.definition.character },
    }
    local expected_path = case.repo .. '/' .. case.definition.expect_file
    local landed, landed_detail = retry(function()
      local response = client:request_sync('textDocument/definition', params, request_timeout_ms, bufnr)
      local uris = location_uris(response and response.result)
      for _, uri in ipairs(uris) do
        if vim.uri_to_fname(uri) == expected_path then
          return true, case.definition.expect_file .. ' via ' .. client.name
        end
      end
      return false, 'got ' .. vim.inspect(vim.tbl_map(vim.uri_to_fname, uris)) .. ' via ' .. client.name
    end)
    report(landed, label_prefix .. ': definition of ' .. case.definition.symbol, landed_detail)

    local symbols = client:request_sync('textDocument/documentSymbol', { textDocument = params.textDocument }, request_timeout_ms, bufnr)
    local symbol_count = symbols and symbols.result and #symbols.result or 0
    report(symbol_count > 0, label_prefix .. ': document symbols', symbol_count .. ' top-level')

    local workspace_label = label_prefix .. ': workspace symbols "' .. case.workspace_query .. '"'
    if client:supports_method 'workspace/symbol' then
      local found, found_detail = retry(function()
        local workspace = client:request_sync('workspace/symbol', { query = case.workspace_query }, request_timeout_ms, bufnr)
        local workspace_count = workspace and workspace.result and #workspace.result or 0
        return workspace_count > 0, workspace_count .. ' result(s)'
      end)
      report(found, workspace_label, found_detail)
    else
      skip(workspace_label, client.name .. ' does not support workspace/symbol')
    end
  end
end

io.stdout:write(string.format('\n%d failure(s)\n', failures))
vim.cmd.cquit(failures == 0 and 0 or 1)
