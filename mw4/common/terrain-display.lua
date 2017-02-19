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

local ns, ts, bs, rs, ls = 0, 1, 2, 4, 8
local color_table = {
	[ns+ns+ns+ns]={  0,  0,  0,128}, -- ---- solid 0x0 black
	[ts+ns+ns+ns]={  0,128,  0,128}, -- t--- solid 0x1 green
	[ns+ns+rs+ns]={128,  0,  0,128}, -- --r- solid 0x4 maroon
	[ts+ns+rs+ns]={128,128,  0,128}, -- t-r- solid 0x5 olive
	[ns+ns+ns+ls]={  0,  0,128,128}, -- ---l solid 0x8 navy
	[ts+ns+ns+ls]={  0,128,128,128}, -- t--l solid 0x9 teal
	[ns+ns+rs+ls]={128,  0,128,128}, -- --rl solid 0xc purple
	[ts+ns+rs+ls]={128,128,128,128}, -- t-rl solid 0xd gray
	[ts+bs+rs+ls]={255,255,255,128}, -- tbrl solid 0xf white
}

function draw_terrain()
	local valX = memory.readword(0xffffc72e)
	local valY = memory.readword(0xffffc730)
	local table_ptr = memory.readlong(0xffffc722)
	local terrain_shift = -memory.readbyte(0xffffc717)
	local camWordX = memory.readword(0xffffc73a)
	local camWordY = memory.readword(0xffffc746)
	local s0 = memory.readbytesigned(0xffffcc70)
	local s1 = (memory.readbyte(0xffffad4d) ~= 1) and ts or ns
	local s2 = memory.readbyte(0xffffad4c)
	local s3 = (memory.readbyte(0xffffad4d) == 0 and s0 < 0) and ts or ns
	local s4 = (s0 >= 0 and s2 == 0) and rs or ns
	local s5 = (s0 < 0) and ls or ns
	local solid_flags = {
		--     ts bs rs ls         ts bs rs ls         ts bs rs ls         ts bs rs ls
		[0x0]= ns+ns+ns+ns, [0x1]= ts+bs+rs+ls, [0x2]= ns+ns+ns+ns, [0x3]= ts+bs+rs+ls,
		[0x4]= s1+ns+ns+ns, [0x5]= ns+ns+ns+ns, [0x6]= ns+ns+ns+ns, [0x7]= ns+ns+ns+ns,
		[0x8]= s3+ns+s4+s5, [0x9]= ts+ns+ns+ns, [0xa]= ns+ns+ns+ns, [0xb]= ns+ns+ns+ns,
		[0xc]= ts+bs+rs+ls, [0xd]= ts+bs+rs+ls, [0xe]= s1+ns+ns+ns, [0xf]= ts+bs+rs+ls,
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
			local index = solid_flags[terrain_type]
			if index ~= 0 then
				local color = color_table[index]
				gui.box(initx, inity, endx, endy, color, color)
			end
			--gui.text(initx + 5, inity + 5, string.format("%02X", terrain_type), 'white', 'black')
		end
	end
end

