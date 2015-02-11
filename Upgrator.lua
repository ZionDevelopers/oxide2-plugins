--[[ 
 Upgrator
 
 Copyright (c) 2015 Nexus <talk@juliocesar.me>, <http://steamcommunity.com/profiles/76561197983103320/>
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 $Id$
 Version 0.0.0 by Nexus on 02-10-2015 11:39 PM (UTC -03:00)
]]--

PLUGIN.Name = "Upgrator"
PLUGIN.Title = "The Upgrator"
PLUGIN.Description = "Upgrate building by shooting!"
PLUGIN.Version = V(0, 0, 0)
PLUGIN.Author = "Nexus"

local UP = {}

UP.ox = PLUGIN

-- Define noDamage
UP.noDamage = nil

-- -----------------------------------------------------------------------------------
-- UP:disableDamage(hitinfo)
-- -----------------------------------------------------------------------------------
-- Disable damage
-- -----------------------------------------------------------------------------------
function UP:disableDamage(hitinfo)
  hitinfo.damageTypes = noDamage
  hitinfo.DoHitEffects = false
  hitinfo.HitMaterial = 0
end

function PLUGIN:Init()
  -- Get no damage type
  UP.noDamage = new(Rust.DamageTypeList._type, nil)
end

-- -----------------------------------------------------------------------------
-- PLUGIN:OnEntityAttacked(entity,hitinfo)
-- called when trying to hit an entity
-- if return behavior not null, will cancel the damage
-- -----------------------------------------------------------------------------
function PLUGIN:OnEntityAttacked(entity, hitinfo)
  if entity:GetComponent("BuildingBlock") then
    UP.disableDamage(hitinfo)
    entity:GetComponent("BaseCombatEntity").health = entity:MaxHealth()
  end
end