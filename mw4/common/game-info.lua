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
--	Global, character independent, game data.
--	Written by: Marzo Junior
--	Based on game disassemblies and Gens' RAM search.
--------------------------------------------------------------------------------

require("mw4/common/rom-check")

game = {
}

function game:level_active()
	return memory.readbyte(0xffff97e9) == 0xff
end

function game:transition_script()
	return memory.readlong(0xffffcbc4)
end

function game:get_flag(flag)
	local flagbyte = 0xffffccaa + SHIFT(flag, 3)
	local byte = memory.readbyte(flagbyte)
	return AND(byte, BIT(AND(flag, 7))) ~= 0
end

function game:get_gear_flag(flag)
	local flagbyte = 0xffffde16 + SHIFT(flag, 3)
	local byte = memory.readbyte(flagbyte)
	return AND(byte, BIT(AND(flag, 7))) ~= 0
end

function game:has_item(item)
	if item < 0x1c then
		-- Sword, armor, shield
		return self:get_gear_flag(item) ~= 0
	elseif item == 0x1c then
		-- Elixir
		return memory.readbyte(0xffffdaa8) ~= 0
	else
		-- Other item types
		local ii = 0
		while ii < 10 do
			if memory.readbyte(0xffffde1a + ii) == item then
				return true
			end
			ii = ii + 1
		end
	end
	return false
end

function game:get_camera_word()
	return memory.readword(0xffffc73a),
	       memory.readword(0xffffc746)
end

function game:get_camera_long()
	return memory.readlong(0xffffc73a),
	       memory.readlong(0xffffc746)
end

-- minX, minY, maxX, maxY
function game:get_limits()
	return 0x1000, 0x1000,
	       memory.readword(0xffffc72e),
	       memory.readword(0xffffc730)
end

function game:level_layout_ptr()
	return memory.readlong(0xffffc722)
end

-- Related to the width of the level
function game:level_terrain_shift()
	return -memory.readbyte(0xffffc717)
end

function game:get_gold()
	return string.format("%6u",
	                     memory.readlong(0xffda7e))
end

function game:get_hearts()
	return string.format("%2d/%2d",
	                     memory.readword(0xffda76),
	                     memory.readword(0xffda74))
end

function game:get_red_hearts()
	return string.format("%2d",
	                     memory.readword(0xffda78))
end

function game:get_blue_hearts()
	return string.format("%2d/15 (%d/10)",
	                     memory.readword(0xffda7a),
	                     memory.readword(0xffda7c))
end

function game:get_flashing_timer()
	return memory.readbyte(0xffcc71)
end

-- Cycles PRNG seed to next value
function game:cycle_rng(seed)
	return OR(AND(seed*41 + SHIFT(seed*41, -16),
	              0xffff0000), AND(seed*41, 0xffff))
end

-- Gets returned PRNG value
function game:random_number(seed)
	return OR(AND(seed, 0xffff0000),
	          AND(SHIFT(AND(seed*41 + SHIFT(seed*41, -16),
	                        0xffff0000), 16), 0xffff))
end

-- Gets current PRNG seed
function game:get_rng_seed(seed)
	return memory.readlong(0xffffcb26)
end

-- Pepe level
function game:get_pepe_level()
	return memory.readbytesigned(0xffffde2a) + 1
end

-- Pepe level
function game:show_pepe_level()
	return string.format("%d", self:get_pepe_level())
end

function game:get_rng_list(numrows)
	local currentseed = self:get_rng_seed()
	if currentseed == 0 then
		currentseed = 0x2a6d365a
	end
	local rng_list = {}
	local i = 0
	rng_list[i] = currentseed
	for i=1,numrows do
		currentseed = self:cycle_rng(currentseed)
		rng_list[i] = currentseed
	end
	return rng_list
end

function game:init()
end

game:init()

