# Releasing

How a release of neurovim.nvim is cut, as it was done for 0.1.0 (2026-10-10). Tags are SemVer without `v`. Forgejo (`origin`, git.jkaindl.de) is the primary remote, GitHub (`github`) the mirror lazy.nvim installs from; both are public.

## 1. Check

```bash
make check                # format, lint, tests on your Neovim, vendor-check
make test NVIM=/path/to/nvim-0.10.4/bin/nvim   # the minimum version (AGENTS.md § Commands)
make release-check        # Bibliothek gate over everything since the last tag (needs the Dach)
```

All three green, and the README passes the workspace's README lint (`readme_lint.py <repo>`, tier `nvim-plugin`) if you have the workspace. Outside the `nvim-plugins` Dach, `vendor-check` and `release-check` print `SKIPPED` — that is not a pass; release from inside the Dach.

## 2. Write the release down

- `CHANGELOG.md`: rename `## [Unreleased]` to `## [X.Y.Z] — YYYY-MM-DD` and add the link line `[X.Y.Z]: https://github.com/johannes-kaindl/neurovim.nvim/releases/tag/X.Y.Z` at the bottom.
- README status line and anything in `doc/neurovim.txt` that names a version or a state ("still private", "once …") — say what is true now.
- Commit (German, Conventional Commits) and push `main` to both remotes.

## 3. Tag and publish

```bash
git tag X.Y.Z <commit>          # lightweight, like nvim-kit's tags
git push origin X.Y.Z && git push github X.Y.Z
git ls-remote origin refs/tags/X.Y.Z; git ls-remote github refs/tags/X.Y.Z
```

Create a release on both forges with the CHANGELOG section as its text, through the REST APIs (GitHub's GraphQL may be throttled; `gh api` REST works): `POST /repos/johannes-kaindl/neurovim.nvim/releases` on api.github.com and `POST /api/v1/repos/jkaindl/neurovim.nvim/releases` on git.jkaindl.de, each with `{"tag_name": "X.Y.Z", "name": "X.Y.Z", "body": "<section>"}`. The tokens are read from their files at call time, never written anywhere.

## 4. Verify like a user

Without credentials: the README GIF (`https://raw.githubusercontent.com/johannes-kaindl/neurovim.nvim/main/docs/images/demo.gif`) answers 200, and the release badge shows the new version.

Then install it for real from GitHub, in a throw-away environment so your own config and save stay out of it:

```bash
E=$(mktemp -d); mkdir -p "$E/config/nvim"
cat > "$E/config/nvim/init.lua" <<'LUA'
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', 'https://github.com/folke/lazy.nvim.git', lazypath })
end
vim.opt.rtp:prepend(lazypath)
require('lazy').setup({ { 'johannes-kaindl/neurovim.nvim', opts = {} } }, { rocks = { enabled = false } })
LUA
export XDG_CONFIG_HOME=$E/config XDG_DATA_HOME=$E/data XDG_STATE_HOME=$E/state XDG_CACHE_HOME=$E/cache
nvim --headless '+Lazy! sync' +qa
git -C "$E/data/nvim/lazy/neurovim.nvim" log --oneline -1 --decorate   # shows the tag
nvim --headless -c 'checkhealth neurovim' -c "w! $E/health.txt" -c 'qa!'; cat "$E/health.txt"
```

Expected: the tag at HEAD, `:checkhealth neurovim` all OK with the vendored nvim-kit and neurovim pins, no error from `opts = {}`.

## 5. Afterwards

- Tell the neurovim session (or note in its cockpit) when the data pin changed — neurovim's `CONSUMERS.md` tracks it.
- Record the release in the cockpit (`$VAULT/25_Coding/neurovim.nvim/`): status, last commit, the release task.
