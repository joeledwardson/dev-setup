local function printer_util(entry)
  local function inner(key, value, indent)
    if type(value) == 'table' then
      print(string.rep('  ', indent) .. tostring(key))
      for k, v in pairs(value) do
        inner(k, v, indent + 1)
      end
    else
      print(string.rep('  ', indent) .. tostring(key) .. ': ' .. tostring(value))
    end
  end
  inner('_', entry, 0)
end

printer_util(vim.lsp.get_clients())
