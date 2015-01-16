--[[ 
 Admin door unlocker
 
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
 Version 0.0.6 by Nexus on 01-16-2015 07:52 AM (GTM -03:00)
]]

PLUGIN.Name = "admin-door-unlocker"
PLUGIN.Title = "Admin door Unlocker"
PLUGIN.Description = "Unlocks any door for Admins"
PLUGIN.Version = V(0, 0, 6)
PLUGIN.Author = "Nexus"
PLUGIN.HasConfig = true
PLUGIN.ResourceId = 756

-- Define Config version
local ConfigVersion = "0.0.0"

-- -----------------------------------------------------------------------------------
-- PLUGIN:Init()
-- -----------------------------------------------------------------------------------
-- On plugin initialisation the required in-game chat commands are registered and data
-- from the DataTable file is loaded.
-- -----------------------------------------------------------------------------------
function PLUGIN:Init ()
    -- Add chat commands
    command.AddChatCommand( "adu.authlevel", self.Object, "cmdChangeAuthLevel" )
    command.AddChatCommand( "adu.toggle", self.Object, "cmdToggleADU" )
    -- Add console commands
    command.AddConsoleCommand( "adu.authlevel", self.Object, "ccmdChangeAuthLevel" )
    command.AddConsoleCommand( "adu.toggle", self.Object, "ccmdToggleADU" )
    -- Update config version
    self:UpdateConfig()
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:UpdateConfig()
-- -----------------------------------------------------------------------------------
-- It check if the config version is outdated
-- -----------------------------------------------------------------------------------
function PLUGIN:UpdateConfig()
    -- Check if the current config version differs from the saved
    if self.Config.Settings.ConfigVersion ~= ConfigVersion then
        -- Load the default
        self:LoadDefaultConfig()
        -- Save config
        self:SaveConfig()
    end
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
        ChatName = "A.D.U",
        Enabled = true,
        RequiredAuthLevel = 2,
        ConfigVersion = "0.0.0",
    }    
   
    -- Plugin Messages:
    self.Config.Messages = {
        Enabled = "A.D.U has been Enabled!",
        Disabled = "A.D.U has been Disabled!",
        AuthLevelChanged = "You changed the required Auth Level to {required}!",
        InvalidAuthLevel = "You need pass a valid auth level like: admin, owner, mod, moderator, user, player, 0 or 1 or 2!",
        NotAllowed = "You cannot use that command because you don't have the required Auth Level {required}!",
     
        Help = {     
            "/adu.toggle - Toggle (Enable/Disable) A.D.U!",
            "/adu.authlevel <n/s> - Change the required auth level to open locked doors."
        }        
    }
    
end


-- -----------------------------------------------------------------------------
-- PLUGIN:SendMessage( target, message )
-- -----------------------------------------------------------------------------
-- Sends a chatmessage to a player.
-- -----------------------------------------------------------------------------
function PLUGIN:SendMessage( player, message )
    -- Check if the message is a table with multiple messages.
    if type( message ) == "table" then
        -- Loop by table of messages and send them one by one
        for i, message in pairs( message ) do
            self:SendMessage( player, message )
        end
    else
        -- Check if we have an existing target to send the message to.
        if player then
            -- Check if player is connected
            if player:IsConnected() then
                -- "Build" the message to be able to show it correctly.
                message = UnityEngine.StringExtensions.QuoteSafe( message )
                -- Send the message to the targetted player.
                player:SendConsoleCommand( "chat.add \"" .. self.Config.Settings.ChatName .. "\""  .. message )
            end
        else
            print("[" .. self.Config.Settings.ChatName .. "] "  .. message )
        end
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ToggleInventoryGuardian ( player )
-- -----------------------------------------------------------------------------------
-- Enable/Disable Admin Door Unlocker
-- -----------------------------------------------------------------------------------
function PLUGIN:ToggleADU ( player )
      -- Check if Admin Door Unlocker is enabled
      if self.Config.Settings.Enabled then
          -- Disable Admin Door Unlocker
          self.Config.Settings.Enabled = false
          -- Send Message to Player
          self:SendMessage(player, self.Config.Messages.Disabled)
      else
          -- Enable Admin Door Unlocker
          self.Config.Settings.Enabled = true
          -- Send Message to Player
          self:SendMessage(player, self.Config.Messages.Enabled)
      end
      
      -- Save the config.
      self:SaveConfig()
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ChangeAuthLevel ( player, authLevel )
-- -----------------------------------------------------------------------------------
-- Change Auth Level required to use Admin Door Unlocker
-- -----------------------------------------------------------------------------------
function PLUGIN:ChangeAuthLevel ( player, authLevel )
    -- Check if Admin Door Unlocker is enabled
    if self.Config.Settings.Enabled then            
        -- Check for Admin
        if authLevel == "admin" or authLevel == "owner" or authLevel == "2" then
            -- Set required auth level to admin
            self.Config.Settings.RequiredAuthLevel = 2
            -- Send message to player
            self:SendMessage(player, self:Parse(self.Config.Messages.AuthLevelChanged, {required = "2"}))
        -- Check for Mod
        elseif authLevel == "mod" or authLevel == "moderator" or authLevel == "1" then
            -- Set required auth level to moderator
            self.Config.Settings.RequiredAuthLevel = 1
            -- Send message to player
            self:SendMessage(player, self:Parse(self.Config.Messages.AuthLevelChanged, {required = "1"}))
        -- Check for Mod
        elseif authLevel == "user" or authLevel == "player" or authLevel == "0" then
            -- Set required auth level to moderator
            self.Config.Settings.RequiredAuthLevel = 0
            -- Send message to player
            self:SendMessage(player, self:Parse(self.Config.Messages.AuthLevelChanged, {required = "0"}))
        else
            -- Send message to player
            self:SendMessage(player, self.Config.Messages.InvalidAuthLevel)
        end           
        
        -- Save the config.
        self:SaveConfig()
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:IsAllowed( player )
-- -----------------------------------------------------------------------------------
-- Checks if the player is allowed to run an admin (or moderator or user) only command.
-- -----------------------------------------------------------------------------------
function PLUGIN:IsAllowed( player )
    -- Grab the player his AuthLevel and set the required AuthLevel.
    local playerAuthLevel = player:GetComponent("BaseNetworkable").net.connection.authLevel

    -- Compare the AuthLevel with the required AuthLevel, if it's higher or equal
    -- then the user is allowed to run the command.
    if playerAuthLevel >= self.Config.Settings.RequiredAuthLevel then
        return true
    end

    return false
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:IsAdmin( player )
-- -----------------------------------------------------------------------------------
-- Checks if the player is allowed to run an admin only command.
-- -----------------------------------------------------------------------------------
function PLUGIN:IsAdmin( player )
    -- Grab the player his AuthLevel and set the required AuthLevel.
    local playerAuthLevel = player:GetComponent("BaseNetworkable").net.connection.authLevel

    -- Compare the AuthLevel with the required AuthLevel, if it's higher or equal
    -- then the user is allowed to run the command.
    if playerAuthLevel == 2 then
        return true
    end

    return false
