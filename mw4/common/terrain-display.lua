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
--	Terrain solidity display.
--	Written by: Marzo Junior
--------------------------------------------------------------------------------

require("mw4/common/rom-check")

-- Solid flags
local ns, ts, bs, rs, ls = 0, 1, 2, 4, 8
local solid_colors = {
	[ns         ]={  0,  0,  0,  0}, -- ---- solid 0x0 black
	[ts         ]={  0,128,  0,128}, -- t--- solid 0x1 green
	[      rs   ]={128,  0,  0,128}, -- --r- solid 0x4 maroon
	[ts   +rs   ]={128,128,  0,128}, -- t-r- solid 0x5 olive
	[         ls]={  0,  0,128,128}, -- ---l solid 0x8 navy
	[ts      +ls]={  0,128,128,128}, -- t--l solid 0x9 teal
	[      rs+ls]={128,  0,128,128}, -- --rl solid 0xc purple
	[ts   +rs+ls]={128,128,128,128}, -- t-rl solid 0xd gray
	[ts+bs+rs+ls]={255,255,255,128}, -- tbrl solid 0xf white
}

-- nil entries get filled in dynamically later
local solid_flags = {
	--     ts bs rs ls
	[0x0]= ns         ,
	[0x1]= ts+bs+rs+ls,
	[0x2]= ns         ,
	[0x3]= ts+bs+rs+ls,
	[0x4]= nil        ,
	[0x5]= ns         ,
	[0x6]= ns         ,
	[0x7]= ns         ,
	[0x8]= nil        ,
	[0x9]= ts         ,
	[0xa]= ns         ,
	[0xb]= ns         ,
	[0xc]= ts+bs+rs+ls,
	[0xd]= ts+bs+rs+ls,
	[0xe]= nil        ,
	[0xf]= ts+bs+rs+ls,
}

-- Extra flags
local zf, jf, sf, df, ls = 0, 1, 2, 4
local flag_colors = {
	[zf      ]=nil              , -- --- 0x0 black
	[jf      ]={  0,255,  0,128}, -- j-- 0x1 green
	[   sf   ]={  0,  0,255,128}, -- -s- 0x4 blue
	[jf+sf   ]={  0,255,255,128}, -- js- 0x4 teal
	[      df]={255,  0,  0,128}, -- --d 0x5 red
}

-- nil entries get filled in dynamically later
local extra_flags = {
	--     ts bs rs ls
	[0x0]= zf      ,
	[0x1]= zf      ,
	[0x2]= zf      ,
	[0x3]=       df,
	[0x4]= jf      ,
	[0x5]= zf      ,
	[0x6]= zf      ,
	[0x7]= zf      ,
	[0x8]=       df,
	[0x9]= zf      ,
	[0xa]=       df,
	[0xb]= zf      ,
	[0xc]=    sf   ,
	[0xd]=    sf   ,
	[0xe]= jf+sf   ,
	[0xf]= zf      ,
}

function draw_terrain()
	local camWordX, camWordY = game:get_camera_word()
	local minX, minY, maxX, maxY = game:get_limits()
	local table_ptr = game:level_layout_ptr()
	local terrain_shift = game:level_terrain_shift()
	-- Patch in dynamic solidity of tiles
	local s0 = memory.readbytesigned(0xffffcc70)
	local s1 = memory.readbyte(0xffffad4d)
	local s2 = (s1 == 0 and s0 < 0) and ts or ns
	local s3 = (s0 >= 0 and memory.readbyte(0xffffad4c) == 0) and rs or ns
	local s4 = (s0 < 0) and ls or ns
	solid_flags[0x4] = (s1 ~= 1) and ts or ns
	solid_flags[0x8] = s2+s3+s4 -- ts+ls or ls or rs or ns
	solid_flags[0xe] = (s1 ~= 1) and ts or ns
	local empty = {0,0,0,0}

	for ii=0,256,16 do
		local xx = AND(camWordX + ii, 0xfff0)
		local initx = xx - camWordX
		local endx = initx + 15
		if xx >= maxX then
			xx = maxX
		elseif xx < minX then
			xx = minX
		end
		xx = SHIFT(xx - minX, 4) * 2
		for jj=0,224,16 do
			local yy = AND(camWordY + jj, 0xfff0)
			local inity = yy - camWordY
			local endy = inity + 15
			if yy >= maxY then
				yy = maxY
			elseif yy < minY then
				yy = minY
			end
			yy = SHIFT(AND(yy - minY, 0xfff0), terrain_shift)
			local terrain_byte = AND(memory.readword(table_ptr + yy + xx), 0x3ff)
			local terrain_type = memory.readbyte(0xffff6000 + terrain_byte)
			if terrain_type ~= 0 then
				local index = solid_flags[terrain_type]
				local flags = extra_flags[terrain_type]
				local color   = solid_colors[index] or empty
				local outline = flag_colors [flags] or color
				gui.box(initx+0, inity+0, endx-0, endy-0, empty, outline or color)
				gui.box(initx+1, inity+1, endx-1, endy-1, color, outline or color)
				-- For debugging:
				--gui.text(initx + 5, inity + 5, string.format("%02X", terrain_type), 'white', 'black')
			end
		end
	end
end

