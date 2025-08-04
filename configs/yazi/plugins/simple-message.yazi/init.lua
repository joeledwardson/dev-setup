return {
  entry = function()
    local cmd = "echo -e 'Option 1\\nOption 2\\nOption 3\\nOption 4' | fzf"
    local output = Command("sh"):args({"-c", cmd}):output()
    
    if output and output.stdout then
      ya.notify({
        title = "You selected:",
        content = output.stdout,
      })
    end
  end,
}