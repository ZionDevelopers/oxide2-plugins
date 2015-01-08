--[[ 
 Warp System
 
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
 Version 0.0.1 by Nexus on 08-01-2015 07:58 AM
]]

PLUGIN.Title = "Warp System"
PLUGIN.Description = "Create teleport points with a custom command"
PLUGIN.Version = V(0, 0, 1)
PLUGIN.Author = "Nexus"
PLUGIN.HasConfig = true

local TeleportData = {}

function PLUGIN:Init ()
      self:LoadSavedData()
      command.AddChatCommand( "warp",   self.Object, "cmdManageWarp" )
end

function PLUGIN:LoadSavedData ()
      TeleportData = datafile.GetDataTable( "warp-system" )
      TeleportData = TeleportData or {}
      TeleportData.WarpPoints =  TeleportData.WarpPoints or {}      
end

function PLUGIN:SaveData()  
    -- Save the DataTable
    datafile.SaveDataTable( "warp-system" )
end

function PLUGIN:LoadDefaultConfig () 
 -- General Settings:
    self.Config.Settings = {
        ChatName          = "Warp",
        ConfigVersion     = "0.0.1",
        WarpEnabled       = true
    }
    
    -- Plugin Messages:
    self.Config.Messages = {
        -- Warp System:
        WarpCooldown = "Your warp requests are currently on cooldown. You'll have to wait {time} to use warp again.",
        WarpRemove = "You have removed the warp {name}!",
        WarpList = "The following warps are available:",
        WarpTPStarted = "Teleporting to your home {name} in {countdown} seconds!",
        Warped = "You teleported to the warp '{name}'!",
        WarpListEmpty = "There is no warps available!",
        WarpBack = "You've teleported back to your previous location!",
        WarpBackSave = "Your previous location has been saved, use /warp back to teleport back!",
        WarpBoundaries = "X and Z values need to be between -{boundary} and {boundary} while the Y value needs to be between -100 and 2000!",

        -- General Messages:
        WarpHelp = {
            "As an admin you have access to the following commands:",
            "/warp add <name> - Create a new warp at your current location.",
            "/warp add <name> <x> <y> <z> - Create a new warp to the set of coordinates.",
            "/warp del <name> - Delete a warp.",
            "/warp ren <old name> <new name> - Rename a warp.",
            "/warp go <name> - Goto a warp.",
            "/warp back - Teleport you back to the location that you was before warp.",
            "/warp list - List all saved warps."
        },

        WarpSettings = {
                "Warp System as the current settings enabled: ",
                "Time between goto warps: {cooldown}"
        },

        -- Error Messages:
        WarpNotFound             = "Couldn't find a warp with that name!",
        InvalidCoordinates       = "The coordinates you've entered are invalid!",

        -- Syntax Errors Admin TP System:
        SyntaxCommandWarp = {
            "A Syntax Error Occurred!",
            "You can only use the /warp command as follows:",
            "/warp add <name> - Create a new warp at your current location.",
            "/warp add <name> <x> <y> <z> - Create a new warp to the set of coordinates.",
            "/warp del <name> - Delete a warp.",
            "/warp ren <old name> <new name> - Rename a warp.",
            "/warp go <name> - Goto a warp.",
            "/warp back - Teleport you back to the location that you was before warp.",
            "/warp list - List all saved warps."
        }
    }
end