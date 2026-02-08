-- Monolithic headless unit test runner for mathfloat module
-- Run with:
-- nvim --headless -u NONE "+lua dofile('tests/run.lua')" +qa

local function cwd()
  if _G.vim and vim.loop and vim.loop.cwd then
    return vim.loop.cwd()
  end
  return assert(io.popen("pwd", "r")):read("*l")
end

local ROOT = cwd()
package.path = ROOT .. "/lua/?.lua;" .. ROOT ..
               "/lua/?/init.lua;" .. package.path

local eval = require("mathfloat.eval")
local matrix = require("mathfloat.functions.matrix")

local function fail(msg)
  error(msg, 2)
end

local function assert_eq(actual, expected, label)
  if actual ~= expected then
    fail(string.format("%s\nexpected: %s\nactual:   %s",
         label or "assert_eq failed", tostring(expected),
         tostring(actual)))
  end
end

local function assert_approx(actual, expected, eps, label)
  eps = eps or 1e-4
  if type(actual) ~= "number" or type(expected) ~= "number" then
    fail((label or "assert_approx type mismatch") .. ": expected numbers")
  end
  if math.abs(actual - expected) > eps then
    fail(string.format("%s\nexpected: %.16g\nactual:   %.16g\neps:      %.3g",
         label or "assert_approx failed", expected, actual, eps))
  end
end

local function assert_err_contains(expr, needle, label)
  local res, err = eval.evaluate(expr)
  if res ~= nil then
    fail((label or "expected error") .. ": got result: " .. tostring(res))
  end
  if type(err) ~= "string" or not err:find(needle, 1, true) then
    fail(string.format("%s\nexpected error containing: %s\nactual error: %s", label or "assert_err_contains failed", tostring(needle), tostring(err)))
  end
end

local function eval_ok(expr)
  local res, err = eval.evaluate(expr)
  if res == nil then
    fail("evaluation failed: " .. tostring(err))
  end
  return res
end

