--[[ 
 T.W.I.M.A, The World Is My Arena
 
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
 Version 0.0.0 by Nexus on 01-1.-2015 08:32 PM (GTM -03:00)
]]--

PLUGIN.Name = "TWIMA"
PLUGIN.Title = "T.W.I.M.A"
PLUGIN.Description = "T.W.I.M.A short for The world is my arena, is a PVP Project"
PLUGIN.Version = V(0, 0, 0)
PLUGIN.Author = "Nexus"
PLUGIN.HasConfig = true

-- Define Config version
local ConfigVersion = "0.0.0"

-- Define data
local Data = {}

-- Define noDamage
local noDamage = nil

-- Define TWIMA Class
local TWIMA = {}

-- -----------------------------------------------------------------------------------
-- TWIMA.disableDamage
-- -----------------------------------------------------------------------------------
-- Disable damage 
-- -----------------------------------------------------------------------------------
TWIMA.disableDamage = function (hitinfo)
    hitinfo.damageTypes = noDamage
    hitinfo.DoHitEffects = false
    hitinfo.HitMaterial = 0
end

-- -----------------------------------------------------------------------------
-- TWIMA.SendMessage( target, message )
-- -----------------------------------------------------------------------------
-- Sends a chatmessage to a player.
-- -----------------------------------------------------------------------------
TWIMA.SendMessage = function ( player, message )
    -- Check if the message is a table with multiple messages.
    if type( message ) == "table" then
        -- Loop by table of messages and send them one by one
        for i, message in pairs( message ) do
            TWIMA.SendMessage( player, message )
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
-- TWIMA.IsAllowed( player )
-- -----------------------------------------------------------------------------------
-- Checks if the player have the required authlevel
-- -----------------------------------------------------------------------------------
TWIMA.IsAllowed = function ( player )
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
-- PLUGIN:Init()
-- -----------------------------------------------------------------------------------
-- On plugin initialisation the required in-game chat commands are registered and data
-- from the DataTable file is loaded.
-- -----------------------------------------------------------------------------------
function PLUGIN:Init ()
    -- Add chat commands
    command.AddChatCommand( "twima.toggle", self.Object, "cmdToggle" )
    -- Add console commands
    command.AddConsoleCommand( "twima.toggle", self.Object, "ccmdChangeAuthLevel" )
    -- Load default saved data
    self:LoadSavedData()
    -- Update config version
    self:UpdateConfig()
    -- Get no damage type
    noDamage = new( Rust.DamageTypeList._type, nil)
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
        ChatName = "T.W.I.M.A",
        Enabled = true,
        RequiredAuthLevel = 2,
        ConfigVersion = "0.0.2",
        DisabledGather = true,
        DisabledBuild = true,
        DisabledDestr = true,
        SleepGod = true,
    }    
   
    -- Plugin Messages:
    self.Config.Messages = {
        Enabled = "T.W.I.M.A has been Enabled!",
        Disabled = "T.W.I.M.A has been Disabled!",
     
        Help = {            
            "/saveinv - Save your inventory for later restoration!"
        }        
    }    
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:LoadSavedData()
-- -----------------------------------------------------------------------------------
-- Load the DataTable file into a table or create a new table when the file doesn't
-- exist yet.
-- -----------------------------------------------------------------------------------
function PLUGIN:LoadSavedData ()
    Data = datafile.GetDataTable( "TWIMA" )
    Data = Data or {}
    Data.SpawnStoragePoints = Data.SpawnStoragePoints or {}     
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SaveData()
-- -----------------------------------------------------------------------------------
-- Saves the table with all the warpdata to a DataTable file.
-- -----------------------------------------------------------------------------------
function PLUGIN:SaveData()  
    -- Save the DataTable
    datafile.SaveDataTable( "TWIMA" )
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:OnGather( dispenser, entity, item )
-- -----------------------------------------------------------------------------------
-- This hook is used to capture resource gathering.
-- -----------------------------------------------------------------------------------
function PLUGIN:OnGather( dispenser, entity, item )
    -- Check if entity is a player and if Gather is disabled
    if self.Config.Settings.DisabledGather or TWIMA.IsAllowed(entity) then
        -- Try to destroy the item      
        item = nil
    end
end

-- -----------------------------------------------------------------------------
-- PLUGIN:OnEntityBuilt(helditem,gameObject)
-- called after a player built a structure
-- No return behavior
-- -----------------------------------------------------------------------------
function PLUGIN:OnEntityBuilt(helditem,gameobject)
    -- Check if building is disabled or if that player is not an admin
    if self.Config.Settings.DisabledBuild or not TWIMA.IsAllowed(helditem.ownerPlayer) then
        -- Keep the player from building
        gameobject:GetComponent("BaseEntity"):Kill(ProtoBuf.Mode.None,0,0,nulVector3)
    end
end

-- -----------------------------------------------------------------------------
-- PLUGIN:OnEntityAttacked(entity,hitinfo)
-- called when trying to hit an entity
-- if return behavior not null, will cancel the damage
-- -----------------------------------------------------------------------------
function PLUGIN:OnEntityAttacked(entity, hitinfo)
    -- Check if the entity is a player
    if entity:ToPlayer() then
        -- Check if the player is sleeping and if SleepGod is enabled
        if entity:ToPlayer():IsSleeping() and self.Config.Settings.SleepGod then  
            -- Disable damage
            TWIMA.disableDamage (hitinfo)
            return
        end
    -- Check if entity is a building block or a world item
    elseif entity:GetComponent("BuildingBlock") or entity:GetComponent("WorldItem") then
        -- Check if hitinfo is valid and have something that is attacking and if that something/someone is a player
        if hitinfo ~= nil and hitinfo.Initiator and hitinfo.Initiator:ToPlayer() then
            -- Check if Destruction is disabled or the player is not an admin
            if self.Config.Settings.DisabledDestr or not TWIMA.IsAllowed(hitinfo.Initiator:ToPlayer()) then
                  -- Disable damage
                  TWIMA.disableDamage (hitinfo)        
                  return
            end
        end
    end
end
