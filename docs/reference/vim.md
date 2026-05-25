---
created: 2025-09-01
updated: 2026-05-24
---

### Command Cheat Sheet (Get & Set)

| Action | **Global Variable** (Example: `colors_name`) | **Editor Option** (Example: `number`) |
| :--- | :--- | :--- |
| **Lua (Set)** | `vim.g.colors_name = "gruvbox"` | `vim.opt.number = true` |
| **Lua (Get)** | `print(vim.g.colors_name)` | `print(vim.opt.number:get())` |
| **Vimscript (Set)** | `let g:colors_name = "gruvbox"` | `set number` |
| **Vimscript (Get)** | `echo g:colors_name` | `set number?` |

And now for buffers etc

| Action | **Global Scope** (Everywhere) | **Buffer Scope** (Current File Only) |
| :--- | :--- | :--- |
| **Concept** | Applies to the entire editor session. | Applies **only** to the currently open file/tab. |
| **Variable Prefix** | `g:` (Vim) / `vim.g` (Lua) | `b:` (Vim) / `vim.b` (Lua) |
| **Option Object** | `vim.opt` | `vim.bo` |
| **Lua Set Variable** | `vim.g.my_var = 1` | `vim.b.my_var = 1` |
| **Lua Set Option** | `vim.opt.scrolloff = 8` | `vim.bo.shiftwidth = 2` |
| **Vim Set Variable** | `let g:my_var = 1` | `let b:my_var = 1` |
| **Vim Set Option** | `set scrolloff=8` | `setlocal shiftwidth=2` |

And globals

---

### Lua Globals (`_G`) vs. Vim Globals (`vim.g`)

| Feature | **Vim Global (`vim.g`)** | **Lua Global (`_G`)** |
| :--- | :--- | :--- |
| **What it is** | A bridge to the **Vimscript** engine. | The global namespace for the **Lua** language. |
| **Primary Use** | Configuring plugins (e.g., `markdown-preview`). | defining functions callable from Vimscript (`v:lua`). |
| **Visibility** | Seen by `.vim` files and older plugins. | Seen by all `.lua` files and the `v:lua` bridge. |
| **Set Command** | `vim.g.my_var = 1` | `_G.my_func = function() ... end` |
| **Get Command** | `print(vim.g.my_var)` | `_G.my_func()` |
| **Vimscript Access** | `echo g:my_var` | `call v:lua.my_func()` |


Summary of the "Big Three"
- vim.opt: Switches/knobs for the Editor (Line numbers, tabs).
- vim.g: Settings for Plugins (Theme names, enable/disable flags).
- _G: Logic for Functions (Your custom code that needs to run everywhere).

Ok so....
In a lua console
```lua
_G.pls = function()
  print("hello?")
  return "no output :("
end
```

Then can do EITHER `:lua print(pls())` or `:lua print(_G.pls())` as `_G` is the global namespace!

Then, the equivalent in vim is 

> notice that `print()` does not appear, as it goes to message history?
> `vim.notify` WILL print however

This STILL doesn't make sense to me - but I guess that the lua print() is only really for debugging? In general an API show either log to a file or notify?

