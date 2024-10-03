-- SPDX-License-Identifier: GPL-2.0-only
--[[
--	zonfic
--	expression.lua
--	Copyright (c) 2024 Yao Zi. All rights reserved.
--]]

local string		= require "string";

local function
pprSymbol(s)
	return s.isConst and s.value or s.name;
end

local compareFn <const> = {
	"equal", "unequal", "less", "less-or-eq", "greater", "greater-or-eq"
};
local compareFnRev = {};
for _, v in pairs(compareFn) do
	compareFnRev[v] = true;
end

local infixOp <const> = {
	["or"]                  = "||",
	["and"]                 = "&&",
	["not"]                 = "!",
	["equal"]               = "==",
	["unequal"]             = "!=",
	["less"]                = "<",
	["less-or-eq"]          = "<=",
	["greater"]             = ">",
	["greater-or-eq"]       = ">=",
	["range"]               = ".."
};

local function
pprExprPrefix(expr)
	local fn = expr.fn;

	if fn == "symbol" then
		return pprSymbol(expr.ref);
	elseif compareFnRev[fn] then
		return ("(%s %s %s)"):
		       format(fn, pprSymbol(expr.left), pprSymbol(expr.right));
	elseif fn == "not" then
		return ("(not %s)"):format(pprExprPrefix(expr.left));
	else
		return ("(%s %s %s)"):
		       format(fn, pprExprPrefix(expr.left),
				  pprExprPrefix(expr.right));
	end
end

local function
pprExprInfix(expr)
	local fn = expr.fn;

	if fn == "symbol" then
		return pprSymbol(expr.ref);
	elseif compareFnRev[fn] then
		return ("(%s %s %s)"):
		       format(pprSymbol(expr.left),
			      infixOp[fn],
			      pprSymbol(expr.right));
	elseif fn == "not" then
		return '!' .. pprExprPrefix(expr.left);
	else
		return ("(%s %s %s)"):
		       format(pprExprInfix(expr.left),
			      infixOp[fn],
			      pprExprInfix(expr.right));
	end
end

return {
	pprExprPrefix	= pprExprPrefix,
	pprExprInfix	= pprExprInfix,
       };