local tests = {}
local function test(name, fn)
  tests[#tests + 1] = { name = name, fn = fn }
end

test("Basic fractions and square roots", function()
  local r = eval_ok("\\frac{1}{2} - 1/\\sqrt{4}")
  assert_approx(r, 0.0, 1e-3)
end)

test("Nested fractions", function()
  local r = eval_ok("\\frac{1}{1 + \\frac{1}{1 + \\frac{1}{1 + \\frac{1}{1 + \\frac{1}{2}}}}}")
  local golden_ratio_inv = (math.sqrt(5) - 1)/2
  assert_approx(r, golden_ratio_inv, 1e-2)
end)

test("Logs", function()
  local r = eval_ok("\\log(1000)+\\ln(e^3) + \\ln(\\mathrm{e}^2) + 1/\\log(0.01)")
  -- log is assumed to be log10
  assert_approx(r, 7.5, 1e-10)
end)

test("Nested square roots", function()
  local expr = "1/\\sqrt{2\\sqrt{3\\sqrt{4\\sqrt{5}}}}"
  local r = eval_ok(expr)
  assert_approx(r, 0.4085, 1e-3)
end)

test("Nested logs", function()
  local r = eval_ok("\\ln(\\ln(e))")
  assert_approx(r, 0.0, 1e-3)
end)

test("Trigs", function()
  local r = eval_ok("\\sin(\\pi/2) + \\cos(pi) - \\tan(\\pi/4)")
  assert_approx(r, -1, 1e-3)
end)

test("Nested trigs", function()
  local r = eval_ok("\\sin(\\sin(0))")
  assert_approx(r, 0.0, 1e-3)
end)

test("Scientific notation preserved", function()
  local r = eval_ok("1e-3 + 2e-3")
  assert_approx(r, 0.003, 1e-6)
end)

-- Operations
test("Simple division", function()
  local r = eval_ok("-1/2/3")
  assert_approx(r, -1/6, 1e-6)
end)

test("Implicit multiplication, spaces", function()
  local r = eval_ok("2( 1-   2)")
  assert_approx(r, -2, 1e-6)
end)

test("Nested implicit multiplication", function()
  local r = eval_ok("2(1-2(1-2))")
  assert_approx(r, 6, 1e-6)
end)

test("Multiplication oeprators, constants", function()
  local r = eval_ok("2\\cdot\\pi - 3\\times \\pi + 4\\pi - 5*\\pi + 6\\pi 2 + e2")
  assert_approx(r, 10*math.pi + 2*math.exp(1), 1e-6)
end)

-- Powers
test("Powers", function()
  local r = eval_ok("4^0.5 + 2^3 - 3^0.0000001 + 9^{1/2}")
  assert_approx(r, 12, 1e-3)
end)

test("Nested powers, mixed braces", function()
  local r = eval_ok("(((2^{1/3})^{3})^{2}^\\frac{1}{2})^2")
  assert_approx(r, 4.0, 1e-6)
end)

-- Combinatorics / factorial
test("factorial", function()
  local r = eval_ok("5!")
  assert_eq(r, 120)
end)

test("binom", function()
  local r = eval_ok("\\binom{6}{2}")
  assert_eq(r, 15)
end)

-- Abs
test("absolute value", function()
  local r = eval_ok("|-3+1|")
  assert_eq(r, 2)
end)

-- Matrices
test("matrix literal", function()
  local A = eval_ok("\\begin{pmatrix}1 & 2\\\\3 & 4\\end{pmatrix}")
  assert_eq(matrix.is_matrix(A), true)
  assert_eq(A.r, 2)
  assert_eq(A.c, 2)
  assert_eq(A._data[1][1], 1)
  assert_eq(A._data[2][2], 4)
end)

test("matrix transpose (intercal)", function()
  local AT = eval_ok("\\begin{pmatrix}1 & 2\\\\3 & 4\\end{pmatrix}^\\intercal")
  assert_eq(matrix.is_matrix(AT), true)
  assert_eq(AT.r, 2)
  assert_eq(AT.c, 2)
  assert_eq(AT._data[1][1], 1)
  assert_eq(AT._data[1][2], 3)
  assert_eq(AT._data[2][1], 2)
  assert_eq(AT._data[2][2], 4)
end)

test("nested transpose", function()
  local AT = eval_ok("(\\begin{pmatrix}1 & 2\\\\3 & 4\\end{pmatrix}^\\intercal)^T")
  assert_eq(matrix.is_matrix(AT), true)
  assert_eq(AT.r, 2)
  assert_eq(AT.c, 2)
  assert_eq(AT._data[1][1], 1)
  assert_eq(AT._data[1][2], 2)
  assert_eq(AT._data[2][1], 3)
  assert_eq(AT._data[2][2], 4)
end)

test("matrix multiplication", function()
  local A = "\\begin{bmatrix}1 & 2\\\\3 & 4\\end{bmatrix}"
  local B = "\\begin{pmatrix}5 & 6\\\\7 & 8\\end{pmatrix}"
  local C = eval_ok(A .. " " .. B) -- same as "*"
  assert_eq(matrix.is_matrix(C), true)
  assert_eq(C._data[1][1], 19)
  assert_eq(C._data[1][2], 22)
  assert_eq(C._data[2][1], 43)
  assert_eq(C._data[2][2], 50)
end)

-- spaces and redundant stuff
test("Spaces and paren size", function()
  local r = eval_ok("1/\\Big(2\\quad \\left(  3   \\; \\, -4\\right)\\Big)")
  assert_eq(r, 1/(2*(3-4)), 1e-2)
end)

local function run_all()
  local passed = 0
  for _, t in ipairs(tests) do
    local ok, err = pcall(t.fn)
    if ok then
      passed = passed + 1
    else
      io.stderr:write("FAIL: " .. t.name .. "\n" .. tostring(err) .. "\n")
      return false
    end
  end
  print(string.format("OK: %d tests", passed))
  return true
end

local ok = run_all()
if not ok then
  -- Exit non-zero in Neovim.
  if _G.vim then
    vim.cmd("cq")
  else
    os.exit(1)
  end
end
