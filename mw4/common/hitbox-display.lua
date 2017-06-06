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
--	Hitbox display.
--	Written by: Marzo Junior
--------------------------------------------------------------------------------

require("mw4/common/rom-check")

local color_list = {
	[   "main"]={outline={  0,255,255,255}, fill={  0,255,255,128}}, -- Cyan
	["special"]={outline={  0,  0,255,255}, fill={  0,  0,255,128}}, -- Blue
	[        0]={outline={255,255,255,255}, fill={255,255,255,128}}, -- White
	[        4]={outline={255,255,  0,255}, fill={255,255,  0,128}}, -- Yellow
	[       12]={outline={255,  0,  0,255}, fill={255,  0,  0,128}}, -- Red
	[        8]={outline={  0,255,  0,255}, fill={  0,255,  0,128}}, -- Green
	[ "simple"]={outline={255,  0,255,255}, fill={255,  0,255,128}}, -- Purple
}

local function draw_hitbox(xx, ww, yy, hh, fillclr, outline)
	gui.box(xx - ww, yy - hh, xx + ww, yy + hh, fillclr, outline)
	gui.line(xx, yy - hh + 1, xx, yy + hh - 1, 'black')
	gui.line(xx - ww + 1, yy, xx + ww - 1, yy, 'black')
end

local function read_byte(script)
	return script + 1, memory.readbyte(script)
end

local function read_word(script)
	return script + 2, memory.readword(script)
end

local function read_branch(script)
	return script+2, script + memory.readwordsigned(script)
end

