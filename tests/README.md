# Tests

This plugin is easiest to test inside headless Neovim (so it uses the same Lua runtime as normal usage).

## Run tests locally

```sh
nvim --headless -u NONE "+lua dofile('tests/run.lua')" +qa
```