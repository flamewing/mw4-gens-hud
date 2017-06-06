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

--	Create space in memory for a savestate
local state = savestate.create()
local buttons = {C=true}

function want_prediction()
	return enable_predictor and game:level_active() and (movie.recording() or not movie.playing())
end

function predict_jumps()
	savestate.save(state)
	for n=1,2 do
		repeat
			joypad.set(1, buttons)
			gens.emulateframeinvisible()
		until not gens.lagged()
	end

	--	get jump velocities
	Asha.jump_speed = Asha:get_speed()
	savestate.load(state)
end

