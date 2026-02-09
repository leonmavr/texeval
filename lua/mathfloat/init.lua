-- public entry point of plugin

local selection = require("mathfloat.selection")
local eval      = require("mathfloat.eval")
local ui        = require("mathfloat.ui")
local matrix_fn = require("mathfloat.functions.matrix")

-- copy scalar to variable
local function fmt_number(x)
  if type(x) ~= "number" then
    return tostring(x)
  end
  return string.format("%.6g", x)
end

local function to_bmatrix(m)
  local rows = {}
  for i = 1, m.r do
    local cols = {}
    for j = 1, m.c do
      cols[#cols + 1] = fmt_number(m._data[i][j])
    end
    rows[#rows + 1] = table.concat(cols, " & ")
  end
  return "\\begin{bmatrix} " .. table.concat(rows, " \\\\ ") .. " \\end{bmatrix}"
end

-- copy matrix to variable as bmatrix format
local function format_for_global(result)
  if matrix_fn.is_matrix(result) then
    return to_bmatrix(result)
  end
  return tostring(result)
end

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

  -- store Texeval's output to a global variable:
  -- - Vimscript: :echo g:texeval_result
  -- - Lua:       print(_G.texeval_result)
  local formatted = format_for_global(result)
  vim.g.texeval_result = formatted
  _G.texeval_result = formatted

  ui.show(result)
end

return M

