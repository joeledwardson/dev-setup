---
created: 2025-09-01
updated: 2026-05-24
---

## Shell debugging
The `.zshrc` provides a debugging variable which uses `zprof` to log the load times when specified.

To use it, set:
```bash
export ZSH_DEBUGRC=true
```

---

## Bash scripting
### Heredocs
The `<<` is a `here-document` (NOT SUPPORED IN FISH! [see here](https://fishshell.com/docs/current/fish_for_bash_users.html#heredocs))

`here-document`s feed a command list to STDIN (hence why it wont work with echo, which doesnt read from stdin!)


e.g. count lines with `wc -l`  is a simple example to demonstrate using `heredoc` to feed 4 lines to stdin to `wc` and print line count
```bash
[joelyboy@desktop-work:~/coding/dev-setup]$ wc -l << 'ENDHEREPLS'
> line 1
> line 2
> line 3
> line 4
> ENDHEREPLS
4

[joelyboy@desktop-work:~/coding/dev-setup]$
```

### Herestring
The `<<<` is a here string.

Similarly to `heredoc`, it goes AFTER the command.

It seems pretty similar to piping input with echo, but i found with my `bw-view` and `bw-edit` functions that echo prints newlines!. Thus will break `jq` parsers

A simple demonstration below, we can see a multilint string is printed across multi lines (as expected) with `echo`, whereas with `<<<` it pipes directly in
> Another addition to using `grep |` is id does not create another process
```bash
➜ joelyboy dev-setup (main) ✗   json='{"note":"Line1\nLine2\tTabbed"}'  # Contains \n and \t
➜ joelyboy dev-setup (main) ✗ echo $json
{"note":"Line1
Line2   Tabbed"}
➜ joelyboy dev-setup (main) ✗ echo $json | jq
jq: parse error: Invalid string: control characters from U+0000 through U+001F must be escaped at line 2, column 13
➜ joelyboy dev-setup (main) ✗ echo "$json" | jq
jq: parse error: Invalid string: control characters from U+0000 through U+001F must be escaped at line 2, column 13
➜ joelyboy dev-setup (main) ✗ jq <<< "$json"
{
  "note": "Line1\nLine2\tTabbed"
}
➜ joelyboy dev-setup (main) ✗
```

Unlike `heredoc`, it only takes a stringle string and does NOT require a delimeter

### Color pipes
I've noticed that alot of linux utilities will not print colour if they thing they are being sent to a TTY terminal they don't print colour.

E.g. with `eza` need to add this and then colours will appear to force it
```bash
eza -l --color=always | xargs -I {} echo {}
```

> I guess the rationale is if the user is piping to another program, escape codes will show up as garbage in a text file for example

Another great example when trawling through syslogs is `dmesg` (seems that `--color=always` is a standardish unix option)
```bash
sudo dmesg --color=always | less
```
### Options
`getopts` is usedful, i (think) its just fancy iterator through bash $@ args?
e.g. checking a `-x` flag
```bash
➜ joelyboy dash (master) ✗ echo 'getopts x opt; echo $opt' > testie.sh
➜ joelyboy dash (master) ✗ ./testie.sh
?
➜ joelyboy dash (master) ✗ ./testie.sh -x
x
```


e.g. multi args (yes im too lazy to do it over multi line in while to make it clearer)
```bash
➜ joelyboy dash (master) ✗ echo 'while getopts xyz opt; do echo $opt; done' > testie.sh
➜ joelyboy dash (master) ✗ ./testie.sh -x
x
➜ joelyboy dash (master) ✗ ./testie.sh -xyz
x
y
z
➜ joelyboy dash (master) ✗
```

---

## Shell scripting
### `jq`
To start with, jq has the "identity" operator `.`, where `jq '.'` is equivalent to `jq`.

And by default it reads from stdin. Can see this just by running it

> That's me typing the inputs and `jq` echoing it back to me (formatted)


```bash
➜ jollof dev-setup (main) ✗ jq '.'
{"a": 1}
{
  "a": 1
}
{"b": 2}
{
  "b": 2
}
3
3
```

Or, can extract value of key "a" from user stdin:
```bash
➜ jollof dev-setup (main) ✗ jq '.a'
1
jq: error (at <stdin>:1): Cannot index number with string "a"
{"a": 4}
4
^C
➜ jollof dev-setup (main) ✗
```

which brings us neatly along to the merge operator, `*`, to combine objects together.


can see here it will take my stdin object and merge with `{a:1}`
```bash
➜ jollof dev-setup (main) ✗ jq '. * {"a": 1}'
{"b": 1}
{
  "b": 1,
  "a": 1
}
{"a": 9999}
{
  "a": 1
}
^C
➜ jollof dev-setup (main) ✗
```


this is NOT to be confused with the mathematical multiplication operator lmao
```bash
➜ jollof dev-setup (main) ✗ jq '. * 3'
10
30
100
300
^C
➜ jollof dev-setup (main) ✗
```


now the `-s` operator will join things together, so if i enter a few lines here to STDIN (then press `ctrl-d` to prompt end ofstdin) it will produce an array, rather than processing 1 by 1.
```bash
➜ jollof dev-setup (main) ✗ jq -s '.'

1
2
3
[
  1,
  2,
  3
]
➜ jollof dev-setup (main) ✗
```

another great example of heredoc! to pipe some lines of stdin to `jq` and see it process them (all as one!) so don't need to fanny around with multiple commands an `ctrl-d`
```bash
➜ jollof dev-setup (main) ✗ jq -s '.' <<EOF
{"a": 1}
{"b": 2}
EOF
[
  {
    "a": 1
  },
  {
    "b": 2
  }
]
➜ jollof dev-setup (main) ✗
```

and now using the full syntax of jq with
```
jq [options...] filter [files...]
```

can see it here

> without the `-s` its just processing `test1` and `test2` as 2 separate commands...?

```bash
➜ jollof dev-setup (main) ✗ echo '{"a": 1}' > /tmp/test1.json
➜ jollof dev-setup (main) ✗ echo '{"b": 2}' > /tmp/test2.json
➜ jollof dev-setup (main) ✗ jq '.' /tmp/test1.json
{
  "a": 1
}
➜ jollof dev-setup (main) ✗ jq '.' /tmp/test1.json  /tmp/test2.json
{
  "a": 1
}
{
  "b": 2
}
➜ jollof dev-setup (main) ✗ jq -s '.' /tmp/test1.json  /tmp/test2.json
[
  {
    "a": 1
  },
  {
    "b": 2
  }
]
➜ jollof dev-setup (main) ✗ jq -s '.' /tmp/test1.json  /tmp/test2.json
```
