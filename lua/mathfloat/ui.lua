-- floating window logic

local M = {}

-- to avoid name clashes with other plugins, e.g. with cleanup function
local close_on_key_ns = vim.api.nvim_create_namespace("mathfloat-ui-close-on-key")

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
    height = 1,
    style = "minimal",
    border = "rounded",
  })

  local cleaned_up = false
  local function cleanup()
    if cleaned_up then
      return
    end
    cleaned_up = true
    vim.on_key(nil, close_on_key_ns)
  end

  -- close on next keypress
  vim.on_key(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    cleanup()
  end, close_on_key_ns)

  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    cleanup()
  end, 10000)
end

return M

