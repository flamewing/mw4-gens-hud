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
	for offset = 0x104,0,-4 do
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
			-- Draw wide collision box
			local xlen = memory.readword(offset + 0xffffac46)
			local ylen = memory.readword(offset + 0xffffac48)
			gui.box(xpos - xlen, ypos - ylen, xpos + xlen, ypos + ylen, color_list[0].fill, color_list[0].outline)
			-- draw narrow interaction box
			if color ~= nil then
				local xlen = memory.readbyte(offset + 0xffffad4a)
				local ylen = memory.readbyte(offset + 0xffffad4b)
				gui.box(xpos - xlen, ypos - ylen, xpos + xlen, ypos + ylen, color.fill, color.outline)
			else
				print(string.format("Error: invalid color for offset %02X", offset))
			end
			-- Draw hurtbox for Asha's sword
			-- Generally seem to be OK, but some cases are clearly wrong;
			-- need to disassemble further.
			if offset == 0 and memory.readbyte(0xffffd2eb) ~= 0 and memory.readbyte(0xffffa637) ~= 4 then
				local attack_mode = memory.readbyte(0xffffa638)
				local frame_data = nil
				if attack_mode == 2 then -- swing down
					frame_data = {["first"]=  2,
					               ["last"]=   4,
					               [0]={ -1, 13, 22, 14},
					               [1]={ -1, 13, 22, 14},
					               [2]={ -1, 13, 22, 14}}
				elseif attack_mode == 6 then -- swing up
					frame_data = {["first"]=  1,
					               ["last"]=   3,
					               [0]={  7,  9, -4, 12},
					               [1]={  4, 13,-17, 14},
					               [2]={  4, 13,-17, 14}}
				elseif attack_mode == 8 then -- swing forward, on air
					frame_data = {["first"]=  1,
					               ["last"]=   4,
					               [0]={ 15, 12, -5,  8},
					               [1]={ 20, 14, 13,  8},
					               [2]={ -2, 14, -7,  8},
					               [3]={-15, 14, -1,  8},
					               [4]={-21, 11, -7,  8}}
				elseif attack_mode == 10 then -- swing forward, on ground
					frame_data = {["first"]=  1,
					               ["last"]=   3,
					               [0]={ 17,  8, -4,  8},
					               [1]={ 27, 14, -2,  8},
					               [2]={ 17, 16,  3,  8}}
				end
				if frame_data ~= nil then
					local anim_frame = memory.readbyte(0xffffaa44)
					if anim_frame <= frame_data.last and anim_frame >= frame_data.first then
						anim_frame = anim_frame - frame_data.first
						local flags = memory.readbyte(0xffff9f1b)
						local tbl = frame_data[anim_frame]
						local dx, wx, dy, wy = tbl[1], tbl[2], tbl[3], tbl[4]
						local cx = xpos + ((AND(flags,  8) == 0) and dx or -dx)
						local cy = ypos + ((AND(flags, 16) == 0) and dy or -dy)
						gui.box(cx - wx, cy - wy, cx + wx, cy + wy, {255,  0,  0,128}, {255,  0,  0,255})
					end
				end
			end
			--[[
			debug=1
			--]]
			if debug == 1 then
				gui.text(xpos-7, ypos-7, string.format("%02X%02X\n%04X", offset, type, routine), 'white', 'black')
			else
				if offset >= 0x34 and offset <= 0x80 then
					if type == 4 then
						-- Hitpoints/invulnerability timer?
						local hps   = memory.readbyte(offset + 0xffffb468) -- HPs
						local timer = memory.readbyte(offset + 0xffffb469) -- Invulnerability timer
						gui.text(xpos-3, ypos-11, string.format("%02X\n%2d\n%2d", offset, hps, timer), 'white', 'black')
					elseif type == 8 then
						-- Treasure
						local treasure = memory.readbyte(offset + 0xffffb468) - 48 -- Treasure type
						local timer = memory.readbyte(offset + 0xffffb774) -- Collect timer
						if treasure >= 0 and treasure < 6 or treasure >= 9 then
							-- Gold
							treasure = 4 * treasure
							local min = memory.readword(treasure + 0x298C8)
							local max = min + memory.readword(treasure + 0x298C6)
							text = string.format("  %02x\n  %02d", offset, timer)
							gui.text(xpos-11, ypos-11, text, 'white', 'black')
							text = string.format("  %02x\n  %02d", offset, timer)
							local text = string.format("%d-%d", min, max)
							if max < 10 then
								gui.text(xpos-5, ypos+5, text, 'white', 'black')
							elseif max < 100 then
								gui.text(xpos-9, ypos+5, text, 'white', 'black')
							else
								gui.text(xpos-13, ypos+5, text, 'white', 'black')
							end
						elseif treasure >= 0 then
							text = string.format("%02X\n%2d", offset, timer)
							gui.text(xpos-3, ypos-7, text, 'white', 'black')
						else
							text = string.format("%02X\n%2d\n%2d", offset, timer, treasure + 48)
							gui.text(xpos-3, ypos-11, text, 'white', 'black')
						end
					end
				else
					gui.text(xpos-3, ypos-3, string.format("%02X", offset), 'white', 'black')
				end
			end
		end
	end
end

