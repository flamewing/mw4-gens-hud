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

if	base_path == nil then
	base_path = (string.gsub(debug.getinfo(1).source, "mw4%-hud", "?", 1)):sub(2)
	package.path = base_path .. ";" .. package.path
end

--------------------------------------------------------------------------------
--	Script configuration options.
--------------------------------------------------------------------------------
gens.persistglobalvariables({
	-- Enabled HUDs
	game_hud = true,
	show_rng = true,
	active_char_huds = {[1]=true, [2]=true},
	stat_hud = true,
	boss_hud_active = true,
	menu_active = true,	-- ignores disable_lua_hud
	-- Special features
	enable_predictor = true,
	-- Configuration options
	disable_lua_hud = false
})

--------------------------------------------------------------------------------
--	Include all of the script subfiles.
--------------------------------------------------------------------------------
require("mw4/common/rom-check")
require("headers/register")
require("headers/widgets")
require("mw4/common/config-menu")
require("mw4/common/game-info")
require("mw4/common/char-info")
require("mw4/common/jump-predictor")
require("mw4/common/status-widget")
require("mw4/common/character-hud")
require("mw4/common/boss-hud")

--------------------------------------------------------------------------------
--	HUD components: status icons, character HUDs, boss HUDs.
--------------------------------------------------------------------------------
Asha = Character:new(true , "asha")
Pepe = Character:new(false, "pepe")
local status_huds = Status_widget:new(119, 0, stat_hud)
local char_huds = {
	[1] = Character_hud:new(Asha, 0, 198, active_char_huds[1]),
	[2] = Character_hud:new(Pepe, 133, 198, active_char_huds[2])
}
local boss_hud = Boss_widget:new(0, 0, boss_hud_active)

--------------------------------------------------------------------------------
--	Main game HUD
--------------------------------------------------------------------------------
local function create_main_hud(ly, w, h)
	local main_hud = Frame_widget:new(0, 0, w, h)
	main_hud:add_status_icon( 5,          5, "heart-red" , bind(game.get_hearts     , game), nil, nil, 10, 0)
	main_hud:add_status_icon( 5, 1 * ly - 1, "heart-blue", bind(game.get_blue_hearts, game), nil, nil, 10, 0)
	main_hud:add_status_icon(71,          5, "gold-bag"  , bind(game.get_gold       , game), nil, nil, 18, 0)
	return main_hud
end

local main_hud = Container_widget:new(0, 3, game_hud)
main_hud:add(create_main_hud(14, 115, 25), 3, 0)
main_hud:add_toggle(make_toggle(25, false, Container_widget.toggled, main_hud, game_hud), 0, 0)

--------------------------------------------------------------------------------
--	RNG HUD
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--	This is a widget for displaying selectable rng seeds.
--------------------------------------------------------------------------------
Rng_num_rows = 8
Rng_widget = class{
}:extends(Container_widget)

function Rng_widget:construct(x, y, active)
	self:super(x, y, active)
	return self
end

function Rng_widget:draw()
	if self.active then
		local newseed = game:get_rng_seed()
		local list = game:get_rng_list(Rng_num_rows)
		local y = 0
		self.children = {}
		for i=0,#list do
			local seed = list[i]
			if i == 0 then
				border = {255, 0, 0, 255}
				fill = {127, 0, 0, 255}
			else
				border = {0, 0, 255, 127}
				fill = {0, 0, 127, 127}
			end
		self:add(make_button(function(seed) memory.writelong(0xffffcb26, seed) end, seed,
				                 string.format("%08X", game:random_number(seed)), 39, 8, border, fill), 0, y)
			y = y + 9
		end
			for _,m in pairs(self.children) do
			m:draw()
		end
	end
	if self.toggle then
		self.toggle:draw()
	end
	return self.active
end

local function create_rng_hud(ly, w, h)
	local rng_hud = Frame_widget:new(0, 0, w, h)
	rng_hud:add(Rng_widget:new(0, 0, true), 0, 0)
	return rng_hud
end

local rng_hud = Container_widget:new(209, 6+24, show_rng, 8)
rng_hud:add(create_rng_hud(14, 40, (Rng_num_rows + 1) * 9 - 1), 3, 0)
rng_hud:add_toggle(make_toggle((Rng_num_rows + 1) * 9 - 1, false, Container_widget.toggled, rng_hud, show_rng), 43, 0)

--------------------------------------------------------------------------------
--	Main workhorse function
--------------------------------------------------------------------------------
local flash_nomovie = false

