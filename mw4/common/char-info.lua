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
--	Character data, wrapped up in an object.
--	Written by: Marzo Junior
--	Based on game disassemblies and Gens' RAM search.
--------------------------------------------------------------------------------

require("headers/lua-oo")
require("mw4/common/rom-check")
require("mw4/common/game-info")

Character = class{
	offset         = 0,
	face           = nil,    --	Currently selected face
	jump_speed     = "",     --	String value for jump prediction
	status_huds    = {},
}

function Character:get_position()
	local xpospix   = memory.readword(0xffa122 + self.offset)
	local xpossub   = memory.readbyte(0xffa124 + self.offset)
	local ypospix   = memory.readword(0xffa226 + self.offset)
	local ypossub   = memory.readbyte(0xffa228 + self.offset)
	return string.format("%5d:%-3d,%5d:%-3d", xpospix, xpossub, ypospix, ypossub)
end

function Character:get_speed()
	local xvel      = memory.readwordsigned(0xffa42e + self.offset)
	local yvel      = memory.readwordsigned(0xffa430 + self.offset)
	return string.format("%+5d, %+5d", xvel, yvel)
end

function Character:hit_time_left()
	return game:get_flashing_timer()
end

function Character:hit_timer()
	return string.format("%5d", self:hit_time_left())
end

function Character:hit_active()
	return self:hit_time_left() ~= 0
end

function Character:wounded_icon()
	return self.curr_set.wounded
end

function Character:init(p1, port)
	self.offset = (p1 and 0) or 4
	self.face   = port	--	This manufactures a HUD icon monitor given the adequate functions.
	--	'Icon' can be either a function or a gdimage.
	local function Create_HUD(this, active_fun, timer_fun, icon)
		local cond = Conditional_widget:new(0, 0, false, active_fun, this)
		local hud  = Frame_widget:new(0, 0, 42, 19)
		hud:add_status_icon(2, 2, icon, bind(timer_fun, this))
		cond:add(hud, 0, 0)

		return cond
	end

--	Here we generate the list of status monitor icons for each character, starting with
	--	the common icons. To add new ones, just copy and modify accordingly.
	if self.offset == 0 then
		self.status_huds = {
			Create_HUD(self, self.hit_active, self.hit_timer, "asha-wounded"),
		}
	else
		self.status_huds = {}
	end
end

function Character:construct(p1, port)
	self:init(p1, port)
	return self
end