local function draw_transitions()
	local script = game:transition_script()
	if script == 0 then
		return
	end
	local camX, camY = game:get_camera_word()
	local asha_xx = memory.readword(0xffffa122) - camX
	local asha_yy = memory.readword(0xffffa226) - camY
	local asha_ww = memory.readword(0xffffac46)
	local asha_hh = memory.readword(0xffffac48)
	local opcode, branch
	script, opcode = read_byte(script)
	while opcode ~= 0xff do
		if opcode >= 0xc0 then
			-- Common script opcodes, used by all MW4 scripts.
			if opcode == 0xf9 or opcode == 0xe3 or opcode == 0xe2 then
				-- Nop, two unknowns.
				-- Don't have to do anything for these opcodes.
			elseif opcode == 0xfb or opcode == 0xef or opcode == 0xe1 then
				-- Play sound, remove inventory item, play music.
				-- Just add 1 to script location.
				script = script + 1
			elseif opcode == 0xfe then
				-- this is an unconditional branch.
				script, branch = read_branch(script)
				script = branch
			elseif opcode == 0xfa or opcode == 0xf8 or opcode == 0xee or opcode == 0xe9 then
				-- Clear flag, set flag, set camera 1, set water level.
				-- Just add 2 to script location.
				script = script + 2
			elseif opcode == 0xeb then
				-- This has water tunnel information; might be useful
				-- in the future.
				-- Just add 2 to script location.
				script = script + 2
			elseif opcode == 0xea then
				-- This has water tunnel information; might be useful
				-- in the future.
				-- Just add 10 to script location.
				script = script + 10
			elseif opcode == 0xf0 or opcode == 0xe8 or opcode == 0xe7 then
				-- Branch if have item (0xf0, 0xe7).
				-- Branch if don't have item (0xe8).
				local type
				script, type = read_byte(script)
				script, branch = read_branch(script)
				if opcode == 0xe8 then
					-- This is branch if don't have item.
					script, branch = branch, script
				end
				if game:has_item(type) then
					script = branch
				end
			elseif opcode == 0xfd or opcode == 0xfc then
				-- Branch if flag is set/clear.
				local flag
				script, flag = read_word(script)
				script, branch = read_branch(script)
				if opcode == 0xfd then
					-- This is branch if flag unset.
					script, branch = branch, script
				end
				if game:get_flag(flag) then
					script = branch
				end
			elseif opcode == 0xf5 or opcode == 0xe6 then
				-- Unknown, delayed set flag.
				-- Just add 4 to script location.
				script = script + 4
			elseif opcode == 0xe4 then
				-- Branch if random() < parameter.
				-- Dealing with this properly is tough; but
				-- fortunately, no level uses this opcode.
				-- Just add 4 to script location.
				script = script + 4
			elseif opcode == 0xf4 or opcode == 0xf3 then
				-- Unknown, set camera 2.
				-- Just add 5 to script location.
				script = script + 5
			elseif opcode == 0xf1 then
				-- Set dialog script. Needed for ice pyramid
				-- doors with incantations.
				local xx, yy, id
				script, xx = read_word(script)
				script, yy = read_byte(script)
				script, id = read_word(script)
				xx = xx - camX
				yy = 0x1000 + SHIFT(yy, -4) - camY - asha_hh
				draw_hitbox(xx, 8, yy, asha_hh, color_list[0].fill, color_list[0].outline)
				if id == 0x14 or id == 0x58 or id == 0x59 or id == 0x5a then
					-- Red spell
					gui.text(xx-7, yy-asha_hh-8, "ABCB", 'white', 'black')
				elseif id == 0x17 or id == 0x5b or id == 0x5c or id == 0x5d then
					-- Blue spell
					gui.text(xx-7, yy-asha_hh-8, "BAAC", 'white', 'black')
				elseif id == 0x44 or id == 0x5e then
					-- White spell
					gui.text(xx-17, yy-asha_hh-8, "CACCCA", 'white', 'black')
				elseif id == 0x46 or id == 0x5f then
					-- Black spell
					gui.text(xx-17, yy-asha_hh-8, "ACAAAC", 'white', 'black')
				end
			elseif opcode == 0xf2 then
				-- Branch if in region.
				local p0, xl, yl, xh, yh
				script, p0 = read_byte(script)
				script, xl = read_byte(script)
				script, yl = read_byte(script)
				script, xh = read_byte(script)
				script, yh = read_byte(script)
				script, branch = read_branch(script)
				xl = SHIFT(SHIFT(AND(p0, 0xC0), -2) + xl, -3)
				yl = SHIFT(SHIFT(AND(p0, 0x30), -4) + yl, -3)
				xh = SHIFT(SHIFT(AND(p0, 0x0C), -6) + xh, -3)
				yh = 0x1800 + SHIFT(yh, -3)
				if xl <= asha_xx and asha_xx <= xh and yl <= asha_yy + asha_hh  and asha_yy + asha_hh <= yh then
					script = branch
				end
			elseif opcode == 0xf7 or opcode == 0xf6 or opcode == 0xed then
				-- Create special object, unknown, create chest.
				-- Just add 8 to script location.
				script = script + 8
			elseif opcode == 0xec then
				-- Create simple object.
				-- Just add 9 to script location.
				script = script + 9
			elseif opcode == 0xe5 then
				-- This has wind tunnel information; might be useful
				-- in the future.
				-- Just add 9 to script location.
				script = script + 9
			end
		else
			-- Opcodes secific to these level features.
			if opcode >= 0x00 and opcode <= 0x03 then
				-- Cross from direction.
				local p0, p1, p2
				script, p0 = read_byte(script)
				script, p1 = read_byte(script)
				script, p2 = read_byte(script)
				local xx = SHIFT(SHIFT(AND(p0, 0xF0), -4) + p1, -3) + 0xF80 - camX
				local yy = SHIFT(SHIFT(AND(p0, 0x0F), -8) + p2, -3) + 0xF80 - camY
				local width, scene, act
				script, width = read_byte(script)
				script, scene = read_byte(script)
				script, act   = read_byte(script)
				local ww, hh
				if opcode == 0x00 or opcode == 0x01 then
					ww = width * 16
					hh = 1
					if opcode == 0x01 then
						yy = yy - hh
					end
				else
					ww = 1
					hh = width * 16
					if opcode == 0x03 then
						xx = xx - ww
					end
				end
				-- Skip remainder of parameters
				script = script + 3
				xx = xx + ww / 2
				yy = yy - asha_hh
				draw_hitbox(xx, ww / 2, yy, hh, color_list.simple.fill, color_list.simple.outline)
				gui.text(xx-9, yy-7, string.format("%02X\n%02X", scene, act), 'white', 'black')
			elseif opcode == 0x04 or opcode == 0x05 then
				-- Call/return. I don't think this is used in any
				-- transition script... if it is, I will have to
				-- add some code to handle it.
				-- Just add 6 to script location.
				print(string.format("Found %02X", opcode))
				script = script + 6
			elseif opcode == 0x06 or opcode == 0x07 or opcode == 0x08 then
				-- Simple gate, reverse gate or special gate.
				local gate, scene, act
				script, gate  = read_word(script)
				local base = 0x7c8f8 + gate * 8
				local xx = SHIFT(memory.readbyte(base + 0), -4) + 0xF80 - camX
				local yy = SHIFT(memory.readbyte(base + 1), -4) + 0xF80 - camY - asha_hh
				local color
				if opcode == 0x06 then
					-- Simple gate
					script, scene = read_byte(script)
					script, act   = read_byte(script)
					color = color_list.simple
				else
					scene = memory.readbyte(base + 2)
					act = memory.readbyte(base + 3)
					if opcode == 0x07 then
						-- Reverse gate
						color = color_list.simple
					else
						-- Special gate
						script = script + 2
						color = color_list[0]
					end
				end
				draw_hitbox(xx, 8, yy, asha_hh, color.fill, color.outline)
				gui.text(xx-3, yy-7, string.format("%02X\n%02X", scene, act), 'white', 'black')
			elseif opcode == 0x09 then
				-- Monster World map trigger. It is a special gate type,
				-- but I won't handle it.
				-- Just add 2 to script location.
				script = script + 2
			elseif opcode == 0x0a then
				-- Rocks that can be detonated.
				-- Just add 6 to script location.
				script = script + 6
			elseif opcode == 0x0b then
				-- Steam geyser.
				-- Just add 3 to script location.
				script = script + 3
			elseif opcode == 0x0c then
				-- Enable use of item. Might be useful; but only
				-- exists for bucket, magic carpet, crystal of
				-- courage and pepe egg.
				-- Just add 11 to script location.
				script = script + 11
			elseif opcode == 0x0d then
				-- Giant fire. Creates an object, so we don't
				-- have to handle it here.
				-- Just add 8 to script location.
				script = script + 8
			elseif opcode == 0x0e or opcode == 0x0f then
				-- Underwater fans. Creates an object, so we don't
				-- have to handle it here.
				-- Just add 7 to script location.
				script = script + 7
			elseif opcode == 0x10 then
				-- Breakable ice. Adds floors and a shrinking
				-- object, so we don't have to handle it here.
				-- Just add 8 to script location.
				script = script + 8
			elseif opcode == 0x11 then
				-- Frost blower. Creates an object, so we don't
				-- have to handle it here.
				-- Just add 4 to script location.
				script = script + 4
			elseif opcode == 0x12 then
				-- Hidden door marker; only good for detection
				-- with Pepe. Actual door is a regular gate.
				-- Just add 3 to script location.
				script = script + 3
			elseif opcode == 0x13 then
				-- Heart vending machine. Creates an object, so
				-- we don't have to handle it here.
				-- Just add 6 to script location.
				script = script + 6
			elseif opcode == 0x14 then
				-- Elemental gate; only serves as trigger for
				-- graphics and medallion use.
				-- Just add 10 to script location.
				script = script + 10
			elseif opcode == 0x15 then
				-- Setup magic carpet ride. Just sets parameter
				-- flag after you pass parameter location.
				-- Just add 4 to script location.
				script = script + 4
			elseif opcode == 0x16 then
				-- Causes death in magic carpet ride
				-- from falling offscreen.
			elseif opcode == 0x17 then
				-- Invalid opcode; causes crash.
			elseif opcode == 0x18 then
				-- Altar you can pray at.
				local xx, yy, ww
				script, xx = read_word(script)
				script, yy = read_word(script)
				script, ww = read_word(script)
				ww = ww / 2
				xx = xx + ww - camX
				yy = yy - asha_hh - camY
				-- Skip remaining parameters.
				script = script + 2
				draw_hitbox(xx, ww, yy, asha_hh, color_list.simple.fill, color_list.simple.outline)
			elseif opcode == 0x19 then
				-- Pepe tree. Might be worth to add it later.
				-- Creates an object, but it has the wrong hitbox.
				-- Just add 3 to script location.
				script = script + 3
			elseif opcode == 0x1a then
				-- Giant pepe egg in fountain.
				-- Just add 4 to script location.
				script = script + 4
			elseif opcode == 0x1B then
				-- Locked door key trigger. Creates an object,
				-- so we don't have to handle it here.
				-- Just add 3 to script location.
				script = script + 3
			end
		end
		script, opcode = read_byte(script)
	end