--	Reads mem values, emulates a couple of frames, displays everything
draw_hud = function ()
	--	look 2 frames into the future, pretending the B button is held,
	--	and get what the X and Y velocity of the player will be
	if want_prediction() then
		predict_jumps()
	end

	--	Display big red translucent box all over screen if not playing or recording a movie.
	if flash_nomovie and not movie.recording() and not movie.playing() then
		gui.box  (0, 0, 319, 223, {255, 0, 0, 128}, {255, 0, 0, 255})
	end

	local alphas = {outline=255, fill=128}
	local color_list = {
		[        0]={outline={255,255,255,alphas.outline}, fill={255,255,255,alphas.fill}},
		[        4]={outline={255,  0,  0,alphas.outline}, fill={255,  0,  0,alphas.fill}},
		[        8]={outline={  0,255,  0,alphas.outline}, fill={  0,255,  0,alphas.fill}},
		[       12]={outline={255,255,  0,alphas.outline}, fill={255,255,  0,alphas.fill}},
		["special"]={outline={255,  0,255,alphas.outline}, fill={255,  0,255,alphas.fill}},
		[ "simple"]={outline={  0,255,255,alphas.outline}, fill={  0,255,255,alphas.fill}},
	}
	local camX = memory.readlong(0xffffc73a)
	local camY = memory.readlong(0xffffc746)
	for offset = 0,0x104,4 do
		local value = memory.readbytesigned(offset + 0xffff9f1a)
		if value < 0 then
			local type = memory.readbyte(offset + 0xffffb25f)
			local color
			local routine
			if offset <= 8 then
				color = color_list[0]
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
			if color ~= nil then
				local xlen = memory.readbyte(offset + 0xffffad4a)
				local ylen = memory.readbyte(offset + 0xffffad4b)
				gui.box(xpos - xlen, ypos - ylen, xpos + xlen, ypos + ylen, color.fill, color.outline)
			end
			--gui.text(xpos-7, ypos-7, string.format("%02X%02X\n%04X", offset, type, routine), 'white', 'black')
			gui.text(xpos-3, ypos-3, string.format("%02X", offset), 'white', 'black')
		end
	end

	--	Basic game HUD
	game_hud = main_hud:draw()

	--	RNG return lists
	show_rng = rng_hud:draw()

	--	The character huds:
	for i, hud in pairs(char_huds) do
		active_char_huds[i] = hud:draw()
	end
	--[[
	boss_hud_active = boss_hud:draw()
	--]]

	--	General timers: invincibility, speed shoes, super status, etc.
	stat_hud = status_huds:draw()
end

local function do_huds()
	draw_hud()
end

local function do_huds_load()
	for _, item in pairs(status_huds.children) do
		item.active = false
	end
	status_huds.children = {}
	do_huds()
end

local function toggle_lua_hud(enable)
	if enable then
		callbacks.gens.registerafter:add(do_huds)
		callbacks.savestate.registerload:add(do_huds_load)
	else
		callbacks.gens.registerafter:remove(do_huds)
		callbacks.savestate.registerload:remove(do_huds_load)
	end
end

--------------------------------------------------------------------------------
--	Starting options.
--------------------------------------------------------------------------------
local function apply_options()
	if char_huds then
		for n = 1,#char_huds do
			char_huds[n]:set_state(active_char_huds[n])
		end
	end
	main_hud:set_state(game_hud)
	rng_hud:set_state(show_rng)
	boss_hud:set_state(boss_hud_active)
	if boss_hud_active then
		boss_hud:register()
	else
		boss_hud:unregister()
	end
	status_huds:set_state(stat_hud)
	toggle_lua_hud(not disable_lua_hud)
end

local function reset_config()
	game_hud = true
	show_rng = true
	active_char_huds = {[1]=true, [2]=true}
	stat_hud = true
	boss_hud_active = true
	menu_active = true
	enable_predictor = true
	disable_lua_hud = false
end

--------------------------------------------------------------------------------
--	Configuration menu.
--------------------------------------------------------------------------------
local menubtn = Container_widget:new(0, 29, menu_active)
local menu = Config_menu:new(73, 55, 110, 112, function ()
		apply_options()
		if not disable_lua_hud then
			do_huds()
		end
		menu_active = menubtn:draw()
	end, menu_active)

menubtn:add_toggle(make_toggle(8, false, Container_widget.toggled, menubtn, not disable_lua_hud), 0, 0)
menubtn:add(make_button(Config_menu.menu_loop, menu, "Options", 42, 8, nil, {0, 0, 0, 192}), 0, 0)
callbacks.gui.register:add(function()
		menu_active = menubtn:draw()
	end)

--------------------------------------------------------------------------------
--	Apply the options and do initial draw.
--------------------------------------------------------------------------------
apply_options()
update_input()
if not disable_lua_hud then
	do_huds()
end
menubtn:draw()

