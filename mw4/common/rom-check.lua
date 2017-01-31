--------------------------------------------------------------------------------
--	This file is part of the Lua HUD for TASing Monster World IV.
--
--	This program is free software: you can redistribute it and/or modify
--	it under the terms of the GNU Lesser General Public License as
--	published by the Free Software Foundation, either version 3 of the
--	License, or (at your option) any later version.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--	GNU General Public License for more details.
--
--	You should have received a copy of the GNU Lesser General Public License
--	along with this program.  If not, see <http://www.gnu.org/licenses/>.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--	ROM checker for Monster World IV.
--	Written by: Marzo Junior
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--	Check if any ROM is loaded.
--------------------------------------------------------------------------------
if not gens.emulating() then
	error("Error: No ROM is loaded.", 0)
end

require("headers/lua-oo")

--------------------------------------------------------------------------------
--	Boss data reading metafunctions.
--------------------------------------------------------------------------------
local function make_unsigned_read(off, add)
	return function(self)
			local val = memory.readbyte(self.offset + off) + add
			return val > 0 and val or 0
		end
end

local function make_signed_read(off, add)
	return function(self)
			local val = memory.readbytesigned(self.offset + off) + add
			return val > 0 and val or 0
		end
end

--	S1 Final Zone boss flash timer frames.
local function s1_fz_flash_timer(self)
	local rout = memory.readbyte(self.offset + 0x34)
	local time = memory.readbyte(self.offset + 0x35)
	return ((rout == 2) and time) or 0
end

--	S3&K Death Egg 1 mini-boss hit points.
local function s3k_dez1_hit_count(self)
	--	There are two objects for this boss: one with the flashing timer and
	--	starting with 255 hit points, the other with the actual hit points
	--	and an inverted flashing timer. Since both take hits, I watch the
	--	former and simply deduct 247 hit points from his total.
	return ((memory.readlong(self.offset) == 0x7e768) and (memory.readbyte(self.offset + 0x29) - 247)) or 0
end

--------------------------------------------------------------------------------
--	Supported ROM data.
--------------------------------------------------------------------------------
--	Enum with the checksums of all supported ROMS.
--	TODO: Add fan-made translations
local sums = {
	mw4jp    = 0x77ae,	-- Original Japanese game
}

--------------------------------------------------------------------------------
--	Object that encapsulates loads of data for a supported ROM.
--------------------------------------------------------------------------------
local rom_info = class{
	checksum = 0,
}

--	Constructor.
function rom_info:construct(checksum)
	self.checksum    = checksum
	return self
end

--------------------------------------------------------------------------------
--	Data for all supported ROMS, gathered in an easy-to-use rom_info array.
--------------------------------------------------------------------------------
local supported_games = {
	--                       Checksum
	mw4jp    = rom_info:new(sums.mw4jp),
}

--	These two variables will hold info on the currently loaded ROM.
rom = nil
romid = nil

--	Find which ROM we have.
local checksum = memory.readword(0x18e)
for id,game in pairs(supported_games) do
	if game.checksum == checksum then
		rom = game
		romid = tostring(id)
		break
	end
end

if rom == nil then
	--	No matching ROM in the supported list. Print error.
	local s1 = "Error: Unsupported ROM"
	local s2 = string.format("Error details: ROM with checksum '0x%04x' is unsupported.", checksum)
	error(s1.."\n\n"..s2, 0)
else
	--	Found ROM. Read and print the reported ROM title.
	local name = string.char(unpack(memory.readbyterange(0x120,0x30)))
	name = string.gsub(name, "(%s+)", " ")
	name = string.gsub(name, "(%s+)$", "")
	--	Special exception for S&K with supported lock-ons.
	if memory.isvalid(0x20018e) then
		local name2 = string.char(unpack(memory.readbyterange(0x200120,0x30)))
		name2 = string.gsub(name2, "(%s+)", " ")
		name = name.." + "..string.gsub(name2, "(%s+)$", "")
	end
	print(name)
end

