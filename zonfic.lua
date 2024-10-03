#!/usr/bin/env lua5.4
-- SPDX-License-Identifier: GPL-2.0-only

local io		= require "io";
local string		= require "string";
local os		= require "os";
local table		= require "table";
local math		= require "math";

local expression	= require "expression";
local util		= require "util";

local kconfig		= require "kconfig";

local kconfigPath	= "./Kconfig";
local environmentPath	= "./zonfic.env.lua";

local pwarn, perr	= util.pwarn, util.perr;

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
		if i ~= #entries then
			io.stdout:write("\n");
		end
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
