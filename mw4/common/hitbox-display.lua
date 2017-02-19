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

local color_list = {
	[   "main"]={outline={  0,255,255,255}, fill={  0,255,255,128}}, -- Cyan
	[ "simple"]={outline={  0,  0,255,255}, fill={  0,  0,255,128}}, -- Blue
	[        0]={outline={255,255,255,255}, fill={255,255,255,128}}, -- White
	[        4]={outline={255,255,  0,255}, fill={255,255,  0,128}}, -- Yellow
	[       12]={outline={255,  0,  0,255}, fill={255,  0,  0,128}}, -- Red
	[        8]={outline={  0,255,  0,255}, fill={  0,255,  0,128}}, -- Green
	["special"]={outline={255,  0,255,255}, fill={255,  0,255,128}}, -- Purple
}

function draw_hitboxes()
	local camX = memory.readlong(0xffffc73a)
	local camY = memory.readlong(0xffffc746)
	for offset = 0,0x104,4 do
		local value = memory.readbytesigned(offset + 0xffff9f1a)
		if value < 0 then
			local type = memory.readbyte(offset + 0xffffb25f)
			local color
			local routine
			if offset <= 8 then
				color = color_list["main"]
				routine = memory.readword(offset + 0xffffb466)
			elseif offset <= 0x30 then
				color = color_list["simple"]
				routine = memory.readbyte(offset + 0xffffb466)
			elseif offset <= 0x80 then
				color = color_list[type]
				routine = memory.readbyte(offset + 0xffffb466) * 256 + memory.readbyte(offset + 0xffffb260)
			else
				color = color_list["special"]
				routine = memory.readword(offset + 0xffffbf78)
			end
			local xpos = math.floor((memory.readlong(offset + 0xffffa122) - camX) / 65536)
			local ypos = math.floor((memory.readlong(offset + 0xffffa226) - camY) / 65536)
			if true or offset <= 0x30 then
				local xlen = memory.readword(offset + 0xffffac46)
				local ylen = memory.readword(offset + 0xffffac48)
				gui.box(xpos - xlen, ypos - ylen, xpos + xlen, ypos + ylen, color_list[0].fill, color_list[0].outline)
			end
			if color ~= nil then
				local xlen = memory.readbyte(offset + 0xffffad4a)
				local ylen = memory.readbyte(offset + 0xffffad4b)
				gui.box(xpos - xlen, ypos - ylen, xpos + xlen, ypos + ylen, color.fill, color.outline)
			else
				print(string.format("Error: invalid color for offset %02X", offset))
			end
			--gui.text(xpos-7, ypos-7, string.format("%02X%02X\n%04X", offset, type, routine), 'white', 'black')
			gui.text(xpos-3, ypos-3, string.format("%02X", offset), 'white', 'black')
		end
	end
end

