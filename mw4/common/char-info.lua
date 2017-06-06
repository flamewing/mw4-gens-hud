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
--	Game object data, wrapped up in an object.
--	Written by: Marzo Junior
--	Based on game disassemblies and Gens' RAM search.
--------------------------------------------------------------------------------

require("headers/lua-oo")
require("mw4/common/rom-check")
require("mw4/common/game-info")

GameObject = class{
	offset         = 0,
}

-- Convenience utility functions
function GameObject:byte(addr)
	return memory.readbyte(addr + self.offset)
end

function GameObject:bytesigned(addr)
	return memory.readbytesigned(addr + self.offset)
end

function GameObject:word(addr)
	return memory.readword(addr + self.offset)
end

function GameObject:wordsigned(addr)
	return memory.readwordsigned(addr + self.offset)
end

function GameObject:long(addr)
	return memory.readlong(addr + self.offset)
end

function GameObject:longsigned(addr)
	return memory.readlongsigned(addr + self.offset)
end

-- Actual information
function GameObject:is_active()
	return self:bytesigned(0xffff9f1a) < 0
end

function GameObject:get_class()
	return self:byte(0xffffb25f)
end

function GameObject:get_type()
	return self:byte(0xffffb260)
end

function GameObject:get_information()
	local kind  = self:byte(0xffffb25e)
	local class = self:get_class()
	local type  = self:get_type()
	local flags = self:byte(0xffffb261)
	return kind,class,type,flags
end

function GameObject:get_routine()
	return self:byte(0xffffb466)
end

function GameObject:get_position()
	local xpospix   = self:word(0xffa122)
	local xpossub   = self:byte(0xffa124)
	local ypospix   = self:word(0xffa226)
	local ypossub   = self:byte(0xffa228)
	return string.format("%5d:%-3d,%5d:%-3d", xpospix, xpossub, ypospix, ypossub)
end

function GameObject:get_speed()
	local xvel      = self:wordsigned(0xffa42e)
	local yvel      = self:wordsigned(0xffa430)
	return string.format("%+5d, %+5d", xvel, yvel)
end

function GameObject:get_anim_info()
	local class = self:byte(0xffa636)
	local mode  = self:byte(0xffa637)
	local type  = self:byte(0xffa638)
	local flags = self:byte(0xffa639)
	local frame = self:byte(0xffaa44)
	return class,mode,type,flags,frame
end

function GameObject:hit_time_left()
	return game:get_flashing_timer()
end

function GameObject:hit_timer()
	return string.format("%5d", self:hit_time_left())
end

function GameObject:hit_active()
	return self:hit_time_left() ~= 0
end

function GameObject:wounded_icon()
	return self.curr_set.wounded
end

function GameObject:construct(offset)
	self.offset = offset
	return self
end

--------------------------------------------------------------------------------
--	Class for special objects.
--------------------------------------------------------------------------------
SpecialObj = class{
	color = nil
}:extends(GameObject)

function SpecialObj:construct(offset)
	self:super(offset)
	self.color = {
		outline={  0,  0,255,255},
		   fill={  0,  0,255,128}
	}
	return self
end

--------------------------------------------------------------------------------
--	Class for scripted objects.
--------------------------------------------------------------------------------
ScriptedObj = class{
	color = nil
}:extends(GameObject)

function ScriptedObj:construct(offset)
	self:super(offset)
	self.color = {
		outline={255,255,255,255},
		   fill={255,255,255,128}
	}
	return self
end

--------------------------------------------------------------------------------
--	Class for enemy objects.
--------------------------------------------------------------------------------
EnemyObj = class{
	color = nil
}:extends(GameObject)

function EnemyObj:construct(offset)
	self:super(offset)
	self.color = {
		outline={255,255,  0,255},
		   fill={255,255,  0,128}
	}
	return self
end

--------------------------------------------------------------------------------
--	Class for treasure objects.
--------------------------------------------------------------------------------
TreasureObj = class{
	color = nil
}:extends(GameObject)

