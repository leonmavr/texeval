local M = {}

local MatrixMT = {}
MatrixMT.__index = MatrixMT

local function is_matrix(x)
  return type(x) == "table" and getmetatable(x) == MatrixMT
end

local function fmt_number(x)
  if type(x) ~= "number" then
    return tostring(x)
  end
  -- Compact, stable-ish display for floats
  return string.format("%.10g", x)
end

function MatrixMT:__tostring()
  local parts = {}
  for i = 1, self.r do
    local row = self._data[i]
    local row_parts = {}
    for j = 1, self.c do
      row_parts[#row_parts + 1] = fmt_number(row[j])
    end
    parts[#parts + 1] = "[" .. table.concat(row_parts, ", ") .. "]"
  end
  return "[" .. table.concat(parts, ", ") .. "]"
end

local function matmul(A, B)
  if A.c ~= B.r then
    error(string.format("matrix dimension mismatch: (%dx%d) * (%dx%d)", A.r, A.c, B.r, B.c))
  end

  local out = {}
  for i = 1, A.r do
    out[i] = {}
    for j = 1, B.c do
      local s = 0
      for k = 1, A.c do
        s = s + A._data[i][k] * B._data[k][j]
      end
      out[i][j] = s
    end
  end
  return M.mat(out)
end

local function scale(A, s)
  local out = {}
  for i = 1, A.r do
    out[i] = {}
    for j = 1, A.c do
      out[i][j] = A._data[i][j] * s
    end
  end
  return M.mat(out)
end

function MatrixMT.__mul(a, b)
  if type(a) == "number" and is_matrix(b) then
    return scale(b, a)
  end
  if is_matrix(a) and type(b) == "number" then
    return scale(a, b)
  end
  if is_matrix(a) and is_matrix(b) then
    return matmul(a, b)
  end
  error("unsupported multiplication")
end

function M.mat(tbl)
  if type(tbl) ~= "table" then
    error("mat expects a table")
  end

  local r = #tbl
  if r == 0 then
    error("mat expects at least one row")
  end

  if type(tbl[1]) ~= "table" then
    error("mat expects a 2D table")
  end

  local c = #tbl[1]
  if c == 0 then
    error("mat expects at least one column")
  end

  for i = 1, r do
    if type(tbl[i]) ~= "table" then
      error("mat expects a 2D table")
    end
    if #tbl[i] ~= c then
      error("mat expects rectangular rows")
    end
    for j = 1, c do
      if type(tbl[i][j]) ~= "number" then
        error("mat entries must be numbers")
      end
    end
  end

  return setmetatable({ _data = tbl, r = r, c = c }, MatrixMT)
end

M.matmul = function(a, b)
  if not is_matrix(a) or not is_matrix(b) then
    error("matmul expects matrices")
  end
  return matmul(a, b)
end

M.is_matrix = is_matrix

return M
