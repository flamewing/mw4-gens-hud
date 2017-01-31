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
--	A self-organizing togglable container widget.
--	Written by: Marzo Junior
--------------------------------------------------------------------------------

require("headers/lua-oo")
require("headers/widgets")

Config_menu = class{
	showing_menu = false,
	draw_fun     = function () end,
}:extends(Frame_widget)

local function make_emerald_toggle(callback, udata, icon, text, h, active)
	local btn = Clickable_widget:new(0, 0, 1 + 16 + 1 + 4 * #text + 1, h, callback, udata, {0, 0, 0, 0}, {0, 0, 0, 0})
	local emerald = Icon_widget:new(0, 0, function()
			if btn.hot then
				return (icon() and "heart-red") or "heart-blue"
			else
				return (icon() and "heart-red") or "heart-empty"
			end
		end)
	btn:add(emerald, 1, 1)
	btn:add(Text_widget:new(0, 0, text), 1 + 16 + 1, math.floor((h - 1 - 5)/2))
	return btn
end

local function make_frame(text, x, y, w, h)
	local fra = Frame_widget:new(x, y + 3, w, h - 2, nil, {0, 0, 0, 0})
	local box = Frame_widget:new(0, 0, 4 + 4 * #text, 8, {0, 0, 255, 255}, {0, 0, 127, 255})
	box:add(Text_widget:new(0, 0, text), 3, 1)
	fra:add(box, 2, -3)
	return fra
end

local function make_warning(text, x, y, w, h)
	local fra = Frame_widget:new(x, y + 3, w, h - 2, nil, {0, 0, 0, 0})
	local box = Frame_widget:new(0, 0, 4 + 4 * #text, 8, {0, 0, 255, 255}, {0, 0, 127, 255})
	box:add(Text_widget:new(0, 0, text), 3, 1)
	fra:add(box, 2, -3)
	return fra
end

function Config_menu:menu_loop()
	--	Nonrecursive.
	if self.showing_menu then
		return
	end
	sound.clear()
	self.showing_menu = true
	while self.showing_menu do
		--	Must do it ourselves.
		update_input()
		--	Draw everything else first.
		self.draw_fun()
		--	Draw menu now, in front of all else.
		self:draw()
		gens.redraw()
		gens.wait()
	end
	self.draw_fun()
	gens.redraw()
	self.showing_menu = false
end

function Config_menu:construct(x, y, w, h, draw_fun, active)
	self:super(x, y, w, h, nil, {0, 0, 0, 225})
	self.showing_menu = false
	self.draw_fun = draw_fun

	self:add(make_button(function(self) self.showing_menu = false end, self, "Close" , 30, 8), math.floor((w - 30)/2), h - 10)
	h = h - 10

	local fra0 = make_frame("HUD Options", 0, 0, w - 4, h - 5)
	--	Toggle for disabling the lua HUD.
	fra0:add(make_emerald_toggle(
		function(self)
			disable_lua_hud = not disable_lua_hud
		end, nil,
		function()
			return not disable_lua_hud
		end, "Enable Lua HUD", 9, not disable_lua_hud), 2, 7)
	--	Conditional display for HUD options.
	local cond = Conditional_widget:new(0, 0, not disable_lua_hud, function()
			return not disable_lua_hud
		end, nil)
	--	Jump predictor toggle.
	cond:add(make_emerald_toggle(
		function(self)
			enable_predictor = not enable_predictor
		end, nil,
		function()
			return enable_predictor
		end, "Enable Jump Predictor", 9, enable_predictor), 0, 0)
	--	Main game HUD toggle.
	cond:add(make_emerald_toggle(
		function(self)
			game_hud = not game_hud
		end, nil,
		function()
			return game_hud
		end, "Show Main HUD", 9, game_hud), 0, 11)
	for n=1,2 do
		--	Pn toggle.
		cond:add(make_emerald_toggle(
			function(self)
				active_char_huds[n] = not active_char_huds[n]
			end, nil,
			function()
				return active_char_huds[n]
			end, string.format("Show Player %d HUD", n), 9, active_char_huds[n]), 0, 11 * (n + 1))
	end
	--	Rng seed HUD toggle.
	cond:add(make_emerald_toggle(
		function(self)
			show_rng = not show_rng
		end, nil,
		function()
			return show_rng
		end, "Show Rng Seed HUD", 9, stat_hud), 0, 44)
	--	Status HUD toggle.
	cond:add(make_emerald_toggle(
		function(self)
			stat_hud = not stat_hud
		end, nil,
		function()
			return stat_hud
		end, "Show Status HUD", 9, stat_hud), 0, 55)
	--	Boss HUD toggle.
	cond:add(make_emerald_toggle(
		function(self)
			boss_hud_active = not boss_hud_active
		end, nil,
		function()
			return boss_hud_active
		end, "Show Boss HUD", 9, boss_hud_active), 0, 66)
	fra0:add(cond, 2, 7 + 11)
	self:add(fra0, 2, 5)

	return self
end

