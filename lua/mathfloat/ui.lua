-- floating window logic

---@diagnostic disable: undefined-global

local M = {}

-- to avoid name clashes with other plugins, e.g. with cleanup function
local close_on_key_ns = vim.api.nvim_create_namespace("mathfloat-ui-close-on-key")

function M.show(result)
  local buf = vim.api.nvim_create_buf(false, true)
  local text = tostring(result)
  local raw_lines = vim.split(text, "\n", { plain = true, trimempty = false })
  if #raw_lines == 0 then
    raw_lines = { "" }
  end

  local max_width = math.max(vim.o.columns - 4, 10)
  local max_height = math.max(vim.o.lines - 4, 1)

  local lines = {}
  local width = 10
  for i, line in ipairs(raw_lines) do
    local padded = " " .. line .. " "
    lines[i] = padded
    width = math.max(width, vim.api.nvim_strwidth(padded))
  end
  width = math.min(width, max_width)

  local height = #lines
  if height > max_height then
    -- Truncate very tall outputs (e.g. huge matrices)
    local truncated = {}
    for i = 1, max_height do
      truncated[i] = lines[i]
    end
    truncated[max_height] = " ... "
    lines = truncated
    height = #lines
    width = math.max(width, vim.api.nvim_strwidth(truncated[max_height]))
    width = math.min(width, max_width)
  end

  -- If width is constrained, hard-truncate lines so the float doesn't error.
  for i, line in ipairs(lines) do
    if vim.api.nvim_strwidth(line) > width then
      lines[i] = vim.fn.strcharpart(line, 0, width)
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = height,
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