I found the docs [here](https://neovim.io/doc/user/lua.html#lua-commands) where it says lua `print()` redirects its output to the nvim message area?

Ok well the various types of printing in vim and lua are frying my brain a bit - especially since `print()` in lua claims to print to the message area but... does not? well gemini (tried) to explain
| Method | Command | Behavior | Persistence |
| :--- | :--- | :--- | :--- |
| **Lua Print** | `print("msg")` | Sends to msg-layer | Often overwritten instantly |
| **Vim Cmd** | `vim.cmd('echo "msg"')` | Standard Vim echo | Stays until next keypress |
| **Vim API** | `vim.api.nvim_echo(...)` | Chunked & Highlighted | High (configured via args) |
| **Notify** | `vim.notify("msg")` | General notification | Depends on UI (popup or cmd) |


`vim.notify()` is fairly modern so that does make sense honestly. its the others

Ok NEVER MIND - it was because i was in the lua console - i assume `print()` is found to a different messages area or something

---

### Vimscript functions
So weird weird details of how functions work in vim
- `system()` is a FUNCTION
- `:echo` is a COMMAND

and functions CANNOT be called directly from the command line!

Hence why `:system(...)` does not work! need `:echo` or `:call` to invoke it

Even weirder... even inside a vimscript function this still applies? which seems strange to me but oh well... So like doing `:` to invoke a command the same applies in vimscript in will complain if you try and do
```vim
function! OpenMarkdownPreview(url)
  system('echo hi')
end
```
will yield
```
E492: Not an editor command: system('echo hi')
```

as you need echo or call!

---

### Wincmd?
So apparently `:tabdo` executes for each tab?

Nice! so like
```lua
:tabdo :echo bufname()
```

Goes and prints bufname for each tab (active buffer)

Ahhhh
`:wincmd =` is the same as `C-W =` a window command...

Interestingly, the reason the the `outline` escapes from this when its called (and graciously so, wouldn't want the outline taking up half the page horizontally...)

It is the `winfixwidth` property that forces the win to stay constant (when `C-w =` is called)

---

### Vim: Redirect command output to register
`:new | put =execute('SomeCommand')` — this opens a new scratch buffer and pastes the output of any ex command into it. Breakdown:
- `:new` — opens a new empty split
- `put =` — puts the result of an expression into the buffer
- `execute('...')` — runs an ex command and captures its output as a string

So `execute('Fidget history')` runs `:Fidget history` and returns the output text, then `put =` pastes it into the buffer where you can search with `/`.

Works with any command, e.g. `:new | put =execute('messages')`, `:new | put =execute('map')`

Ok so (ME not claude as of now...)

`|` is not actually what i thought like a pipe in bash, it is actually just like `;` in bash (see `:h :bar` in vim)

So in this case we are just saying `:new` to open a new buffer and THEN `:put` to dump the output of the register

**Gotcha: `|` doesn't work with all commands.** Some commands treat `|` as part of their own arguments instead of as a command separator. User-defined commands (from plugins) do this by default unless the plugin author explicitly opted in to `|` separation with `-bar` (see `:h command-bar`). So:
```vim
:OutlineFocus | OutlineClose   " BROKEN — OutlineClose is passed as an arg to OutlineFocus
```
Fix: use `<cmd>...<cr>` chaining in a keymap, or just use separate commands. In ex mode, there's no clean workaround — run them separately:
```vim
:OutlineFocus
:OutlineClose
```
Or in a keymap:
```lua
vim.keymap.set("n", "<leader>X", function()
  vim.cmd("OutlineFocus")
  vim.cmd("OutlineClose")
end)
```

e.g.
```vim
let @b='pls'
:put b
```
dumps 'pls' into current buffer

i did try this
```vim
:put = execute('echo "hi there"')
```
BUT echo doesn't return to a buffer so it wouldn't work. WAIT IGNORE. just needed to escape the " with
```vim
:put = execute('echo \"hi there\"')
```

....or...
```vim
:put = 'hi there'
```

---

### Vim registers and the `"` prefix
Registers in vim are accessed with `"` (double quote) in normal mode.

**Special registers:**

| Register | Description | Example |
| :--- | :--- | :--- |
| `"+` | System clipboard | `"+y` yank to clipboard, `let @+=expand('%:p')` copy file path to clipboard |
| `"=` | Expression register — evaluates vimscript | `put =execute('Fidget history')` dumps command output into buffer |
| `"0` | Last yank | `"0p` paste what you last yanked (not deleted) |
| `""` | Default (unnamed) | `p` pastes from here by default |

> to see help can use vims special 'quote' like `:h quote=` is equivalent to `:h "=`

**Accessing registers — `"` vs `@`:**

| Syntax | Context | Example |
| :--- | :--- | :--- |
| `"` | Normal mode — select register before an operator | `"ay` yank into `a`, `"+p` paste from clipboard |
| `@` | Ex commands / vimscript — read/write registers | `let @+ = expand('%:p')`, `@a` execute macro |

**Why `quote=` in vim help?**
Vim help spells `"` as `quote` in its help tags, so `:h quote=` means "help for the `"=` register", `:h quotea` for `"a`, etc.

---

### Vim variable scopes cheat sheet

| Scope | What | Vim get | Vim set | Lua get | Lua set |
|-------|------|---------|---------|---------|---------|
| `g:` | global variables | `:echo g:foo` | `:let g:foo = 1` | `vim.g.foo` | `vim.g.foo = 1` |
| `b:` | buffer-local variables | `:echo b:foo` | `:let b:foo = 1` | `vim.b.foo` or `vim.b[bufnr].foo` | `vim.b.foo = 1` |
| `w:` | window-local variables | `:echo w:foo` | `:let w:foo = 1` | `vim.w.foo` or `vim.w[winid].foo` | `vim.w.foo = 1` |
| `t:` | tab-local variables | `:echo t:foo` | `:let t:foo = 1` | `vim.t.foo` or `vim.t[tabnr].foo` | `vim.t.foo = 1` |
| `v:` | vim predefined variables | `:echo v:count` | (read-only mostly) | `vim.v.count` | (read-only mostly) |

**Options** (settings like `number`, `expandtab`) use `vim.opt` / `vim.o` / `vim.bo` / `vim.wo`:

| Scope | What | Vim get | Vim set | Lua get | Lua set |
|-------|------|---------|---------|---------|---------|
| global option | `:set foo` | `:echo &foo` | `:set foo=1` | `vim.o.foo` or `vim.opt.foo:get()` | `vim.o.foo = 1` or `vim.opt.foo = 1` |
| buffer option | `:setlocal foo` (buffer) | `:echo &l:foo` | `:setlocal foo=1` | `vim.bo.foo` or `vim.bo[bufnr].foo` | `vim.bo.foo = 1` |
| window option | `:setlocal foo` (window) | `:echo &l:foo` | `:setlocal foo=1` | `vim.wo.foo` or `vim.wo[winid].foo` | `vim.wo.foo = 1` |

**Examples:**

| Type | Example | Purpose |
|------|---------|---------|
| `vim.g.mapleader` | `vim.g.mapleader = ' '` | global var, set leader key |
| `vim.g.clipboard` | `vim.g.clipboard = {...}` | global var, clipboard provider config |
| `vim.b.disable_autoformat` | `vim.b.disable_autoformat = true` | buffer var, custom flag for conform.nvim |
| `vim.opt.number` | `vim.opt.number = true` | option, show line numbers |
| `vim.bo.filetype` | `vim.bo.filetype` | buffer option, get current filetype |
| `vim.wo.wrap` | `vim.wo.wrap = false` | window option, disable line wrap |
| `vim.v.event` | `vim.v.event.regcontents` | vim predefined, yank event data |

> `vim.opt` vs `vim.o`: `vim.opt` returns a special object with `:get()`, `:append()`, `:prepend()`, `:remove()`. `vim.o` is simpler direct access. For setting simple values they're interchangeable.

---

### Terminal escape sequences cheat sheet

Escape sequences control terminal behavior. Two main types: **CSI** (Control Sequence Introducer) for cursor/display and **OSC** (Operating System Command) for terminal features.

| Type | Command | Breakdown | What it does |
|------|---------|-----------|--------------|
| CSI | `printf '\e[2J'` | `\e[` + `2` + `J` | clear entire screen (`J`=erase, `2`=all) |
| CSI | `printf '\e[10;5H'` | `\e[` + `10;5` + `H` | move cursor to row 10, col 5 (`H`=position) |
| CSI | `printf '\e[31mRed\e[0m'` | `\e[` + `31` + `m` | set text red (`m`=SGR, `31`=red fg) |
| CSI | `printf '\e[0m'` | `\e[` + `0` + `m` | reset all attributes (`0`=reset) |
| CSI | `printf '\e[2 q'` | `\e[` + `2` + ` q` | set cursor to block (`q`=cursor shape) |
| CSI | `printf '\e[5 q'` | `\e[` + `5` + ` q` | set cursor to bar/beam |
| CSI | `printf '\e[?25l'` | `\e[` + `?25` + `l` | hide cursor (`l`=low/off) |
| CSI | `printf '\e[?25h'` | `\e[` + `?25` + `h` | show cursor (`h`=high/on) |
| OSC | `printf '\e]0;My Title\a'` | `\e]` + `0;` + `title` + `\a` | set window title |
| OSC | `printf '\e]9;%s\e\\' "msg"` | `\e]` + `9;` + `msg` + `\e\\` | desktop notification (works over SSH) |
| OSC | `printf '\e]52;c;%s\a' "$(echo -n 'hello' \| base64)"` | `\e]` + `52;c;` + `BASE64` + `\a` | copy to clipboard |

**Key:**
- `\e` or `\033` = ESC (0x1B)
- `\a` or `\007` = BEL (terminates OSC)
- CSI ends with a letter (`J`, `H`, `m`, `q`, `l`, `h`)
- OSC ends with BEL (`\a`) or ST (`\e\\`)

**SGR (Select Graphic Rendition) codes for `\e[...m`:**

| Code | Effect | Code | Effect |
|------|--------|------|--------|
| `0` | reset all | `1` | bold |
| `30-37` | fg colors | `40-47` | bg colors |
| `38;5;N` | 256-color fg | `48;5;N` | 256-color bg |
| `38;2;R;G;B` | truecolor fg | `48;2;R;G;B` | truecolor bg |

**Example combining:** `\e[1;31m` = bold + red, `\e[38;2;255;100;0mOrange\e[0m` = truecolor orange then reset

**OSC 52 clipboard breakdown:**

```
printf '\e]52;c;%s\a' "$(echo -n 'hello' | base64)"
        │ │  │ │       │                   │
        │ │  │ │       │                   └─ base64 encode (required by spec)
        │ │  │ │       └─ substituted into %s
        │ │  │ └───────── \a = BEL, "end of message"
        │ │  └─────────── c = clipboard target (c=clipboard, p=primary, s=select)
        │ └────────────── 52 = clipboard operation (xterm assigned number)
        └──────────────── \e] = OSC introducer ("hey terminal, incoming command")
```

Why base64? The clipboard content might contain special characters that would break the escape sequence. Base64 ensures it's safe ASCII.

Works over SSH because the escape sequence travels through the terminal stream back to your *local* terminal (kitty/wezterm/etc) which handles the actual clipboard.

Ref: https://terminalguide.namepad.de/seq/osc-52/

---

### Revisiting folding
So can do it like this (with LSP)
```lua
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'v:lua.vim.lsp.foldexpr()'
```

See `:h vim.lsp.foldexpr()` for more details on how it works

An interactive way to see it for current line is
```lua
:echo v:lua.vim.lsp.foldexpr(line('.'))
```

Whereby `line('.')` is current line (see `:h :line()`) and the `vim.lsp.foldexpr()` takes an arg of the current line number

To use treesitter it must be
```lua
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
```
see https://neovim.io/doc/user/treesitter.html#vim.treesitter.foldexpr()

Similarly, can test it with 
```lua
echo v:lua.vim.treesitter.foldexpr(line('.'))
```

#### foldlevel / foldlevelstart

`foldlevel` is the **active threshold** for a buffer — folds deeper than N are closed.

```
foldlevel=0   → all folds closed
foldlevel=1   → only level-1 folds open
foldlevel=99  → everything open
```

`foldlevelstart` sets the initial `foldlevel` when a buffer opens. Default is 0 (all closed).

```lua
vim.opt.foldlevelstart = 99  -- start with all folds open
```

---

### Treesitter and folding
Ok so claude came up with a very interesting note about treesitter and how it supports folding.

Treesitter has flags for types of treesitter (nodes?) on which to do folds. For SQL this is https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/sql/folds.scm here where it is JUST `statement` notes. (`WITH`, `SELECT`) i believe but not including union selects?

So if i go into a `sql` file with `select * .... union all select` the second `select` is NOT a statement hence can't fold on it!

So have some options:
- use LSP for SQL?
- override treesitter to add fold commands for union/select?

> also need to add fallback to indent for `:LspInfo` which is of filetype `checkhealth` no supported by treesitter or LSP (i assume)

Also.... trying out the `sqls` and `sqlls` couldnt get folding to work?

Well.... checking out https://neovim.io/doc/user/lsp.html it says you need "textDocument/foldingRange" to support folding?

And with `sqlls` I tried:
```vim
:redir >pls.txt
:lua =vim.lsp.get_active_clients()[1].server_capabilities
:redir END
```
And couldnt see it there....

Claude wrote me this a custom fallback function for folding myself?
```lua
function CustomFoldExpr()
  local lnum = vim.v.lnum
  local buf = vim.api.nvim_get_current_buf()
  local ts_ok, ts_result = pcall(vim.treesitter.foldexpr)
  if ts_ok and ts_result ~= '0' and ts_result ~= 0 then
    vim.b[buf].fold_provider = 'treesitter'
    return ts_result
  end
  vim.b[buf].fold_provider = 'indent'
  local indent = vim.fn.indent(lnum)
  local sw = vim.bo[buf].shiftwidth
  if sw == 0 then
    sw = vim.bo[buf].tabstop
  end
  return math.floor(indent / sw)
end

function ShowFoldProvider()
  local provider = vim.b.fold_provider or 'unknown'
  vim.notify('fold provider: ' .. provider, vim.log.levels.INFO)
  return provider
end

vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.CustomFoldExpr()'
```

---

### Treesitter folding quirk with multi-line signatures
`vim.treesitter.foldexpr()` breaks fold hierarchy when a function has a multi-line signature. Example:
```python
    def parse_st8_bet_data(   # foldexpr: >3 (starts level 3 fold)
        self,                  # foldexpr: 3
        record: ArchiveRecord, # foldexpr: 3
    ) -> ParseResult:          # foldexpr: 3
        try:                   # foldexpr: >3 (starts NEW level 3 fold)
```

The `parameters` treesitter node spans multiple lines, inflating the fold level to 3 (class > func > parameters). When `parameters` ends, the foldexpr never drops back to level 2 before `try_statement` starts its own `>3`. Vim sees two separate level-3 folds rather than a level-2 fold containing a level-3 fold.

Result: closing the function fold only collapses the signature (lines 108-111), not the body. The `try` block is a separate fold at the same level.

Key foldexpr syntax (`:h fold-expr`):
- `>N` = **start** a new fold at level N
- `N` = continue at level N
- `<N` = end a fold at level N

Useful built-in level commands:
- `zm`/`zr` = increment/decrement foldlevel by 1
- `zM`/`zR` = close/open all folds
- `:set foldlevel=N` = close all folds deeper than N

Single-line signatures fold correctly. This is **not** a treesitter parser bug - the parser correctly nests `try_statement` inside `function_definition`. The bug is in **neovim's `vim.treesitter.foldexpr()`** which translates the tree into fold levels. It counts `parameters` as a foldable multi-line node at the same depth as `try_statement` (both direct children of `function_definition`), so it assigns them the same level instead of treating the function body as deeper than the signature. LSP folding (`vim.lsp.foldexpr()`) may handle it better but LSP fold support varies by server.

---

## Neovim misc
### Buffers
Ok, time to start making some notes on neovim, will be a long journey I'm sure

To start with buffers
- telescope has `space space` to view buffers
- `echo bufnr()` (or `echo bufname()` to view buffer name)
- view `help buffers` to view vim's help
- according to claude, `ctrl-g` is also view buffer number?

This is however false, as i found out!

> to view vim's list of all commands do `:help index`. then can search for `ctrl-g` and see the following line
```
|CTRL-G|	CTRL-G		   display current file name and position
```

Right I FINALLY know what the buffer things mean in vim

> (yes i know i could have just done `:h buffers` all this time...)

But, `h` is hidden, `a` is active and 

Ahhh and unlisted buffers! that's where help, outline, aerial lazy etc put their buffers! makes sense now.

To view just to `:buffers!` with the exclamation mark

### Command redirection
see `:help redir`
e.g.
```
:redir >pls.txt
```
then
```
:registers
```
then
```
:redir END
```


### Type hints
So... type hints in lua are.. interesting, why they couldnt just use typescripts way? 😠

Turns out i can configure the lua language server DIRECTLY.

TODO
I need to research this more, but can configure `workspace.library`?
e.g. from claude? if i wanted to set some types file for a lib?
```
{
  "workspace.library": ["./yazi_types.lua"]
}
```

But i actually already have lazydev installed, which according to claude helps as it can
- adds nvim library stuffs to lua (guess would be nightmare trying to do myself)

> already added wezterm types in there

### Finding commands
With my neovim setup based on kickstart, i have `leader(space)-s-k` to search commands

But in general (from claude 😆)

```vim
  :help index           " All commands overview
  :help normal-index    " Normal mode commands
  :help insert-index    " Insert mode commands
  :help visual-index    " Visual mode commands
  :help ex-cmd-index    " Ex commands (:commands)
```

:help index is the closest to "view all keybindings" - it shows built-in Vim commands organized by mode.

For your custom mappings, use:
```vim
:nmap    " normal mode
:imap    " insert mode
:vmap    " visual mode
```


nice, `cat pls.txt` gives:
```bash
Type Name Content
  l  ""   |CTRL-G|^ICTRL-G^I^I   display current file name and position^J
  l  "0   |CTRL-G|^ICTRL-G^I^I   display current file name and position^J
  l  "1     "$schema": "/etc/xdg/swaync/configSchema.json",^J
.................
```

### Lua
so lua in neovim has alot of ways to interact with vim itself, here some of the main ones
```vim
vim.api        -- Low-level Neovim API (buffers, windows, keymaps)
vim.lsp        -- LSP client functions
vim.diagnostic -- Diagnostics (errors, warnings)
vim.fn         -- Call Vimscript functions from Lua
vim.keymap     -- Set keymaps (nicer than vim.api.nvim_set_keymap)
vim.opt        -- Set options (like set number, set mouse=a)
vim.cmd        -- vim commands?
```

but also, given that extensions/plugins must register commands with vim itself to be able to call

e.g.
```vim
  vim.api.nvim_create_user_command('HelloWorld', function()
    print('Hello from Lua!')
  end, {}
```

registers `HelloWorld` with vim itself (but defined in lua)? so we can call `:HelloWorld`

One useful link for documentation on [lua type hints is here](https://luals.github.io/wiki/annotations/)

### Lsps
It seems that most lsp configs are NOT typed. i guess that calling
```lua
require('lspconfig')[server_name].setup(server)
```

would be difficult to type all of them?

BUT all the configurations can be found [here](https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#lua_ls), just have to dig through the docs normally

Now i couldn't get luals to give type hints to work, and `lazydev` docs are about as useful as a sack of potatoes, so I'm digging through myself. (with some help from claude)

Now
- neovim's state is installed to `~/.local/share/nvim`
- once again 0 documentation about this very helpfully, found out the `lua ls` from mason is at `~/.local/share/nvim/mason/bin/lua-language-server`
- soooo, running ``~/.local/share/nvim/mason/bin/lua-language-server --help`, found out can add `--loglevel=debug` to cmd args!

I've yet to figure out how to put this into my own "standard" lib, but having a utility to deep print all lua object  properties.... welllll turns out thats `vim.inspect` 😆. but will put it here for my own learnings
```lua
local function printer_util(entry)
	local function inner(key, value, indent)
		if type(value) == "table" then
			print(string.rep("  ", indent) .. tostring(key))
			for k, v in pairs(value) do
				inner(k, v, indent + 1)
			end
		else
			print(string.rep("  ", indent) .. tostring(key) .. ": " .. tostring(value))
		end
	end
	inner("_", entry, 0)
end
```

### Understanding the docs
Can use `:h notation` to see how the neovim documentation refers to stuff like option chars in `[]` (e.g. `:mes[sages]` could be `:mes` or `:messages`)

Another good one is `:helpgrep` for searching through the help. Although finding help (sections NOT searching) is provided by telescope via `<LEADER>-s-h`


Another one is `:h key-notation`.

> something to note is its not mentioned anywhere epxlicitly that sometimes in the docs they use `caret notation`, like `^V` for `ctrl-v`

Didn't know  about execution mode `gQ` either, pretty cool for re-running commands

### Tags
Just do `:h tagsrch` honestly (short for tag and special search)
Apparently calling `:ta[g]` is the same as `C-]`

soooo
`C-]` = `:tag` = `:ta`

Also can name tag to go to? like `:tag help` to go to help tag

So tags are not that fancy after all, just `*tag_here*`. like in the outline help can use `c-]` on `outline-prerequisites` to jump to the tag, but unformatted text is just like this!

```txt
➜ jollof ~ cat /home/jollof/.local/share/nvim/lazy/outline.nvim/doc/outline.txt

*outline.txt*             For NVIM v0.7.0

==============================================================================
Table of Contents                                  *outline-table-of-contents*

  - Prerequisites                                      |outline-prerequisites|
  - Installation                                        |outline-installation|
  - Setup                                                      |outline-setup|
  - Configuration                                      |outline-configuration|
  - Providers                                              |outline-providers|
  - Commands                                                |outline-commands|
  - Default keymaps                                  |outline-default-keymaps|
  - Highlights                                            |outline-highlights|
  - Lua API                                                  |outline-lua-api|
  - Tips                                                        |outline-tips|
  - Recipes                                                  |outline-recipes|
  - Neovim 0.7                                            |outline-neovim-0.7|
  - Limitations                                          |outline-limitations|
  - Related plugins                                  |outline-related-plugins|
------------------------------------------------------------------------------

PREREQUISITES                                          *outline-prerequisites*
```

Vim stores these in files (somewhere) to keep an index of tags so can jump between files


### Registers
`stressed-boomer`

Ahhhh finally, i should have googled this a LONG time ago.

The black hole register means the data dies, so can delete without putting it into the register!.

e.g. `"_d` to delete to black hole register

oh this is cool!
```
:let @{reg-name} = {expr1}			*:let-register* *:let-@*
			Write the result of the expression {expr1} in register
```

Like.... erm?
```vim
:let @a = bufnr()
```

to set buffer `a` to buffer number? couldn't think of a better example ‍‍🤷


Like.... erm?
```vim
:let @a = bufnr()
```

to set buffer `a` to buffer number? couldn't think of a better example ‍‍🤷

The `+` register is `quoteplus` which apparently is the system clipboard?
So can do
```vim
let @+ = "hello there pls"
```

To set a string to clipboard

### Tabs
Didn't realise this b ut I can use `:1tabn` to go to tab 1 and `:4tabn` to go to tab 4 etc
This is also equiv to `1gt`

Also I can stop doing `:tabnew` and then `:help ...`

And just (if I'd bothered to do this before lol 🤣 `:h :tab`)
```vim
:tab :help ...
```

### Misc
**Pipe**

So `:help :bar` will explain but can show an example that makes more sense:
```vim
:tabnew | :h buffers
```

Will notice above that the help is in the bottom half of the window if this is called. I.e. the commands are chained NOT piped. My interpretation of this is
1. open a new tab
2. open help for buffers

Ok wow this example taught me alot:
```vim
:execute 'r !ls' | '[
```

read i guess takes not file file name but also bash commands to read in?

And then (remember `|` is NOT pipe but chaining commands), go to mark `[` which is beginning of yank or previously unchanged text (i.e. top of output in english)

> remember that ' is for marks

**Set**

So set sets an option but would be interesting to see a test.

I actually have `relativenumber` set in my `init.lua` but I think some plugins must be overriding because when i call `set relativenumber?` to retrieve its blank!

Something more simple is the `:set timeoutlen?` gets me the `timeoutlen = 300` value

**Messages**

Really need to read into this more, but `:NoiceAll` has more messages.
According to claude `:redraw` can help flush messages? although that doesn't make sense to me as this is Noice and NOT vim internally

**Delete Command**
FML..... I was reading the wrong command
`:[range]d register`
wondering why it wasn't working.

but this, `:d` is DIFFERENT to `d`, as it is an execution/command

TODO
- read [this](https://github.com/folke/noice.nvim/wiki/A-Guide-to-Messages), noice guide on msgs
- have a read through `:help ui-messages`

**Execute**
Thanks clude, i didn't understand this myself...

Literally just executing stringified expressions, but vim expressions (not terminal).

Like, lets combine a register?

So earlier I was playing around with setting registers. `:echo getreg('a')` prints 3, the buffer name I set earlier.

So then to open the tab with a buffer from register `a` can do
```vim
:execute "buffer" getreg('a')`
```

Or another one(I suppose as we are technically in cmd mode `gg` wouldn't work without the `normal` prefix)
```vim
:execute "normal! gg"              " Runs normal mode commands
```

**Commands vs functions vs expressions**
An important distinction here is that `getreg` is a vim **function**, NOT a command

- functions cannot be called like `:` as commands are
- functions can return values
- functions must be invoked like `run_function()` with parenthesis

Or wait, I (think) command is a bit ambiguous here? A command being like `:e` or `:reg` etc etc.

Ok doing `:h vimeval.txt` would be a good read as it covers vim expressions and its syntax which is pretty key to understanding all of this long term

This table is a super useful reference point from `:help expression` to see how to access different types of vars/registers etc
```vim
|expr9|	number			number constant
	"string"		string constant, backslash is special
	`'string'`		string constant, ' is doubled
	[expr1, ...]		|List|
	`{expr1: expr1, ...}`	|Dictionary|
	#{key: expr1, ...}	|Dictionary|
	&option			option value
	(expr1)			nested expression
	variable		internal variable
	va{ria}ble		internal variable with curly braces
	$VAR			environment variable
	@r			contents of register "r"
	function(expr1, ...)	function call
	func{ti}on(expr1, ...)	function call with curly braces
	`{args -> expr1}`	lambda expression
```

**Eval**
To show here a good usecase, it clearly says in the docs that `:h :echo` that you `:echo {expr}` i.e. echo and expression
So `:echo 4+5` is 9. where 4+5 is the expression

Or, could have done `:echo eval("4+5")` to achieve the same thing

So...
- `:execute` executes a string (command written as text). e.g `:execute 'normal gg'`
- `:echo` executes an expression and prints the result e.g. `:echo x` to print variable `x`
- `eval` executes a string (expression written as text). e.g. `eval("x")` would retrieve variable `x` 


**History**
Wow must NOT forget these, command line history and search history respectively!
- `q:`
- `g/`

### Regexps
Ok so I (roughly) understand what this magic stuff is about in regexp

Can see from `:set magic?` that its `magic` (and NOT `nomagic`, strange syntax choice here from vim that `true` is `:set magic` and false is `:set nomagic`)... so the `no` is the invert bit?

So the default behaviour is to take everything literally, like brackets (), pipe | etc...

The only exception I have see is `/` which is the last pattern (ok this is much quicker than doing `/` and then up to find last pattern tbf). also backslash `\` must always be escaped

Ok so default is 'magic':

- in magic, in general stuff must be escaped (like `\.` for literal dot)
- `\m` forces magic mode (e.g. `\m\.` forces magic modes and searches for literal dot)
- in "no magic" (NOT default), magic characters are generally off (just `.` for literal dot)
- `\M` forces no magic mode (e.g. `\M.` forces no magic mode and searches for literal dot)

Additional modes
- "very" magic, even `(` and `)` literals must be escaped
> this one is SO annoying. given the default is sort od regexp EXCEPT for braces 👿
- `\v` triggers "very" magic, e.g. `\v\(` to search for `(` char
- the default is `(` just to search for `(` char

- "very" not magic, even `\$` is required
- `\V` to trigger "very" not magic


### Mappings
I ALWAYS get lost looking at the strange mapping syntax in vim `nnnoommapremap` shite. So i got claude to write me a diagram of the `i` (for insert), vs `no` for no remapping and various combinations....

| Command | Mode | Description |
|---------|------|-------------|
| `nmap` | **n**ormal | When you're just moving around |
| `imap` | **i**nsert | When you're typing text |
| `vmap` | **v**isual | When you've selected text |
| `xmap` | e**x**tended visual | Visual block mode (strict visual) |
| `omap` | **o**perator-pending | After d, c, y, etc |
| `smap` | **s**elect | Select mode (like visual but different) |
| `cmap` | **c**ommand-line | When typing `:commands` |
| `tmap` | **t**erminal | In terminal buffer |


#### Special Combinations
| Command | Modes | Description |
|---------|-------|-------------|
| `:map` | n, v, o | Works in normal, visual, and operator-pending |
| `:map!` | i, c | Works in insert and command-line modes |

> The `no` in `noremap`

**"no" = "NO remap"** — it means **disable remapping** of the right-hand side. The "no" is a prefix meaning "don't allow remapping".

#### :map vs :noremap — The Key Difference

### :map (allows remapping)
```vim
:map a b
:map b c
```
**You press:** `a`
- → remapped to `b`
- → remapped again to `c`
- **Result:** `c` executes

⚠️ Can cause chains and loops!

#### :noremap (disables remapping)
```vim
:noremap a b
:map b c
```
**You press:** `a`
- → mapped to `b` (literal, won't scan again)
- **Result:** `b` executes

✓ Safe and predictable!

#### All the `noremap` variants

| Command | Mode | Description |
|---------|------|-------------|
| `nnoremap` | normal | No remap |
| `inoremap` | insert | No remap |
| `vnoremap` | visual | No remap |
| `xnoremap` | visual block | No remap |
| `onoremap` | operator-pending | No remap |
| `snoremap` | select | No remap |
| `cnoremap` | command-line | No remap |
| `tnoremap` | terminal | No remap |

**Why this matters:** when a Vim mapping like `['<C-/>']` silently does nothing, or `<C-[>` behaves identically to `<Esc>`, the cause is almost always a mismatch between what *you think* the keypress sends and what the terminal *actually* sends.

### The ASCII table in two halves

```
 Dec  Hex  Char          Dec  Hex  Char
────────────────────    ────────────────────
  0   0x00  NUL    ◄──    64  0x40  @
  1   0x01  SOH    ◄──    65  0x41  A
  2   0x02  STX    ◄──    66  0x42  B
  ...                     ...
  8   0x08  BS     ◄──    72  0x48  H     (Ctrl+H = Backspace)
  9   0x09  TAB    ◄──    73  0x49  I     (Ctrl+I = Tab)
  10  0x0A  LF     ◄──    74  0x4A  J     (Ctrl+J = Enter/newline)
  13  0x0D  CR     ◄──    77  0x4D  M     (Ctrl+M = Enter)
  ...                     ...
  27  0x1B  ESC    ◄──    91  0x5B  [     (Ctrl+[ = Escape !)
  28  0x1C  FS     ◄──    92  0x5C  \
  29  0x1D  GS     ◄──    93  0x5D  ]
  30  0x1E  RS     ◄──    94  0x5E  ^
  31  0x1F  US     ◄──    95  0x5F  _     (Ctrl+_ = 0x1F)
────────────────────
 0-31: CONTROL codes      32-126: printable text
```

The **left column (0–31)** is not printable — these are control signals (move cursor, ring bell, etc). The **right column (64–95)** is the `@A-Z[\]^_` block of printable ASCII.

### The rule: Ctrl clears bits 6 and 7

Pressing `Ctrl` with a character in the `@`–`_` range (ASCII 64–95) **masks off the top 2 bits**, leaving only the bottom 5:

```
  Ctrl + [   =   '[' AND 0b00011111
                   │
  '[' = 91 = 0b 0 1 0 1 1 0 1 1
                   │
  mask  =    0b 0 0 0 1 1 1 1 1   ← keep only bottom 5 bits
                   │
  result =   0b 0 0 0 1 1 0 1 1  =  27  =  0x1B  =  ESC  ✓
```

The pattern is symmetric: each letter in `@`…`_` is **exactly 64 higher** than its control code, and 64 = `0b01000000` — bit 6. Masking it off is the same as subtracting 64.

```
  Ctrl + _   =   '_' AND 0b00011111

  '_' = 95 = 0b 0 1 0 1 1 1 1 1
  mask  =    0b 0 0 0 1 1 1 1 1
  result =   0b 0 0 0 1 1 1 1 1  =  31  =  0x1F  =  US  (Unit Separator)
```

### Quick reference: surprising aliases

| You press | ASCII of key | AND 0x1F | Byte sent | Vim name | Common name |
|-----------|-------------|----------|-----------|----------|-------------|
| `Ctrl+@`  | 64 (`@`)   | 0        | `0x00`   | `<C-@>`  | NUL         |
| `Ctrl+H`  | 72 (`H`)   | 8        | `0x08`   | `<C-H>`  | Backspace   |
| `Ctrl+I`  | 73 (`I`)   | 9        | `0x09`   | `<C-I>`  | Tab         |
| `Ctrl+J`  | 74 (`J`)   | 10       | `0x0A`   | `<C-J>`  | Newline     |
| `Ctrl+M`  | 77 (`M`)   | 13       | `0x0D`   | `<C-M>`  | Enter/CR    |
| **`Ctrl+[`**  | **91 (`[`)**   | **27**       | **`0x1B`**   | **`<C-[>`**  | **Escape ← !!**    |
| `Ctrl+\`  | 92 (`\`)   | 28       | `0x1C`   | `<C-\>`  | FS          |
| `Ctrl+_`  | 95 (`_`)   | 31       | `0x1F`   | `<C-_>`  | US          |

!!! warning "This means `<C-[>` IS `<Esc>` — always"
    They produce the exact same byte (`0x1B`). You cannot map `<C-[>` to do something different from `<Esc>` in a legacy terminal — they are identical. Kitty's extended keyboard protocol *can* distinguish them, but only if both the terminal and the application (Neovim, Telescope) opt in.

### The `C-/` edge case

`/` is ASCII 47, which is **below 64** — outside the clean `@`–`_` range. The AND rule gives `47 & 31 = 15` (`0x0F`), not `0x1F`. So why do most terminals send `0x1F` for `Ctrl+/`?

On a US keyboard, `/` and `?` share the same physical key. When applying a Ctrl modifier to a key outside the normal range, many terminals use the **shifted** variant of that key instead:

```
  '?' = 63 = 0b 0 0 1 1 1 1 1 1   ← shifted '/' on US keyboard
  mask  =    0b 0 0 0 1 1 1 1 1
  result =   0b 0 0 0 1 1 1 1 1  =  31  =  0x1F
```

`0x1F` is the same byte as `Ctrl+_`. So `Ctrl+/` and `Ctrl+_` arrive at Neovim **as the same byte**, and Neovim represents it as `<C-_>`.

!!! danger "This is why `['<C-/>'] = 'to_fuzzy_refine'` silently failed in Telescope"
    The mapping was registered under the name `<C-/>`, but the terminal sent byte `0x1F` which Neovim labels `<C-_>`. Two different names, same physical key, no match → fell through to Telescope's default `<C-/>` handler (which_key).

    Fix: map **both** names:
    ```lua
    ['<C-/>'] = 'to_fuzzy_refine',
    ['<C-_>'] = 'to_fuzzy_refine',  -- what the terminal actually sends
    ```

### Verify what your terminal actually sends

Press a key in insert mode and insert the raw byte with `Ctrl+V`:

```vim
" In insert mode, press Ctrl+V then your key — shows the literal char
" e.g. Ctrl+V then Ctrl+[ inserts a literal ESC glyph (^[)
```

Or check with `cat` in a shell — it prints the raw bytes:

```bash
cat          # start cat
^/           # press Ctrl+/, see what appears — likely shows as '^_' (0x1F)
^[           # press Ctrl+[, shows as '^[' (0x1B = ESC)
^C           # Ctrl+C to quit
```

Or inspect the actual hex:

```bash
# Type the key, press Enter, Ctrl+D
xxd | head -1
# e.g. Ctrl+[ + Enter shows:  0000000: 1b0a  ..
#                                       ↑↑
#                                       1b = ESC = Ctrl+[
```
