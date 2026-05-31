# dev-setup

## Git / PRs

The bot account (`joels-claude-bot`) cannot push directly to `origin` — push feature branches to `bot-fork` instead, then open a PR targeting `joeledwardson/dev-setup`:

```sh
git push -u bot-fork <branch>
gh pr create --repo joeledwardson/dev-setup --head joels-claude-bot:<branch> ...
```
