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
 Version 0.0.1 by Nexus on 01-08-2015 07:58 AM  (GTM -03:00)
]]

PLUGIN.Title = "Warp System"
PLUGIN.Description = "Create teleport points with a custom command"
PLUGIN.Version = V(0, 0, 1)
PLUGIN.Author = "Nexus"
PLUGIN.HasConfig = true

local WarpData = {}

-- -----------------------------------------------------------------------------------
-- PLUGIN:Init()
-- -----------------------------------------------------------------------------------
-- On plugin initialisation the required in-game chat commands are registered and data
-- from the DataTable file is loaded.
-- -----------------------------------------------------------------------------------
function PLUGIN:Init ()
      self:LoadSavedData()
      command.AddChatCommand( "warp",   self.Object, "cmdWarp" )
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:LoadSavedData()
-- -----------------------------------------------------------------------------------
-- Load the DataTable file into a table or create a new table when the file doesn't
-- exist yet.
-- -----------------------------------------------------------------------------------
function PLUGIN:LoadSavedData ()
      WarpData = datafile.GetDataTable( "warp-system" )
      WarpData = WarpData or {}
      WarpData.WarpPoints =  WarpData.WarpPoints or {}      
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SaveData()
-- -----------------------------------------------------------------------------------
-- Saves the table with all the warpdata to a DataTable file.
-- -----------------------------------------------------------------------------------
function PLUGIN:SaveData()  
    -- Save the DataTable
    datafile.SaveDataTable( "warp-system" )
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:LoadDefaultConfig()
-- -----------------------------------------------------------------------------------
-- The plugin uses a configuration file to save certain settings and uses it for
-- localized messages that are send in-game to the players. When this file doesn't
-- exist a new one will be created with these default values.
-- -----------------------------------------------------------------------------------
function PLUGIN:LoadDefaultConfig () 
 -- General Settings:
    self.Config.Settings = {
        ChatName          = "Warp",
        ConfigVersion     = "0.0.1",
        WarpEnabled       = true
    }
    
    -- Warp System Settings: 
    self.Config.Warp = {
        Cooldown          = 600,
        Countdown         = 15,
        DailyLimit        = 500,
        ModeratorsCanManageWarps = true
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
                "Time between goto warps: {cooldown}",
                "Daily limit of goto warps: {limit}"
        },

        -- Error Messages:
        WarpNotFound = "Couldn't find a warp with that name!",
        InvalidCoordinates = "The coordinates you've entered are invalid!",
        WarpGotoLimitReached = "You have reached the daily limit of {limit} warp goto today!",

        -- Syntax Errors Warp System:
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

-- -----------------------------------------------------------------------------------
-- PLUGIN:IsAllowed( player )
-- -----------------------------------------------------------------------------------
-- Checks if the player is allowed to run an admin (or moderator) only command.
-- -----------------------------------------------------------------------------------
-- Credit: m-Teleportation

function PLUGIN:IsAllowed( player )
    -- Grab the player his AuthLevel and set the required AuthLevel.
    local playerAuthLevel = player:GetComponent("BaseNetworkable").net.connection.authLevel
    local requiredAuthLevel = 2
    
    -- Check if Moderators are also allowed to use the commands.
    if self.Config.Warp.ModeratorsCanManage then
        -- Moderators are allowed to run the commands, reduce the required AuthLevel
        -- to 1.
        requiredAuthLevel = 1   
    end

    -- Compare the AuthLevel with the required AuthLevel, if it's higher or equal
    -- then the user is allowed to run the command.
    if playerAuthLevel >= requiredAuthLevel then
        return true
    end

    return false
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:cmdWarp( player, cmd, args )                               Admin Command
-- -----------------------------------------------------------------------------------
-- In-game '/warp' command for server admins to be able to manage warps.
-- -----------------------------------------------------------------------------------
function PLUGIN: cmdTeleport( player, cmd, args )
    -- Check if the Warp System is enabled.
    if not self.Config.Settings.WarpEnabled then return end
    
    -- Check if the player is allowed to run the command.
    if not self:IsAllowed( player ) then return end
    
    -- Check of the command is to add a new warp
    if args[0] == 'add' then
      -- Check if the warp is at a current location
      if args.Length == 2 then
        -- Test for empty strings
        if args[1] ~= '' or args[1] ~= ' ' then
          
        end            
      else
        self:SendMessage( player, self.Config.Messages.SyntaxCommandWarp )
      end
    end
end