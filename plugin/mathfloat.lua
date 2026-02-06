-- source this to use the plugin

if vim.g.loaded_mathfloat then
  return
end
vim.g.loaded_mathfloat = true

vim.api.nvim_create_user_command(
  "Texeval",
  function()
    require("mathfloat").calculate_selection()
  end,
  { range = true }
)

