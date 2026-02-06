-- floating window logic

local M = {}

function M.show(result)
  local buf = vim.api.nvim_create_buf(false, true)
  local text = tostring(result)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    " " .. text .. " ",
  })
  local width = math.max(#text + 4, 10)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    row = -3,
    col = 0,
    width = width,
    height = 2,
    style = "minimal",
    border = "rounded",
  })

  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, 3000)
end

return M

