--------------------------------------------------------------------------------
--	This file is part of the Lua HUD for TASing Sega Genesis Sonic games.
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
--	Input function and structure.
--------------------------------------------------------------------------------

require("headers/register")

mouse = {x = 0, y = 0, dx = 0, dy = 0, leftdown = false, click = false}

local input_state = {}

function update_input()
	input_state = input.get()
	mouse.dx = input_state.xmouse - mouse.x
	mouse.dy = input_state.ymouse - mouse.y
	mouse.x = input_state.xmouse
	mouse.y = input_state.ymouse
	if input_state.leftclick and mouse.leftdown ~= input_state.leftclick then
		mouse.click = true
	else
		mouse.click = false
	end
	mouse.leftdown = input_state.leftclick
end

callbacks.gui.register:add(function()
		update_input()
	end)

