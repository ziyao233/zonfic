#!/usr/bin/env lua5.4
-- SPDX-License-Identifier: GPL-2.0-only

local io		= require "io";
local string		= require "string";
local os		= require "os";
local table		= require "table";
local math		= require "math";

local kconfig		= require "kconfig";

local kconfigPath	= "./Kconfig";
local environmentPath	= "./zonfic.env.lua";

local function
pwarn(fmt, ...)
	io.stderr:write(string.format(fmt .. "\n", ...));
end

local function
perr(fmt, ...)
	pwarn(fmt, ...);
	os.exit(1);
end

local function
printTable(t)
	local l = 0;
	for _, entry in ipairs(t) do
		l = math.max(l, entry.k:len());
	end

	for _, entry in ipairs(t) do
		local k, v = entry.k, entry.v;
		print(("%s: %s%s"):format(k, (" "):rep(l - k:len()), v));
	end
end


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
	["or"]			= "||",
	["and"]			= "&&",
	["not"]			= "!",
	["equal"]		= "==",
	["unequal"]		= "!=",
	["less"]		= "<",
	["less-or-eq"]		= "<=",
	["greater"]		= ">",
	["greater-or-eq"]	= ">=",
	["range"]		= ".."
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

local function
prettyPrintConfig(cfg)
	local t = {
		{ k = "name", v = cfg.name },
	};

	for file, line in pairs(cfg.location) do
		table.insert(t, { k = "location",
				  v = ("%s: %d"):format(file, line) });
	end

	if cfg.depends then
		table.insert(t, { k = "depends on",
				  v = pprExprInfix(cfg.depends) });
	end

	printTable(t);
end

local function
doSearch(arg)
	if not arg[1] then
		perr("Usage:\n\tsearch <CONFIG_NAME>");
	end

	local name = string.gsub(arg[1], "[a-z]", string.upper);
	local entries = { cfgs[name] };
	if not entries[1] then
		pwarn("Configuration \"%s\" not found", name);
		pwarn("Try fuzzy searching...");

		for k, cfg in pairs(cfgs) do
			if string.find(k, name, 1, true) then
				table.insert(entries, cfg);
			end
		end
	end

	for i, entry in ipairs(entries) do
		prettyPrintConfig(entry);
	end
end

local opts = {
	search = { func = doSearch },
};

local opt = opts[arg[1]];
if not opt then
	if not arg[1] then
		perr("Usage:\n\tzonfic <operation> [ARG1] ...");
	else
		perr("Unknown operation \"%s\"", arg[1]);
	end
end

local ok, env = pcall(dofile, environmentPath);
if not ok then
	pwarn("Failed to evaluate environment file %s", environmentPath);
	pwarn("Configuration parsing is likely to fail");
	env = {};
end

for k, v in pairs(env) do
	kconfig.setenv(k, v);
end

cfgs = kconfig.parse(kconfigPath);
table.remove(arg, 1);
opt.func(arg);
