---
title: "Neovim surround examples"
---

# Neovim surround examples

The final `)` in `saiw)` is a **mini.surround identifier for a parentheses pair**:
insert `(` on the left and `)` on the right. The final `x` in `saiwx` uses the
plugin's literal fallback: insert `x` on both sides.

Both characters are interpreted by mini.surround in that position. They are not
ordinary Vim commands such as `x` for deleting a character.

```text
sa | iw | )
add | inner word | parentheses pair

sa | iw | x
add | inner word | literal x on both sides
```

All examples use this config's default mini.surround mappings. Start in **normal
mode** with the cursor on the **h in hello**, unless stated otherwise. Spaces and
`|` separators in breakdowns are explanatory: **do not type them**. No leader key
is involved.

## Which part comes from where?

| Layer | Examples | Job | Documentation |
| --- | --- | --- | --- |
| Vim's visual modes | `v`, `V` | Start selecting characters or whole lines | [Visual mode](https://neovim.io/doc/user/visual/) |
| Vim's text objects | `iw`, `i(`, `a(` | Describe a region of text | [Text objects](https://neovim.io/doc/user/motion/#text-objects) |
| Vim's motions | `$`, `{`, `3l` | Describe movement from the cursor | [Motions and operators](https://neovim.io/doc/user/motion/) |
| mini.ai | Enhances objects such as `i(` and `a(` | Improves how regions are found; configured separately from mini.surround | [mini.ai](https://nvim-mini.org/mini.nvim/doc/mini-ai.html) |
| mini.surround | `sa`, `sd`, `sr` | Add, delete, or replace wrappers | [Surround actions](https://nvim-mini.org/mini.nvim/doc/mini-surround.html#example-usage) |

For example, `va(` is Vim's visual selection plus the "around parentheses" text
object, enhanced here by mini.ai. It does not require mini.surround.

The selection language is reusable: `viw` selects an inner word, `diw` deletes
one, `yiw` copies one, and `saiw)` adds parentheses around one.

## Step 1: choose the action

| Keys | Meaning | Next input | Final input |
| --- | --- | --- | --- |
| `sa` | Surround add | Which text? | What new wrapper? |
| `sd` | Surround delete | Which existing wrapper? | Nothing else |
| `sr` | Surround replace | Which existing wrapper? | What replacement wrapper? |

These actions come from [mini.surround](https://nvim-mini.org/mini.nvim/doc/mini-surround.html#example-usage).
Add needs a region because its wrapper does not exist yet. Delete and replace
find an existing enclosing wrapper around the cursor.

## Step 2 for add: choose the text

These selectors are called **text objects**:

| Keys | Meaning | With the cursor on hello in `(hello world)` | Documentation |
| --- | --- | --- | --- |
| `iw` | Inner word | `hello` | [Vim: iw](https://neovim.io/doc/user/motion/#iw) |
| `aw` | Word plus adjacent whitespace | `hello ` | [Vim: aw](https://neovim.io/doc/user/motion/#aw) |
| `i(` | Inside parentheses | `hello world` | [Vim: i(](https://neovim.io/doc/user/motion/#i%28) |
| `a(` | Parentheses and their contents | `(hello world)` | [Vim: a(](https://neovim.io/doc/user/motion/#a%28) |
| `i{` / `a{` | Inside / including braces | Same distinction for `{…}` | [Vim text objects](https://neovim.io/doc/user/motion/#text-objects) |
| `i"` / `a"` | Inside / including double quotes | Same distinction for `"…"` | [Vim text objects](https://neovim.io/doc/user/motion/#text-objects) |
| `ip` | Inner paragraph | The paragraph containing the cursor | [Vim: ip](https://neovim.io/doc/user/motion/#ip) |

A **motion** is another way to supply text to an action:

| Motion | Text covered after an action | Documentation |
| --- | --- | --- |
| `$` | From cursor to end of line | [Vim motions](https://neovim.io/doc/user/motion/) |
| `{` | Backward to a paragraph boundary | [Vim paragraphs](https://neovim.io/doc/user/motion/#paragraph) |
| `3l` | Three characters moving right | [Vim: l](https://neovim.io/doc/user/motion/#l) |

Bare `{` and `a{` are different: `{` moves backward by paragraph; `a{` identifies
an existing brace-delimited region. Similarly, bare `(` is a backward-sentence
motion; it does not select parentheses.

## Step 3 for add: choose the new wrapper

This table describes **mini.surround's interpretation**, not Vim's normal-mode
meaning for the same characters.

| Final identifier | Interpretation | Left inserted | Right inserted | Selected hello becomes |
| --- | --- | --- | --- | --- |
| `)` | Special: parentheses pair | `(` | `)` | `(hello)` |
| `(` | Special: padded parentheses | `( ` | ` )` | `( hello )` |
| `]` | Special: brackets pair | `[` | `]` | `[hello]` |
| `[` | Special: padded brackets | `[ ` | ` ]` | `[ hello ]` |
| `}` | Special: braces pair | `{` | `}` | `{hello}` |
| `{` | Special: padded braces | `{ ` | ` }` | `{ hello }` |
| `"` | Literal character on both sides | `"` | `"` | `"hello"` |
| `*` | Literal character on both sides | `*` | `*` | `*hello*` |
| `x` | Literal character on both sides | `x` | `x` | `xhellox` |
| `i` | Literal character on both sides | `i` | `i` | `ihelloi` |
| `?` | Special: prompt for both strings | First answer | Second answer | Whatever you specify |

Source: [mini.surround's built-in surroundings](https://nvim-mini.org/mini.nvim/doc/mini-surround.html#builtin-surroundings).
There are other special identifiers, including `f` for function calls and `t` for
tags. Letters are not universally literal: `x` and `i` specifically use the
literal fallback in this default configuration.

## Add: full before/after table

| Full command | Action and target | Final character's meaning | Before → after |
| --- | --- | --- | --- |
| `saiw)` | `sa` + `iw`: add around inner word | Pair `()` | `hello` → `(hello)` |
| `saiw(` | `sa` + `iw`: add around inner word | Padded parentheses | `hello` → `( hello )` |
| `saiw}` | `sa` + `iw`: add around inner word | Pair `{}` | `hello` → `{hello}` |
| `saiw{` | `sa` + `iw`: add around inner word | Padded braces | `hello` → `{ hello }` |
| `saiw]` | `sa` + `iw`: add around inner word | Pair `[]` | `hello` → `[hello]` |
| `saiw"` | `sa` + `iw`: add around inner word | Literal `"` on each side | `hello` → `"hello"` |
| `saiw*` | `sa` + `iw`: add around inner word | Literal `*` on each side | `hello` → `*hello*` |
| `saiwx` | `sa` + `iw`: add around inner word | Literal `x` on each side | `hello` → `xhellox` |
| `saa(i` | `sa` + `a(`: including parentheses | Literal `i` on each side | `(hello)` → `i(hello)i` |
| `sai(i` | `sa` + `i(`: inside parentheses | Literal `i` on each side | `(hello)` → `(ihelloi)` |
| `saa(}` | `sa` + `a(`: including parentheses | Pair `{}` | `(hello)` → `{(hello)}` |
| `sai(}` | `sa` + `i(`: inside parentheses | Pair `{}` | `(hello)` → `({hello})` |
| `saa(*` | `sa` + `a(`: including parentheses | Literal `*` on each side | `(hello)` → `*(hello)*` |
| `sai(*` | `sa` + `i(`: inside parentheses | Literal `*` on each side | `(hello)` → `(*hello*)` |

There is no separate `saa` command. In `saa(i`, one `a` finishes `sa`, and the next
starts `a(`. The final `i` is a literal wrapper, not an insert-mode command:

```text
sa | a( | i
add | select including parentheses | insert literal i on both sides

sa | i( | i
add | select inside parentheses | insert literal i on both sides
```

For the note `(capital is across all files)`, `saa(i` produces
`i(capital is across all files)i`. `sa(i` instead uses the backward-sentence
motion and can reach back into preceding prose.

## Delete and replace: find an existing wrapper

After `sd` or `sr`, `)` means **find an enclosing parentheses pair**, not insert
one. A wrapper identifier describes the pair; the action determines what happens
to it. The documentation calls this an **input surrounding**, while the new
wrapper is an **output surrounding**.

Source: [mini.surround input and output surroundings](https://nvim-mini.org/mini.nvim/doc/mini-surround.html#builtin-surroundings).

| Command | Breakdown | Before → after |
| --- | --- | --- |
| `sd)` | Delete the existing `()` pair | `(hello)` → `hello` |
| `sd"` | Delete the existing quote pair | `"hello"` → `hello` |
| `sdx` | Delete existing literal `x…x` wrapping | `xhellox` → `hello` |
| `sr)"` | Replace old `()` pair with literal quotes | `(hello)` → `"hello"` |
| `sr)]` | Replace old `()` pair with new `[]` pair | `(hello)` → `[hello]` |
| `sr")` | Replace old quotes with new `()` pair | `"hello"` → `(hello)` |
| `sr)i` | Replace old `()` pair with literal letters | `(hello)` → `ihelloi` |

There is no `iw` or `a(` step after `sd`: the enclosing wrapper already defines
the boundaries. Only its two ends are removed; its contents remain.

## Visual selection: choose the text first

`v` and `V` come from [Vim's Visual mode](https://neovim.io/doc/user/visual/).
Once text is selected, `sa` needs only the new wrapper. Pause after the selection
step to inspect the highlight.

| Full command | Vim selection first | mini.surround part | Before → after |
| --- | --- | --- | --- |
| `vsa}` | `v`: current character only | `sa}`: add `{}` | `hello` → `{h}ello` |
| `viwsa}` | `v` + `iw`: inner word | `sa}`: add `{}` | `hello` → `{hello}` |
| `vi(sa}` | `v` + `i(`: inside parentheses | `sa}`: add `{}` | `(hello)` → `({hello})` |
| `va(sa}` | `v` + `a(`: including parentheses | `sa}`: add `{}` | `(hello)` → `{(hello)}` |
| `Vsax` | `V`: whole line | `sax`: add literal x's | `hello world` → `xhello worldx` |

Typing just `v` initially selects one character. That is why `vsa{` wraps just
that character (with padded braces), rather than finding a word or parentheses.

### Why not saVx for the whole line?

The meaning of `V` depends on the mode:

- **Before `sa`:** `V` starts whole-line visual selection. `Vsax` works.
- **After `sa`:** Vim is waiting for a motion. `V` forces a following motion to
  be linewise; it does not finish the selection by itself. `saVx` is incomplete
  as a surround operation because `x` is not that motion.

See [Vim's forced-motion rules](https://neovim.io/doc/user/motion/#forced-motion).
An alternative without visual selection is `sa_x`: `_` supplies a linewise
motion over the current line.

### What does sa{x select?

`sa{x` means `sa` + backward-paragraph motion `{` + literal wrapper `x`.
It wraps the text traversed by the motion, with the starting cursor position
providing one boundary. It does not search for an opening brace.

For actual brace-delimited text, use `saa{x`: `{hello}` becomes `x{hello}x`.

## Multi-character wrappers

For more **selected text**, choose a larger text object, motion, or visual
selection. For a wrapper containing more than one character, use `?`.

Type `saiw?`, then answer the prompts:

```text
Left surrounding:  BEGIN  [Enter]
Right surrounding: END    [Enter]

hello → BEGINhelloEND
```

For Markdown bold, enter `**` at both prompts. Alternatively, `2saiw*` repeats
the wrapper twice and produces `**hello**`. The leading `2` repeats the wrapper;
it does not select two words.

See [mini.surround examples](https://nvim-mini.org/mini.nvim/doc/mini-surround.html#example-usage)
and [counts](https://nvim-mini.org/mini.nvim/doc/mini-surround.html#count-with-actions).

## Practice and further examples

Put `(hello world)` on a scratch line, with the cursor on hello:

1. Type `va(`, inspect the highlight, then `sa}`: `{(hello world)}`.
2. Undo with `u`, then type `sd)`: `hello world`.
3. Undo with `u`, then type `sr)]`: `[hello world]`.

This compares adding another layer, removing a layer, and replacing a layer on
the same text.

- [Official mini.surround video demo](https://nvim-mini.org/mini.nvim/readmes/mini-surround#demo)
- [Official mini.surround examples](https://nvim-mini.org/mini.nvim/doc/mini-surround.html#example-usage)
- [Neovim editing tutorial](https://neovim.io/doc/user/usr_04/)
- [Vim & Neovim reference](vim)

Tutorials for other surround plugins often use `ys`, `ds`, and `cs`. This config
uses mini.surround's `sa`, `sd`, and `sr`; the example commands above match those
bindings.
