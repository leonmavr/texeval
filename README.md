# texeval
Evaluate LaTeX expressions in floating windows without leaving nvim.

## Features:

- [x] Arithmetic, fractions, brackets
- [x] Whitespace-agnostic and bracket modifier-agnostic
- [x] Transcendental functions (trig, log, etc)
- [x] Square roots and powers
- [x] Factorials and binomials 
- [x] Scientific notation (`5e-4`)
- [X] Matrix multiplication and transpore

Future ideas:
- [ ] Copy to clipboard and convert result back to LaTeX syntax    

## How to install

### With Packer

Add this to your `init.lua`:
```
use 'leonmavr/texeval'
```
Or if you wish to add a keybind of your choice to invoke it this way in visual mode:
```
use {
  "leonmavr/texeval",
  config = function()
    -- <leader>t in visual mode to call it
    vim.keymap.set("v", "<leader>t", ":<C-U>Texeval<CR>", { noremap = true, silent = true })
  end,
}
```
Then, execute `PackerSync` (hit `Esc`, `:PackerSync`) and you're ready to go.

### How to use

In visual model, select the expression to evaluate (press `v` and navigate to select it).
Then in the command line (press `:`) run:
```
:'<,'>Texeval
```
You may want to map this to a keybind of your choice instead of invoking `Texeval` every time:
```
vim.keymap.set('v', '<Leader>t', ':Texeval<CR>', { silent = true })
```

### Examples

<div align="center">
  <img src="https://github.com/leonmavr/texeval/blob/master/assets/demo_before_after.png" />
</div>

<div align="center">
  <img src="https://github.com/leonmavr/texeval/blob/master/assets/examples.png" />
</div>
