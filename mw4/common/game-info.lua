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
	curr_char    = nil,
}

function game:get_gold()
	return string.format("%6d", memory.readlong(0xffda7e))
end

function game:get_hearts()
	return string.format("%2d/%2d", memory.readword(0xffda76), memory.readword(0xffda74))
end

function game:get_red_hearts()
	return string.format("%2d", memory.readword(0xffda78))
end

function game:get_blue_hearts()
	return string.format("%2d/15 (%d/10)", memory.readword(0xffda7a), memory.readword(0xffda7c))
end

function game:get_flashing_timer()
	return memory.readbyte(0xffcc71)
end

-- Cycles PRNG seed to next value
function game:cycle_rng(seed)
	return OR(AND(seed*41 + SHIFT(seed*41, -16), 0xffff0000), AND(seed*41, 0xffff))
end

-- Gets returned PRNG value
function game:random_number(seed)
	return OR(AND(seed, 0xffff0000), AND(SHIFT(AND(seed*41 + SHIFT(seed*41, -16), 0xffff0000), 16), 0xffff))
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

