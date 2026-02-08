# Tests

This plugin is easiest to test inside headless Neovim.
You can assert LaTeX expressions directly inside the test file.

## Run tests locally

```sh
nvim --headless -u NONE "+lua dofile('tests/run.lua')" +qa
```