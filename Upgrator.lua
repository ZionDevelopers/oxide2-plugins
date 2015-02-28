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
PLUGIN.HasConfig = true

local UP = {}

UP.ox = PLUGIN

-- Define Settings
UP.Settings = {}
-- Define Messages
UP.Messages = {}

UP.Timers = {}

-- General Settings:
UP.DefaultSettings = {
  ChatName = "Upgrator:",
  Enabled = true,
  RequiredAuthLevel = 2,
  ConfigVersion = "0.0.0"
}

-- Plugin Messages:
UP.DefaultMessages = {
  Enabled = "Enabled!",
  Disabled = "Disabled!",
  AuthLevelChanged = "You changed the required Auth Level to %d!",
  InvalidAuthLevel = "You need pass a valid auth level like: admin, owner, mod, moderator, user, player, 0 or 1 or 2!",
  NotAllowed = "You cannot use that command because you don't have the required Auth Level %d!",

  Help = {
    "/up.toggle - Toggle (Enable/Disable) Upgrator [GLOBAL]!",
    "/up.authlevel <n/s> - Change the required auth level.",
    "/upgrator"
  }
}

-- Define noDamage
UP.noDamage = nil

-- -----------------------------------------------------------------------------------
-- UP:UpdateConfig()
-- -----------------------------------------------------------------------------------
-- It check if the config version is outdated
-- -----------------------------------------------------------------------------------
function UP:UpdateConfig()
  -- Check if the current config version differs from the saved
  if self.ox.Config.Settings.ConfigVersion ~= self.DefaultSettings.ConfigVersion then
    -- Load the default
    self.ox:LoadDefaultConfig()
    -- Save config
    self.ox:SaveConfig()
  end
  
  -- Copy Tables
  self.Settings = self.ox.Config.Settings
  self.Messages = self.ox.Config.Messages
end

-- -----------------------------------------------------------------------------
-- UP:SendMessage(player, message)
-- -----------------------------------------------------------------------------
-- Sends a chatmessage to a player.
-- -----------------------------------------------------------------------------
function UP:SendMessage(player, message)
  -- Check if the message is a table with multiple messages.
  if type(message) == "table" then
    -- Loop by table of messages and send them one by one
    for i, message in pairs(message) do
      self:SendMessage(player, message)
    end
  else
    -- Check if we have an existing target to send the message to.
    if player ~= nil then
      -- Check if player is connected
      if player then
        -- Send the message to the targetted player
        rust.SendChatMessage(player, self.Settings.ChatName, message)
      end
    else
      self:Log(self.Settings.ChatName.." "..message )
    end
  end
end

-- -----------------------------------------------------------------------------------
-- UP:Toggle(player)
-- -----------------------------------------------------------------------------------
-- Enable/Disable Admin Door Unlocker
-- -----------------------------------------------------------------------------------
function UP:Toggle(player)
  -- Check if Admin Door Unlocker is enabled
  if self.Settings.Enabled then
    -- Disable Admin Door Unlocker
    self.Settings.Enabled = false
    -- Send Message to Player
    self:SendMessage(player, self.Messages.Disabled)
  else
    -- Enable Admin Door Unlocker
    self.Settings.Enabled = true
    -- Send Message to Player
    self:SendMessage(player, self.Messages.Enabled)
  end

  -- Save the config.
  self.ox:SaveConfig()
end

-- -----------------------------------------------------------------------------------
-- UP:ChangeAuthLevel(player, authLevel)
-- -----------------------------------------------------------------------------------
-- Change Auth Level required to use Admin Door Unlocker
-- -----------------------------------------------------------------------------------
function UP:ChangeAuthLevel(player, authLevel)
  -- Check if Admin Door Unlocker is enabled
  if self.Settings.Enabled then
    -- Check for Admin
    if authLevel == "admin" or authLevel == "owner" or authLevel == "2" then
      -- Set required auth level to admin
      self.Settings.RequiredAuthLevel = 2
      -- Send message to player
      self:SendMessage(player, self.Messages.AuthLevelChanged:format(2))
      -- Check for Mod
    elseif authLevel == "mod" or authLevel == "moderator" or authLevel == "1" then
      -- Set required auth level to moderator
      self.Settings.RequiredAuthLevel = 1
      -- Send message to player
      self:SendMessage(player, self.Messages.AuthLevelChanged:format(1))
      -- Check for Mod
    elseif authLevel == "user" or authLevel == "player" or authLevel == "0" then
      -- Set required auth level to moderator
      self.Settings.RequiredAuthLevel = 0
      -- Send message to player
      self:SendMessage(player, self.Messages.AuthLevelChanged:format(0))
    else
      -- Send message to player
      self:SendMessage(player, self.Messages.InvalidAuthLevel)
    end

    -- Save the config.
    self.ox:SaveConfig()
  end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:IsAllowed(player)
