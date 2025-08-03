-- Save this as ~/.config/yazi/plugins/simple-message.yazi/init.lua

local function entry()
	ya.notify({
		title = "Test Message",
		content = "Hello from yazi plugin!",
		timeout = 3,
	})
	local cmd = "echo -e 'Option 1\\nOption 2\\nOption 3\\nOption 4' | fzf"
	local output = Command("sh"):args({ "-c", cmd }):output()

	if output and output.stdout then
		ya.notify({
			title = "You selected:",
			content = output.stdout,
		})
	end
end

return { entry = entry }
