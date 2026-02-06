-- grab visually selected text

local M = {}

function M.get()
  local bufnr = 0
  local start_pos = vim.fn.getpos("'<")
  local end_pos   = vim.fn.getpos("'>")
  local start_row = start_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_row   = end_pos[2] - 1
  local end_col   = end_pos[3]

  if start_row < 0 or end_row < 0 then
    return nil
  end
  local lines = vim.api.nvim_buf_get_text(
    bufnr,
    start_row,
    start_col,
    end_row,
    end_col,
    {}
  )
  return table.concat(lines, " ")
end

return M

