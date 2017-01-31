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
--	Character HUD widget.
--	Written by: Marzo Junior
--------------------------------------------------------------------------------

require("headers/lua-oo")
require("headers/widgets")
require("mw4/common/game-info")
require("mw4/common/char-info")
require("mw4/common/infinite-jump")

--------------------------------------------------------------------------------
--	Character HUD object.
--------------------------------------------------------------------------------
Character_hud = class{
	character = nil,
}:extends(Container_widget)

function Character_hud:construct(char, x, y, active)
	self:super(x, y, active)
	self.character = char

	self:add_toggle(make_toggle(25, false, Container_widget.toggled, self, active),
	                char.offset == 0 and 0 or 119, 0)

	local cond

	local char_hud = Frame_widget:new(0, 0, 115, 25)
	char_hud:add(Icon_widget:new(0, 0, char.face), 2, 2)

	--	Position
	char_hud:add(Icon_widget:new(0, 0, "location"                   ), 21, 2)
	char_hud:add(Text_widget:new(0, 0, bind(char.get_position, char)), 36, 2)

	--	Speed
	char_hud:add(Icon_widget:new(0, 0, "speed"                      ), 21, 13)
	char_hud:add(Text_widget:new(0, 0, bind(char.get_speed   , char)), 36, 10)

	if char.offset == 0 then
		cond = Conditional_widget:new(0, 0, active, function(self) return true end, nil)
		--	Jump prediction
		char_hud:add(Text_widget:new(0, 0,
				function()
					if want_prediction() then
						return char.jump_speed
					else
						return ""
					end
				end), 36, 17)
	else
		cond = Conditional_widget:new(0, 0, active, function(self) return game:get_pepe_level() ~= 0 end, nil)
		-- Infinite jump
		local btn = Clickable_widget:new(0, 0, 16, 16, do_one_jump, nil)
		btn:add(Icon_widget:new(0, 0, "flight-boost"), 0, 0)
		char_hud:add(btn, 99, 9)
		char_hud:add(Text_widget:new(0, 0, bind(game.show_pepe_level   , game)), 9, 18)
	end

	cond:add(char_hud, 0, 0)
	self:add(cond, 4, 0)
	return self
end

