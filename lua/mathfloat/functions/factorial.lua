local function factorial(n)
  if type(n) ~= "number" then
    error("ERROR: factorial expects a number!")
  end
  if n ~= n or n == math.huge or n == -math.huge then
    error("ERROR: factorial expects a finite number!")
  end

  -- We omit negative/non-integer factorials
  local ni = math.floor(n + 0.5)
  if ni ~= n then
    error("ERROR: factorial expects an integer!")
  end
  if ni < 0 then
    error("ERROR: factorial expects a non-negative integer!")
  end

  -- Factorial of >170 breaks in many scripting languages
  if ni > 170 then
    error("ERROR: factorial too large!")
  end

  local acc = 1
  for i = 2, ni do
    acc = acc * i
  end
  return acc
end

return factorial
