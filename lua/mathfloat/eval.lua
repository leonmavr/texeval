-- module return
local M = {}

local factorial = require("mathfloat.functions.factorial")
local binom = require("mathfloat.functions.binom")
local apply_func_powers = require("mathfloat.functions.apply_func_powers")
local matrix = require("mathfloat.functions.matrix")
local transpose = require("mathfloat.functions.transpose")

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function mat2lua(body)
  body = body:gsub("\n", " ")
  -- row breaks: \\ in LaTeX
  -- NOTE: match TWO backslashes, not any backslash command like \pi
  --       remove space modifiers like \\[1ex]
  body = body:gsub("%s*\\\\\\\\%s*%b[]%s*", "\n")
  body = body:gsub("%s*\\\\%s*", "\n")
  -- strip matrix-only helpers that would otherwise leak backslashes
  body = body:gsub("\\hline", "")

  local row_lua = {}
  for row in body:gmatch("[^\n]+") do
    row = trim(row)
    if row ~= "" then
      row = row:gsub("%s*&%s*", "\t")
      local cols = {}
      for col in row:gmatch("[^\t]+") do
        col = trim(col)
        if col ~= "" then
          cols[#cols + 1] = col
        end
      end
      row_lua[#row_lua + 1] = "{" .. table.concat(cols, ",") .. "}"
    end
  end

  return "mat({" .. table.concat(row_lua, ",") .. "})"
end

local function parse_braced(s, i)
  -- parse nested braces starting from s[i]
  -- return the contents and the index of the next character after the closing brace
  if s:sub(i, i) ~= "{" then
    return nil, i
  end
  local depth = 0
  local start_i = i + 1
  local j = i
  while j <= #s do
    local ch = s:sub(j, j)
    if ch == "{" then
      depth = depth + 1
    elseif ch == "}" then
      depth = depth - 1
      if depth == 0 then
        return s:sub(start_i, j - 1), j + 1
      end
    end
    j = j + 1
  end
  return nil, i
end

local function expand_frac(expr)
  -- expand \frac{a}{b} into (a)/(b) to support nested braces.
  local out = {}
  local i = 1
  while i <= #expr do
    -- NOTE: use a single literal backslash ("\\frac" in Lua)
    local s, e = expr:find("\\frac", i, true)
    if not s then
      out[#out + 1] = expr:sub(i)
      break
    end
    out[#out + 1] = expr:sub(i, s - 1)
    i = e + 1

    while i <= #expr and expr:sub(i, i):match("%s") do
      i = i + 1
    end

    if expr:sub(i, i) ~= "{" then
      out[#out + 1] = "\\frac"
    else
      local a, next_i = parse_braced(expr, i)
      if not a then
        out[#out + 1] = "\\frac"
      else
        i = next_i
        while i <= #expr and expr:sub(i, i):match("%s") do
          i = i + 1
        end
        if expr:sub(i, i) ~= "{" then
          out[#out + 1] = "\\frac{" .. a .. "}"
        else
          local b, next_i2 = parse_braced(expr, i)
          if not b then
            out[#out + 1] = "\\frac{" .. a .. "}"
          else
            out[#out + 1] = "(" .. expand_frac(a) .. ")/(" .. expand_frac(b) .. ")"
            i = next_i2
          end
        end
      end
    end
  end
  return table.concat(out)
end

----------------------------------------------------------------------
-- Supported functions
----------------------------------------------------------------------
local function log10(x)
  return math.log(x) / math.log(10)
end

local function sinh(x)
  return (math.exp(x) - math.exp(-x)) / 2
end

local function cosh(x)
  return (math.exp(x) + math.exp(-x)) / 2
end

local function tanh(x)
  local ex = math.exp(x)
  local enx = math.exp(-x)
  return (ex - enx) / (ex + enx)
end

local safe_env = {
  math = math,
  abs  = math.abs,
  sqrt = math.sqrt,
  sin  = math.sin,
  cos  = math.cos,
  tan  = math.tan,
  sinh = sinh,
  cosh = cosh,
  tanh = tanh,
  log  = log10,
  ln   = math.log,
  factorial = factorial,
  binom = binom,
  mat = matrix.mat,
  matmul = matrix.matmul,
  transpose = transpose,
  pi   = math.pi,
  e    = math.exp(1),
}

----------------------------------------------------------------------
-- LaTeX to Lua translator
----------------------------------------------------------------------
local function latex_to_lua(expr)
  -- remove math mode symbols
  expr = expr:gsub("%$", "")
  -- remove common spacing commands
  expr = expr:gsub("\\,", "")
  expr = expr:gsub("\\;", "")
  expr = expr:gsub("\\:", "")
  expr = expr:gsub("\\!", "")
  expr = expr:gsub("\\quad", " ")
  expr = expr:gsub("\\qquad", " ")
  expr = expr:gsub("\\%s", " ")
  -- remove decorative sizing macros (any case): \big, \Big, \BIG, \bigg, \Bigg,
  -- and delimiter variants like \bigl, \Bigr, \Bigm, etc.
  expr = expr:gsub("\\[bB][iI][gG][gG]?[lLrRmM]?%s*", "")
  -- operators
  expr = expr:gsub("\\cdotp", "*")
  expr = expr:gsub("\\cdot", "*")
  expr = expr:gsub("\\times", "*")
  -- remove common sizing wrappers
  expr = expr:gsub("\\left%s*%(", "(")
  expr = expr:gsub("\\right%s*%)", ")")
  -- absolute value: \left|x\right| -> abs(x)
  expr = expr:gsub("\\left%s*%|", "abs(")
  expr = expr:gsub("\\right%s*%|", ")")
  -- also handle \left\lvert x \right\rvert
  expr = expr:gsub("\\left%s*\\lvert", "abs(")
  expr = expr:gsub("\\right%s*\\rvert", ")")

  -- matrix environments: \begin{pmatrix} ... \end{pmatrix}, 
  --                        \begin{bmatrix} ... \end{bmatrix}, etc.
  expr = expr:gsub("\\begin%s*{([%a]+matrix)}%s*(.-)%s*\\end%s*{%1}", function(_, body)
    return mat2lua(body)
  end)

  -- transpose: ^T, ^\top, ^\intercal (and braced forms)
  -- normalize all variants to ^T for easier procesing in the next step
  expr = expr:gsub("%^{%s*\\top%s*}", "^T")
  expr = expr:gsub("%^%s*\\top", "^T")
  expr = expr:gsub("%^{%s*\\intercal%s*}", "^T")
  expr = expr:gsub("%^%s*\\intercal", "^T")
  expr = expr:gsub("%^{%s*T%s*}", "^T")

  -- apply transpose to common preceding forms.
  -- transpose() is a no-op for scalars.
  -- function calls: matmul(A,B)^T -> transpose(matmul(A,B))
  expr = expr:gsub("([%a_][%w_]*)%s*(%b())%s*%^%s*T", function(fn, args)
    return "transpose(" .. fn .. args .. ")"
  end)
  -- grouped expressions: (A*B)^T -> transpose(A*B)
  expr = expr:gsub("(%b())%s*%^%s*T", "transpose%1")
  -- simple identifiers/numbers: A^T -> transpose(A), 2^T -> transpose(2)
  expr = expr:gsub("([%a_][%w_]*)%s*%^%s*T", "transpose(%1)")
  expr = expr:gsub("([%d%.]+)%s*%^%s*T", "transpose(%1)")
  -- trig powers: \sin^2(x), \tan^{3}(\frac{\pi}{6}), etc.
  -- NOTE: this must be run this BEFORE expanding \frac{..}{..} into (..)/(..),
  -- because that generates new parens that confuse the simple (...) matcher.
  expr = apply_func_powers(expr, "sin")
  expr = apply_func_powers(expr, "cos")
  expr = apply_func_powers(expr, "tan")
  expr = apply_func_powers(expr, "sinh")
  expr = apply_func_powers(expr, "cosh")
  expr = apply_func_powers(expr, "tanh")
  -- \frac{a}{b} -> (a)/(b) (brace-aware, supports nesting)
  expr = expand_frac(expr)
  -- \binom{N}{k} -> binom(N,k)
  expr = expr:gsub(
    "\\binom%s*{([^}]+)}%s*{([^}]+)}",
    "binom(%1,%2)"
  )
  -- \fracab (no braces)
  expr = expr:gsub("\\frac%s*\\pi%s*([%w%.]+)", "(pi)/(%1)")
  expr = expr:gsub("\\frac%s*([%w%.]+)%s*\\pi", "(%1)/(pi)")
  expr = expr:gsub("\\frac%s*\\mathrm%s*{e}%s*([%w%.]+)", "(e)/(%1)")
  expr = expr:gsub("\\frac%s*([%w%.]+)%s*\\mathrm%s*{e}", "(%1)/(e)")
  expr = expr:gsub("\\frac%s*([%w%.]+)%s*([%w%.]+)", "(%1)/(%2)")
  -- \sqrt{a} -> sqrt(a)
  expr = expr:gsub(
    "\\sqrt%s*{([^}]+)}",
    "sqrt(%1)"
  )
  -- \sqrt(a) -> sqrt(a)
  expr = expr:gsub("\\sqrt%s*%(([^)]+)%)", "sqrt(%1)")
  -- trig / log functions (support both {..} and (..))
  expr = expr:gsub("\\sin%s*{([^}]+)}",    "sin(%1)")
  expr = expr:gsub("\\sin%s*%(([^)]+)%)",  "sin(%1)")
  expr = expr:gsub("\\cos%s*{([^}]+)}",    "cos(%1)")
  expr = expr:gsub("\\cos%s*%(([^)]+)%)",  "cos(%1)")
  expr = expr:gsub("\\tan%s*{([^}]+)}",    "tan(%1)")
  expr = expr:gsub("\\tan%s*%(([^)]+)%)",  "tan(%1)")
  expr = expr:gsub("\\sinh%s*{([^}]+)}",   "sinh(%1)")
  expr = expr:gsub("\\sinh%s*%(([^)]+)%)", "sinh(%1)")
  expr = expr:gsub("\\cosh%s*{([^}]+)}",   "cosh(%1)")
  expr = expr:gsub("\\cosh%s*%(([^)]+)%)", "cosh(%1)")
  expr = expr:gsub("\\tanh%s*{([^}]+)}",   "tanh(%1)")
  expr = expr:gsub("\\tanh%s*%(([^)]+)%)", "tanh(%1)")
  expr = expr:gsub("\\log%s*{([^}]+)}",    "log(%1)")
  expr = expr:gsub("\\log%s*%(([^)]+)%)",  "log(%1)")
  expr = expr:gsub("\\ln%s*{([^}]+)}",     "ln(%1)")
  expr = expr:gsub("\\ln%s*%(([^)]+)%)",   "ln(%1)")
  -- constants
  expr = expr:gsub("\\pi", "pi")
  expr = expr:gsub("\\mathrm%s*{e}", "e")
  expr = expr:gsub("\\mathrm%s*{\\pi}", "pi")
  -- exponent: a^{b} -> a^(b)
  expr = expr:gsub("(%w+)%s*%^{([^}]+)}", "%1^(%2)")
  -- allow simple grouping braces around Euler's number: {e} -> (e)
  expr = expr:gsub("{%s*e%s*}", "(e)")
  -- factorial
  expr = expr:gsub("(%b())%s*!", function(group)
    return "factorial" .. group
  end)
  expr = expr:gsub("([%w%._]+)%s*!", "factorial(%1)")
  -- absolute value
  while true do
    local n
    expr, n = expr:gsub("|([^|]+)|", "abs(%1)")
    if n == 0 then
      break
    end
  end
  return expr
end

-- Lua evaluation
local function eval_lua(expr)
  local fn, err = load("return " .. expr, "mathfloat", "t", safe_env)
  if not fn then
    return nil, (err or "load error") .. "\nGenerated Lua: " .. tostring(expr)
  end

  local ok, result = pcall(fn)
  if not ok then
    return nil, tostring(result) .. "\nGenerated Lua: " .. tostring(expr)
  end

  return result
end

local function insert_implicit_mult(expr)
  -- Protect scientific notation (e.g. 1e-3, 2.5E6, .5e2) so we don't
  -- incorrectly turn it into multiplication with Euler's constant
  local sci = {}
  local sci_i = 0

  local function protect_sci(mantissa, exponent)
    sci_i = sci_i + 1
    sci[sci_i] = mantissa .. "e" .. exponent
    return "__SCINOT" .. sci_i .. "__"
  end

  expr = expr:gsub("(%d*%.%d+)[eE]([%+%-]?%d+)", protect_sci)
  expr = expr:gsub("(%d+%.?%d*)[eE]([%+%-]?%d+)", protect_sci)
  -- Insert implicit multiplication, but avoid breaking scientific notation like 1e-3
  expr = expr:gsub("(%d)([a-df-zA-DF-Z])", "%1*%2")
  expr = expr:gsub("(%d)%s+([a-df-zA-DF-Z_][%w_]*)", "%1*%2")
  expr = expr:gsub("([%d%.]+)%s+([a-df-zA-DF-Z_][%w_]*)", "%1*%2")
  -- Euler's number multiplication: 2e, 2 e, e2, e 2, e(1+2)
  expr = expr:gsub("([%d%.]+)%s*e", "%1*e")
  expr = expr:gsub("e%s*([%d%.]+)", "e*%1")
  expr = expr:gsub("e%s*%(", "e*(")
  -- pi multiplication: \pi2, \pi 2, pi2, pi 2
  expr = expr:gsub("pi%s*([%d%.]+)", "pi*%1")
  -- identifier followed by whitespace and a function call: pi sin(1) -> pi*sin(1)
  expr = expr:gsub("([%a_][%w_]*)%s+([%a_][%w_]*)%(", "%1*%2(")

  expr = expr:gsub("(%d)%(", "%1*(")
  expr = expr:gsub("(%d)%s+%(", "%1*(")
  expr = expr:gsub("%)(%d)", ")*%1")
  expr = expr:gsub("%)(%a)", ")*%1")
  expr = expr:gsub("%)%(", ")*(")
  expr = expr:gsub("%)%s+(%d)", ")*%1")
  expr = expr:gsub("%)%s+([%a_])", ")*%1")
  expr = expr:gsub("%)%s+%(", ")*(")

  local functions = {
    abs = true,
    sin = true,
    cos = true,
    tan = true,
    sinh = true,
    cosh = true,
    tanh = true,
    sqrt = true,
    log = true,
    ln = true,
    factorial = true,
    binom = true,
    mat = true,
    matmul = true,
    transpose = true,
  }
  expr = expr:gsub("(%a+)%(", function(name)
    if functions[name] then
      return name .. "("
    else
      return name .. "*("
    end
  end)
  expr = expr:gsub("(%a+)%s+%(", function(name)
    if functions[name] then
      return name .. "("
    else
      return name .. "*("
    end
  end)

  -- safety catch: if implicit-multiplication accidentally created `fn*(...)` for
  -- a whitelisted function name, rewrite it back into a function call.
  for name, ok in pairs(functions) do
    if ok then
      expr = expr:gsub(name .. "%s*%*%s*%(", name .. "(")
    end
  end

  -- restore scientific notation
  expr = expr:gsub("__SCINOT(%d+)__", function(i)
    return sci[tonumber(i)]
  end)

  return expr
end

----------------------------------------------------------------------
-- public API
-----------------------------------------------------------------------
function M.evaluate(expr)
  local lua_expr = latex_to_lua(expr)
  lua_expr = insert_implicit_mult(lua_expr)
  return eval_lua(lua_expr)
end

return M