-- -----------------------------------------------------------------------------------
-- Checks if the player is allowed to run an admin (or moderator or user) only command.
-- -----------------------------------------------------------------------------------
function UP:IsAllowed(player)
  -- Check if player is valid
  if player ~= nil then
    -- Check if is connected
    if player:GetComponent("BaseNetworkable").net.connection ~= nil then
      -- Compare the Player's AuthLevel with the required AuthLevel, if it's higher or equal
      return player:GetComponent("BaseNetworkable").net.connection.authLevel >= self.Settings.RequiredAuthLevel
    end
  end

  return false
end

-- -----------------------------------------------------------------------------------
-- UP:Log(message)
-- -----------------------------------------------------------------------------------
-- Log normal
-- -----------------------------------------------------------------------------------
-- Credit: HooksTest
-- -----------------------------------------------------------------------------------
function UP:Log(message)
  local arr = util.TableToArray({message})
  UnityEngine.Debug.Log.methodarray[0]:Invoke(nil, arr)
end

-- -----------------------------------------------------------------------------------
-- UP:LogWarning(message)
-- -----------------------------------------------------------------------------------
-- Log Warning
-- -----------------------------------------------------------------------------------
-- Credit: HooksTest
-- -----------------------------------------------------------------------------------
function UP:LogWarning(message)
  local arr = util.TableToArray({message})
  UnityEngine.Debug.LogWarning.methodarray[0]:Invoke(nil, arr)
end

-- -----------------------------------------------------------------------------------
-- UP:LogError(message)
-- -----------------------------------------------------------------------------------
-- Log Error
-- -----------------------------------------------------------------------------------
-- Credit: HooksTest
-- -----------------------------------------------------------------------------------
function UP:LogError(message)
  local arr = util.TableToArray({message})
  UnityEngine.Debug.LogError.methodarray[0]:Invoke(nil, arr)
end

-- -----------------------------------------------------------------------------------
-- UP:disableDamage(hitinfo)
-- -----------------------------------------------------------------------------------
-- Disable damage
-- -----------------------------------------------------------------------------------
function UP:disableDamage(hitinfo)
  hitinfo.damageTypes = self.noDamage
  hitinfo.DoHitEffects = false
  hitinfo.HitMaterial = 0
end

function PLUGIN:Init()
  -- Get no damage type
  UP.noDamage = new(Rust.DamageTypeList._type, nil)
  UP:UpdateConfig()
end

function PLUGIN:Unload()
  for i, _ in pairs(UP.Timers) do
    UP.Timers[i]:Destroy()
    UP.Timers[i] = nil
  end
end

-- -----------------------------------------------------------------------------
-- PLUGIN:OnEntityAttacked(entity,hitinfo)
-- called when trying to hit an entity
-- if return behavior not null, will cancel the damage
-- -----------------------------------------------------------------------------
function PLUGIN:OnEntityAttacked(entity, hitinfo)
  if entity:GetComponent("BuildingBlock") and hitinfo.Initiator ~= nil and self.Settings.Enabled then
    if hitinfo.Initiator:ToPlayer() then
      local playerID = rust.UserIDFromPlayer(entity)
        if UP:IsAllowed(entity) and UP.Timers[playerID] == nil then
        UP:disableDamage(hitinfo)
        entity:SetGrade(entity.blockDefinition.grades.Length-1)
        entity:GetComponent("BaseCombatEntity").health = entity:MaxHealth()+1
      end
    end
  end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:LoadDefaultConfig()
-- -----------------------------------------------------------------------------------
-- The plugin uses a configuration file to save certain settings and uses it for
-- localized messages that are send in-game to the players. When this file doesn't
-- exist a new one will be created with these default values.
-- -----------------------------------------------------------------------------------
function PLUGIN:LoadDefaultConfig()
  self.Config.Settings = UP.DefaultSettings
  self.Config.Messages = UP.DefaultMessages
end