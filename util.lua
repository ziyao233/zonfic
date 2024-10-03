-- SPX-License-Identifier: GPL-2.0-only
--[[
--	zonfic
--	util.lua
--	Copyright (c) 2024 Yao Zi. All rights reserved.
--]]

local io		= require "io";
local string		= require "string";

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

return {
	perr		= perr,
	pwarn		= pwarn,
	printTable	= printTable,
       };