function TreasureObj:construct(offset)
	self:super(offset)
	self.color = {
		outline={  0,255,  0,255},
		   fill={  0,255,  0,128}
	}
	return self
end

--------------------------------------------------------------------------------
--	Class for damaging objects.
--------------------------------------------------------------------------------
DamagingObj = class{
	color = nil
}:extends(GameObject)

function DamagingObj:construct(offset)
	self:super(offset)
	self.color = {
		outline={255,  0,  0,255},
		   fill={255,  0,  0,128}
	}
	return self
end

--------------------------------------------------------------------------------
--	Class for simple objects.
--------------------------------------------------------------------------------
SimpleObj = class{
	color = nil,
	display = true,
	dy = 0
}:extends(GameObject)

local simple_display_only = {
	[ 0]=true,
	[ 1]=false,
	[ 2]=false,
	[ 3]=true,
	[ 4]=false,
	[ 5]=false,
	[ 6]=true,
	[ 7]=false,
	[ 8]=true,
	[ 9]=false,
	[10]=true,
}

function SimpleObj:get_routine()
	return self:byte(0xffffbf78)
end

function SimpleObj:display_only()
	local rout = self:get_routine()
	return simple_display_only[rout]
end

function SimpleObj:get_code()
	return (not display_only()) and self:long(0xffffc076) or 0
end

function SimpleObj:construct(offset)
	self:super(offset)
	local revgate = self:wordsigned(0xffffcd86)
	if revgate >= 0 and revgate <= 0x28 and memory.readbyte(revgate + 0xffffce0c) == 0xC0 then
		-- don't draw it
		self.display = false
	end
	if self:get_code() == 0x14784 then
		-- Align chest to Asha's centerline.
		self.dy = -16
	else
		self.dy = 0
	end
	if self:get_routine() == 7 then
		-- Giant fire
		self.color = {
			outline={255,  0,  0,255},
			   fill={255,  0,  0,128}
		}
	else
		self.color = {
			outline={255,  0,255,255},
			   fill={255,  0,255,128}
		}
	end
	return self
end

--------------------------------------------------------------------------------
--	Class for miscellaneous objects.
--------------------------------------------------------------------------------
MiscObj = class{
	color = nil
}:extends(GameObject)

function MiscObj:construct(offset)
	self:super(offset)
	self.color = {
		outline={255,  0,255,255},
		   fill={255,  0,255,128}
	}
	print(string.format("MiscObj: %02X", offset))
	return self
end

--------------------------------------------------------------------------------
--	Class for Asha and Pepe.
--------------------------------------------------------------------------------
Character = class{
	color          = nil,
	face           = nil,    --	Currently selected face
	jump_speed     = "",     --	String value for jump prediction
	status_huds    = {},
}:extends(GameObject)

function Character:init(port)
	self.face   = port	--	This manufactures a HUD icon monitor given the adequate functions.
	self.color = {
		outline={  0,255,255,255},
		   fill={  0,255,255,128}
	}
	if port ~= nil then
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
end

function Character:construct(offset, port)
	self:super(offset)
	self:init(port)
	return self
end

--------------------------------------------------------------------------------
--	Factory function
--------------------------------------------------------------------------------
function GameObject.create(offset)
	if offset == 0x00 then
		return Character:new(offset, nil)
	elseif offset == 0x04 then
		return Character:new(offset, nil)
	elseif offset <= 0x30 then
		return SpecialObj:new(offset)
	elseif offset <= 0x80 then
		local self = GameObject:construct(offset)
		local type = self:get_class()
		if type == 0 then
			return ScriptedObj:new(offset)
		elseif type == 4 then
			return EnemyObj:new(offset)
		elseif type == 4 then
			return TreasureObj:new(offset)
		else
			return DamagingObj:new(offset)
		end
	elseif offset <= 0xc8 then
		return SimpleObj:new(offset)
	else
		return MiscObj:new(offset)
	end
end