end

-- -----------------------------------------------------------------------------
-- PLUGIN:Parse( message, values )
-- -----------------------------------------------------------------------------
-- Replaces the parameters in a message with the corresponding values.
-- -----------------------------------------------------------------------------
-- Credit: m-Teleportation
function PLUGIN:Parse( msg, values )
    for k, v in pairs( values ) do
        -- Replace the variable in the message with the specified value.
        tostring(v):gsub("(%%)", "%%%%") 
        msg = msg:gsub( "{" .. k .. "}", v)
    end

    return msg
end

-- -----------------------------------------------------------------------------
-- PLUGIN:Count( tbl )
-- -----------------------------------------------------------------------------
-- Counts the elements of a table.
-- -----------------------------------------------------------------------------
-- Credit: m-Teleportation
function PLUGIN:Count( tbl ) 
    local count = 0

    if type( tbl ) == "table" then
        for _ in pairs( tbl ) do 
            count = count + 1 
        end
    end

    return count
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SendHelpText( player )
-- -----------------------------------------------------------------------------------
-- HelpText plugin support for the command /help.
-- -----------------------------------------------------------------------------------
function PLUGIN:SendHelpText(player)
    -- Check if user is admin
    if self:IsAdmin( player ) then
        -- Send message to player
        self:SendMessage(player, self.Config.Messages.Help)
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:cmdChangeAuthLevel ( player, _, args )
-- -----------------------------------------------------------------------------------
-- Change required Auth Level
-- -----------------------------------------------------------------------------------
function PLUGIN:cmdChangeAuthLevel( player, _, args )
    -- Check if Admin Door Unlocker is enabled
    if self:IsAdmin(player) and self.Config.Settings.Enabled then
        -- Check for passed args
        if args.Length == 1 then
            -- Change required Auth level
            self:ChangeAuthLevel(player, args[0])
        elseif args.Length == 0 then
            -- Send message to player
            self:SendMessage(player, self.Config.Messages.InvalidAuthLevel)
        end
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:cmdToggleInventoryGuardian ( player )
-- -----------------------------------------------------------------------------------
-- Enable/Disable Inventory Guardian
-- -----------------------------------------------------------------------------------
function PLUGIN:cmdToggleADU ( player )
    -- Check if Inventory Guardian is enabled and If player is allowed
    if self:IsAdmin( player ) then
        -- Restore Player inventory
        self:ToggleADU (player)
    else
        -- Send message to player
        self:SendMessage(player, self:Parse(self.Config.Messages.NotAllowed, {required = "2"}))
    end
end


-- -----------------------------------------------------------------------------------
-- PLUGIN:CanOpenDoor()
-- -----------------------------------------------------------------------------------
-- When any player try to open any door this function is trigged
-- -----------------------------------------------------------------------------------
function PLUGIN:CanOpenDoor( player, door ) 
    -- Check if player is admin
    if self:IsAllowed(player) and self.Config.Settings.Enabled then
        -- Unlock the door
        door:SetFlag(global.Flags.Locked, false)
        -- Lock the door
        timer.Once(0.1, function() door:SetFlag(global.Flags.Locked,true) end)
    end
end


-- -----------------------------------------------------------------------------------
-- PLUGIN:ccmdChangeAuthLevel ( arg )
-- -----------------------------------------------------------------------------------
-- Change required Auth Level
-- -----------------------------------------------------------------------------------
function PLUGIN:ccmdChangeAuthLevel( arg )
    -- Check for passed args
    if arg.Args.Length == 1 then
        -- Change required Auth level
        self:ChangeAuthLevel(nil, arg.Args[0])
    elseif arg.Args.Length == 0 then
        -- Send message to player
        self:SendMessage(player, self.Config.Messages.InvalidAuthLevel)
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ccmdToggleInventoryGuardian ()
-- -----------------------------------------------------------------------------------
-- Enable/Disable Inventory Guardian
-- -----------------------------------------------------------------------------------
function PLUGIN:ccmdToggleADU ()
    -- Restore Player inventory
    self:ToggleADU (nil)
end
