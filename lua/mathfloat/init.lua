-- public entry point of plugin

local selection = require("mathfloat.selection")
local eval      = require("mathfloat.eval")
local ui        = require("mathfloat.ui")

-- public API
local M = {}

function M.calculate_selection()
  local expr = selection.get()
  if not expr or expr == "" then
    return
  end
  local result, err = eval.evaluate(expr)
  if not result then
    vim.notify("Texeval error: " .. err, vim.log.levels.ERROR)
    return
  end
  ui.show(result)
end

return M

