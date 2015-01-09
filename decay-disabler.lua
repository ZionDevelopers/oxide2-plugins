--[[ 
 Decay Disabler
 
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
 Version 0.0.2 by Nexus on 01-08-2015 10:03 PM (GTM -03:00)
]]

PLUGIN.Title = "Decay disabler"
PLUGIN.Description = "Disable decay of buildings"
PLUGIN.Version = V(0, 0, 2)
PLUGIN.Author = "Nexus"
PLUGIN.ResourceId = 761

-- -----------------------------------------------------------------------------------
-- PLUGIN:OnStructureDecay(structure)
-- -----------------------------------------------------------------------------------
-- When a building trigger decay
-- -----------------------------------------------------------------------------------
function PLUGIN:OnStructureDecay(structure)
    return true
end