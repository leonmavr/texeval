local matrix = require("mathfloat.functions.matrix")

local function transpose(x)
  if not matrix.is_matrix(x) then
    -- scalars are skipped
    return x
  end

  local out = {}
  for j = 1, x.c do
    out[j] = {}
    for i = 1, x.r do
      out[j][i] = x._data[i][j]
    end
  end

  return matrix.mat(out)
end

return transpose
