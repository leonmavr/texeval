# texeval
Evaluate LaTeX expressions in floating windows without leaving nvim.

## Features:

- [x] Arithmetic, fractions, brackets
- [x] Whitespace-agnostic and bracket modifier-agnostic
- [x] Transcendental functions (trig, log, etc)
- [x] Square roots and powers
- [x] Factorials and binomials 
- [x] Scientific notation (`5e-4`)
- [x] Matrix multiplication and transpore
- [x] Copy to clipboard and convert result back to LaTeX syntax    

## How to install

### With Packer

For a minimal installation, add this to your `init.lua`:
```
use 'leonmavr/texeval'
```
If you wish to install it with custom keybinds for evaluation and pasting, add this instead:
```
use {
    "leonmavr/texeval",
    config = function()
        -- visual: evaluate selection
        vim.keymap.set("v", "<leader>t", ":<C-U>Texeval<CR>", { noremap = true, silent = true })
        -- normal: after evaluation, paste result at cursor
        vim.keymap.set("n", "<leader>tp", function()
            vim.api.nvim_put(vim.split(vim.g.texeval_result or "", "\n"), "c", true, true)
        end, { noremap = true, silent = true })
    end,
}
```
Then, execute `PackerSync` (hit `Esc`, `:PackerSync`) and you're ready to go.

### With lazy.nvim

(untested) Add the following inside your `require("lazy").setup(...)`:
```
{
    "leonmavr/texeval",
}
```

### With Plug

(untested) Add the following to your `init.vim`/`init.lua`:
```
v:null
```

## How to use

Texeval can both evaluate and paste the result. For matrices, the result will be formatted in LaTeX syntax. 

To evaluate an expression, switch to visual model, select the expression to evaluate (press `v` and navigate to select it).
Then in the command line (press `:`) run:
```
:'<,'>Texeval
```
Pasting is more complicated as the result is stored in the global `vim.g.texeval_result` (or `g:texeval_result` in vimscript).

Therefore it's suggested to add the following two mappings in your `init.lua`, either wrapped in the package as earlier or standalone:
```
-- visual mode: evaluate
vim.keymap.set('v', '<Leader>t', ':Texeval<CR>', { silent = true })
-- normal mode: paste
vim.keymap.set("n", "<leader>tp", function()
  vim.api.nvim_put(vim.split(vim.g.texeval_result or "", "\n"), "c", true, true)
end, { noremap = true, silent = true })
```

## Examples

<div align="center">
  <img src="https://github.com/leonmavr/texeval/blob/master/assets/demo_before_after.png" />
</div>

<div align="center">
  <img src="https://github.com/leonmavr/texeval/blob/master/assets/examples.png" />
</div>


https://github.com/user-attachments/assets/7126db14-e20f-497c-a35f-b12a2d8ace13


## Testing 

### Unit tests

It's been tested pretty thoroughly and the unit tests are found at `tests/run.lua`.
You can run them with:
```
nvim --headless -u NONE "+lua dofile('tests/run.lua')" +qa
```

### Manual test when developing

```
:set rtp+=/path/to/root
:source plugin/mathfloat.lua
```
