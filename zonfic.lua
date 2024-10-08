#!/usr/bin/env lua5.4
-- SPDX-License-Identifier: GPL-2.0-only

local io		= require "io";
local string		= require "string";
local os		= require "os";
local table		= require "table";
local math		= require "math";

local configfile	= require "configfile";
local expression	= require "expression";
local util		= require "util";

local kconfig		= require "kconfig";

local kconfigPath	= "./Kconfig";
local defScriptPath	= "./zonfic.def.lua";

local pwarn, perr	= util.pwarn, util.perr;

local defArgs = {};

local function
doDiff(arg)
	local path = arg[1] or "./.config";

	if not defArgs.values then
		perr("Base configuration is not specified");
	end

	local loaded = configfile.parse(defArgs.cfgs, path);
	local evaluated = defArgs.values;
	local syms, toString = defArgs.cfgs, configfile.toString;
	for k, v in pairs(loaded) do
		local v_ = evaluated[k];
		if not v_ then
			pwarn("undefined symbol %s");
		elseif v ~= v_ then
			pwarn("%s: parsed %s, evaludated %s",
			      k, toString(syms[k], v), toString(syms[k], v_));
		end
		evaluated[k] = nil;
	end

	for k, v in pairs(evaluated) do
		pwarn("Symbol %s is not specified in %s", k, path);
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
				  v = expression.pprExprInfix(cfg.depends) });
	end

	if #cfg.select ~= 0 then
		for _, dep in pairs(cfg.select) do
			table.insert(t, {
						k = "select",
						v = expression.pprExprInfix(dep)
					});
		end
	end

	util.printTable(t);
end

local function
doSearch(arg)
	if not arg[1] then
		perr("Usage:\n\tsearch <CONFIG_NAME>");
	end

	local name = string.gsub(arg[1], "[a-z]", string.upper);
	local entries = { defArgs.cfgs[name] };
	if not entries[1] then
		pwarn("Configuration \"%s\" not found", name);
		pwarn("Try fuzzy searching...");

		for k, cfg in pairs(defArgs.cfgs) do
			if string.find(k, name, 1, true) then
				table.insert(entries, cfg);
			end
		end
	end

	for i, entry in ipairs(entries) do
		prettyPrintConfig(entry);
		if i ~= #entries then
			io.stdout:write("\n");
		end
	end
end

local function
doGenerate(arg)
	if not arg[1] then
		perr("Usage:\n\tzonfic generate <OUTPUT-CONFIG>");
	end

	if not defArgs.values then
		perr("Base configuration is not specified");
	end

	configfile.generate(defArgs.cfgs, defArgs.values, arg[1]);
end

local opts = {
	diff = { func = doDiff },
	eval = { func = function() end },	-- no-op, just evaluate defscript
	generate = { func = doGenerate },
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

local defScriptEnv = {
			type	= type,
			pairs	= pairs,
			error	= error,
		     };
defScriptEnv._G = defScriptEnv;

defScriptEnv.setenv = function(env)
	if type(env) ~= "table" then
		error("environment must be a table");
	end

	for k, v in pairs(env) do
		kconfig.setenv(k, v);
	end

	defArgs.cfgs = kconfig.parse(kconfigPath);
end

defScriptEnv.baseConfig = function(path)
	if not defArgs.cfgs then
		error("environment must be set before base configuration");
	end

	defArgs.values = configfile.parse(defArgs.cfgs, path);
end

defScriptEnv.log = function(s, ...)
	pwarn(tostring(s), ...);
end

local defScript, msg = loadfile(defScriptPath, "t", defScriptEnv);
if not defScript then
	perr("Failed to load defscript:\n%s", msg);
end

local ok, msg = pcall(defScript);
if not ok then
	perr("Failed to evaluate defscript:\n%s", msg);
end

table.remove(arg, 1);
opt.func(arg);