end

function draw_hitboxes()
	draw_transitions()
	local camX, camY = game:get_camera_long()
	for offset = 0x104,0,-4 do
		local value = memory.readbytesigned(offset + 0xffff9f1a)
		if value < 0 then
			local type = memory.readbyte(offset + 0xffffb25f)
			local color
			local routine
			local display = true
			local dy = 0
			if offset <= 4 then
				-- Asha and Pepe
				color = color_list.main
				routine = memory.readword(offset + 0xffffb466)
			elseif offset <= 0x30 then
				-- 0x8 and 0xc can have dynamic art.
				-- Some of the others include moving blocks
				-- and platforms.
				color = color_list.special
				routine = memory.readbyte(offset + 0xffffb466)
			elseif offset <= 0x80 then
				-- Objects in this class include:
				-- * scripted objects (type 0);
				-- * enemies (state machines; type 4);
				-- * treasure objects (type 8);
				-- * damaging objects (arrows, fireballs; type 0xc).
				color = color_list[type]
				routine = memory.readbyte(offset + 0xffffb466) * 256 + memory.readbyte(offset + 0xffffb260)
			elseif offset <= 0xc8 then
				-- Objects that are either display-only or
				-- which run a simple piece of code (and,
				-- optionally, also display).
				local revgate = memory.readwordsigned(offset + 0xffffcd86)
				if revgate >= 0 and revgate <= 0x28 and memory.readbyte(revgate + 0xffffce0c) == 0xC0 then
					-- don't draw it
					display = false
				end
				if memory.readlong(offset + 0xffffc076) == 0x14784 then
					-- Align chest to Asha's centerline.
					dy = -16
				end
				if memory.readword(offset + 0xffffbf78) == 7 then
					-- Giant fire
					color = color_list[0xc]
				else
					color = color_list.simple
				end
				routine = memory.readword(offset + 0xffffbf78)
			else -- 0xcc to 0x104
				-- Not sure
				color = color_list.simple
				routine = memory.readword(offset + 0xffffbf78)
			end
			if display then
				local xpos = math.floor((memory.readlong(offset + 0xffffa122) - camX) / 65536)
				local ypos = math.floor((memory.readlong(offset + 0xffffa226) - camY) / 65536) + dy
				-- Draw wide collision box
				local xlen = memory.readword(offset + 0xffffac46)
				local ylen = memory.readword(offset + 0xffffac48)
				draw_hitbox(xpos, xlen, ypos, ylen, color_list[0].fill, color_list[0].outline)
				-- draw narrow interaction box
				if color ~= nil then
					local xlen = memory.readbyte(offset + 0xffffad4a)
					local ylen = memory.readbyte(offset + 0xffffad4b)
					draw_hitbox(xpos, xlen, ypos, ylen, color.fill, color.outline)
				else
					print(string.format("Error: invalid color for offset %02X", offset))
				end
				-- Draw hurtbox for Asha's sword/Asha's shield
				-- Generally seem to be OK.
				local anim_mode = memory.readbyte(0xffffa637)
				if offset == 0 and memory.readbyte(0xffffd2eb) ~= 0 and (anim_mode == 2 or anim_mode == 4) then
					local anim_type = memory.readbyte(0xffffa638)
					local frame_data = nil
					local fillclr
					local outline
					if anim_mode == 2 then
						fillclr = {255,  0,  0,128}
						outline = {255,  0,  0,255}
						if anim_type == 2 then -- swing down
							frame_data = {["first"]=  2,
									      ["last"]=   4,
									      [0]={ -1, 13, 22, 14},
									      [1]={ -1, 13, 22, 14},
									      [2]={ -1, 13, 22, 14}}
						elseif anim_type == 6 then -- swing up
							frame_data = {["first"]=  1,
									      ["last"]=   3,
									      [0]={  7,  9, -4, 12},
									      [1]={  4, 13,-17, 14},
									      [2]={  4, 13,-17, 14}}
						elseif anim_type == 8 then -- swing forward, on air
							frame_data = {["first"]=  1,
									      ["last"]=   4,
									      [0]={ 15, 12, -5,  8},
									      [1]={ 20, 14, 13,  8},
									      [2]={ -2, 14, -7,  8},
									      [3]={-15, 14, -1,  8},
									      [4]={-21, 11, -7,  8}}
						elseif anim_type == 10 then -- swing forward, on ground
							frame_data = {["first"]=  1,
									      ["last"]=   3,
									      [0]={ 17,  8, -4,  8},
									      [1]={ 27, 14, -2,  8},
									      [2]={ 17, 16,  3,  8}}
						end
					elseif anim_mode == 4 then -- shield
						fillclr = {  0,  0,255,128}
						outline = {  0,  0,255,255}
						frame_data = {["first"]=  2,
							          ["last"]=   2,
							          [0]={ 11,  5,  0, 14}}
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
							draw_hitbox(cx, wx, cy, wy, fillclr, outline)
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
							local hps   = memory.readbytesigned(offset + 0xffffb468) -- HPs
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
								local text = string.format("  %02x\n  %02d", offset, timer)
								gui.text(xpos-11, ypos-11, text, 'white', 'black')
								text = string.format("%d-%d", min, max)
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
						else
							gui.text(xpos-3, ypos-3, string.format("%02X", offset), 'white', 'black')
						end
					else
						gui.text(xpos-3, ypos-3, string.format("%02X", offset), 'white', 'black')
					end
				end
			end
		end
	end
end

