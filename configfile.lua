-- SPDX-License-Identifier: GPL-2.0-only
--[[
--	zonfic
--	configfile.lua
--	Copyright (c) 2024 Yao Zi. All rights reserved.
--]]

local io		= require "io";
local string		= require "string";

local util		= require "util";

local pwarn, perr = util.pwarn, util.perr;

local function
toData(sym, v)
	if sym.type == "string" then
		if not (v:sub(1, 1) == '"' and v:sub(-1, -1) == '"') then
			return nil;
		else
			return v:sub(2, -2);
		end
	elseif sym.type == "integer" then
		return tonumber(v);
	elseif sym.type == "hex" then
		return v:sub(1, 2) == "0x" and tonumber(v);
	elseif sym.type == "bool" then
		return (v == "y" or v == "n") and v;
	elseif sym.type == "tristate" then
		return (v == "y" or v == "n" or v == "m") and v;
	else
		perr("Symbol %s: Unknown type %s", sym.name, sym.type);
	end
end

local function
parse(syms, path)
	local f = assert(io.open(path, "r"));
	local values = {};

	for line in f:lines() do
		if #line == 0 or line:sub(1, 1) == '#' or
		   line:match("^%s+$") then
			goto continue;
		end

		local k, v = line:match("CONFIG_([^=]+)=(.+)");
		if not k or not v then
			pwarn("Ignoring invalid entry \"%s\"", line);
			goto continue;
		end

		local sym = syms[k];
		if not sym then
			pwarn("Ignoring unknown symbol \"%s\"", k);
			goto continue;
		end

		local t = toData(sym, v);
		if not t then
			perr("Symbol %s: Invalid value \"%s\"", k, t);
		end

		values[k] = t;
::continue::
	end

	f:close();

	-- Kconfig may emit 'n' as unset (and possibly leaving a comment)
	-- For unset bool/tristate symbols, we set to 'n'
	for k, v in pairs(syms) do
		if not values[k] then
			if v.type == "bool" or v.type == "tristate" then
				values[k] = 'n';
			end
		end
	end

	return values;
end

local function
toString(sym, v)
	if sym.type == "bool" or sym.type == "tristate" then
		return v;
	elseif sym.type == "integer" then
		return ("%d"):format(v);
	elseif sym.type == "hex" then
		return ("0x%x"):format(v);
	elseif sym.type == "string" then
		return ("%q"):format(v);
	else
		perr("Symbol %s: Unknown type %s", sym.name, sym.type);
	end
end

local function
generate(syms, values, path)
	local f = assert(io.open(path, "w"));

	for k, v in pairs(values) do
		f:write(("CONFIG_%s=%s\n"):format(k, toString(syms[k], v)));
	end

	f:close();
end

return {
	parse		= parse,
	toString	= toString,
	generate	= generate,
       };
