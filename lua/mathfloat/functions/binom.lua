local function binom(n, k)
  if type(n) ~= "number" or type(k) ~= "number" then
    error("binom expects numbers")
  end
  if n ~= n or k ~= k or n == math.huge or n == -math.huge or k == math.huge or k == -math.huge then
    error("binom expects finite numbers")
  end

  local ni = math.floor(n + 0.5)
  local ki = math.floor(k + 0.5)
  if ni ~= n or ki ~= k then
    error("binom expects integers")
  end
  if ni < 0 or ki < 0 then
    error("binom expects non-negative integers")
  end
  if ki > ni then
    return 0
  end

  ki = math.min(ki, ni - ki)
  if ki == 0 then
    return 1
  end
  if ki > 100000 then
    error("binom too large")
  end

  local acc = 1
  for i = 1, ki do
    acc = acc * (ni - ki + i) / i
    if acc == math.huge or acc == -math.huge then
      error("binom overflow")
    end
  end
  return acc
end

return binom
