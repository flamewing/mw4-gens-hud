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
--	Jump predictor.
--	Written by: Marzo Junior
--------------------------------------------------------------------------------

require("mw4/common/rom-check")

local color_table = {
	[0x0]={  0,  0,  0,128}, --                      : black
	[0x1]={128,  0,  0,128}, -- top                  : maroon
	[0x2]={  0,128,  0,128}, --     bottom           : green
	[0x3]={128,128,  0,128}, -- top bottom           : olive
	[0x4]={  0,  0,128,128}, --            right     : navy
	[0x5]={128,  0,128,128}, -- top        right     : purple
	[0x6]={  0,128,128,128}, --     bottom right     : teal
	[0x7]={192,192,192,128}, -- top bottom right     : silver
	[0x8]={128,128,128,128}, --                  left: gray
	[0x9]={255,  0,  0,128}, -- top              left: red
	[0xa]={  0,255,  0,128}, --     bottom       left: lime
	[0xb]={255,255,  0,128}, -- top bottom       left: yellow
	[0xc]={  0,  0,255,128}, --            right left: blue
	[0xd]={255,  0,255,128}, -- top        right left: fuchsia
	[0xe]={  0,255,255,128}, --     bottom right left: aqua
	[0xf]={255,255,255,128}, -- top bottom right left: white
}

function draw_terrain()
	local valX = memory.readword(0xffffc72e)
	local valY = memory.readword(0xffffc730)
	local table_ptr = memory.readlong(0xffffc722)
	local terrain_shift = -memory.readbyte(0xffffc717)
	local camWordX = memory.readword(0xffffc73a)
	local camWordY = memory.readword(0xffffc746)
	local s0 = memory.readbytesigned(0xffffcc70)
	local s1 = (memory.readbyte(0xffffad4d) ~= 1) and 1 or 0
	local s2 = memory.readbyte(0xffffad4c)
	local s3 = (memory.readbyte(0xffffad4d) == 0 and s0 < 0) and 1 or 0
	local s4 = (s0 >= 0 and s2 == 0) and 4 or 0
	local s5 = (s0 < 0) and 8 or 0
	local is_floor_table = {
		[0x0]= 0, [0x1]= 1, [0x2]= 0, [0x3]= 1,
		[0x4]=s1, [0x5]= 0, [0x6]= 0, [0x7]= 0,
		[0x8]=s3, [0x9]= 1, [0xa]= 0, [0xb]= 0,
		[0xc]= 1, [0xd]= 1, [0xe]=s1, [0xf]= 1,
	}
	local is_ceiling_table = {
		[0x0]= 0, [0x1]= 2, [0x2]= 0, [0x3]= 2,
		[0x4]= 0, [0x5]= 0, [0x6]= 0, [0x7]= 0,
		[0x8]= 0, [0x9]= 0, [0xa]= 0, [0xb]= 0,
		[0xc]= 2, [0xd]= 2, [0xe]= 0, [0xf]= 2,
	}
	local is_rightwall_table = {
		[0x0]= 0, [0x1]= 4, [0x2]= 0, [0x3]= 4,
		[0x4]= 0, [0x5]= 0, [0x6]= 0, [0x7]= 0,
		[0x8]=s4, [0x9]= 0, [0xa]= 0, [0xb]= 0,
		[0xc]= 4, [0xd]= 4, [0xe]= 0, [0xf]= 4,
	}
	local is_leftwall_table = {
		[0x0]= 0, [0x1]= 8, [0x2]= 0, [0x3]= 8,
		[0x4]= 0, [0x5]= 0, [0x6]= 0, [0x7]= 0,
		[0x8]=s5, [0x9]= 0, [0xa]= 0, [0xb]= 0,
		[0xc]= 8, [0xd]= 8, [0xe]= 0, [0xf]= 8,
	}
	for ii=0,256,16 do
		local xx = AND(camWordX + ii, 0xfff0)
		local initx = xx - camWordX
		local endx = initx + 15
		if xx >= valX then
			xx = valX
		elseif xx < 0x1000 then
			xx = 0x1000
		end
		xx = SHIFT(xx - 0x1000, 4) * 2
		for jj=0,224,16 do
			local yy = AND(camWordY + jj, 0xfff0)
			local inity = yy - camWordY
			local endy = inity + 15
			if yy >= valY then
				yy = valY
			elseif yy < 0x1000 then
				yy = 0x1000
			end
			yy = SHIFT(AND(yy - 0x1000, 0xfff0), terrain_shift)
			local terrain_byte = AND(memory.readword(table_ptr + yy + xx), 0x3ff)
			local terrain_type = memory.readbyte(0xffff6000 + terrain_byte)
			local index = is_floor_table[terrain_type] + is_ceiling_table[terrain_type]
						+ is_leftwall_table[terrain_type] + is_rightwall_table[terrain_type]
			if index ~= 0 then
				local color = color_table[index]
				gui.box(initx, inity, endx, endy, color, color)
			end
			--gui.text(initx + 5, inity + 5, string.format("%02X", terrain_type), 'white', 'black')
		end
	end
end

