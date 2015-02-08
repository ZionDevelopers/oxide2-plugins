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
 Version 0.0.6 by Nexus on 02-07-2015 03:41 PM (UTC -03:00)
]]--

PLUGIN.Name = "warp-system"
PLUGIN.Title = "Warp System"
PLUGIN.Description = "Create teleport points with a custom command"
PLUGIN.Version = V(0, 0, 6)
PLUGIN.Author = "Nexus"
PLUGIN.HasConfig = true
PLUGIN.ResourceId  = 760

-- Define Warp System Class
local Warp = {}

Warp.Data = {}
Warp.TPVecs = {}
Warp.TPPrevious = {}
Warp.Timers = {}
Warp.ConfigVersion = "0.0.2"
Warp.ox = PLUGIN

-- Define Settings
Warp.Settings = {}

-- Define Messages
Warp.Messages = {}

-- General Settings:
Warp.DefaultSettings = {
  ChatName = "Warp:",
  ConfigVersion = "0.0.2",
  Enabled = true,
  RequiredAuthLevel = 2,
  EnableCooldown = true,
  EnableCountDown = true,
  EnableDailyLimit = true,
  EnableDailyLimitForAdmin = false,
  EnableCoolDownForAdmin = false,
  Cooldown = 600,
  Countdown = 15,
  DailyLimit = 10,
}

-- Plugin Messages:
Warp.DefaultMessages = {
  -- Warp System:
  Remove = "You have removed the warp %s!",
  List = "The following warps are available:",
  ListEmpty = "There is no warps available at the moment!",
  Warped = "You Warped to '%s'!",
  ListEmpty = "There is no warps available!",
  Back = "You've teleported back to your previous location!",
  BackSave = "Your previous location has been saved before you warped, use /warp back to teleport back!",
  Save = "You have saved the %s warp as %d, %d, %d!",
  Delete = "You have deleted the %s warp!",
  Ren = 'You have renamed the warp %s to %s!',
  AuthNeeded = 'You don\'t have the right Auth Level to use "%s!"',
  Exists = 'The warp %s already exists!',
  Cooldown = "Warp requests have a cooldown of %ds. You need wait %ds to use a Warp again.",
  LimitReached = "You have reached the daily limit of %d, You need wait until tomorrow to warp again!",
  Interrupted = "You was interrupted, Before Warp!",
  Pending = "You cannot use a Warp now, Because you are still waiting to get Warped!",
  Started = "You Warp request is on the wait list, It will start on %d seconds.",

  -- Error Messages:
  NotFound = "Couldn't find the %s warp !",

  -- General Messages:
  HelpAdmin = {
    "As an admin you have access to the following commands:",
    "/warp add <name> - Create a new warp at your current location.",
    "/warp add <name> <x> <y> <z> - Create a new warp to the set of coordinates.",
    "/warp del <name> - Delete a warp.",
    "/warp go <name> - Goto a warp.",
    "/warp back - Teleport you back to the location that you was before warp.",
    "/warp list - List all saved warps."
  },

  HelpUser = {
    "As an user you have access to the following commands:",
    "/warp go <name> - Goto a warp.",
    "/warp back - Teleport you back to the location that you was before warp.",
    "/warp list - List all saved warps."
  },

  -- Syntax Errors Warp System:
  SyntaxCommandWarp = {
    "A Syntax Error Occurred!",
    "You can only use the /warp command as follows:",
    "/warp add <name> - Create a new warp at your current location.",
    "/warp add <name> <x> <y> <z> - Create a new warp to the set of coordinates.",
    "/warp del <name> - Delete a warp.",
    "/warp go <name> - Goto a warp.",
    "/warp back - Teleport you back to the location that you was before warp.",
    "/warp list - List all saved warps."
  }
}

-- -----------------------------------------------------------------------------------
-- PLUGIN:Init()
-- -----------------------------------------------------------------------------------
-- On plugin initialisation the required in-game chat commands are registered and data
-- from the DataTable file is loaded.
-- -----------------------------------------------------------------------------------
function PLUGIN:Init ()
  self:LoadSavedData()
  command.AddChatCommand("warp", self.Plugin, "cmdWarp")
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:LoadSavedData()
-- -----------------------------------------------------------------------------------
-- Load the DataTable file into a table or create a new table when the file doesn't
-- exist yet.
-- -----------------------------------------------------------------------------------
function PLUGIN:LoadSavedData()
  Warp.Data = datafile.GetDataTable("warp-system")
  Warp.Data = Warp.Data or {}
  Warp.Data.WarpPoints =  Warp.Data.WarpPoints or {}
  Warp.Data.Usage = Warp.Data.Usage or {}
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SaveData()
-- -----------------------------------------------------------------------------------
-- Saves the table with all the warpdata to a DataTable file.
-- -----------------------------------------------------------------------------------
function PLUGIN:SaveData()
  -- Save the DataTable
  datafile.SaveDataTable("warp-system")
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:LoadDefaultConfig()
-- -----------------------------------------------------------------------------------
-- The plugin uses a configuration file to save certain settings and uses it for
-- localized messages that are send in-game to the players. When this file doesn't
-- exist a new one will be created with these default values.
-- -----------------------------------------------------------------------------------
function PLUGIN:LoadDefaultConfig()
  self.Config.Settings = Warp.DefaultSettings
  self.Config.Messages = Warp.DefaultMessages
end

-- -----------------------------------------------------------------------------------
-- Warp:IsAllowed(player)
-- -----------------------------------------------------------------------------------
-- Checks if the player is allowed to run an admin (or moderator) only command.
-- -----------------------------------------------------------------------------------
function Warp:IsAllowed(player)
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
-- PLUGIN:cmdWarp(player, cmd, args)
-- -----------------------------------------------------------------------------------
-- In-game '/warp' command for server admins to be able to manage warps.
-- -----------------------------------------------------------------------------------
function PLUGIN:cmdWarp(player, _, args)
  -- Check if the Warp System is enabled.
  if not self.Config.Settings.Enabled then return end

  -- Setup default vars
  local cmd = ''
  local param = ''
  local x = 0
  local y = 0
  local z = 0

  -- Check and setup args
  if args.Length == 1 then
    cmd = args[0]
  elseif args.Length == 2 then
    cmd = args[0]
    param = args[1]
  elseif args.Length == 5 then
    cmd = args[0]
    param = args[1]
    x = args[2]
    y = args[3]
    z = args[4]
  end

  -- Check if the command is to add a new warp
  if cmd == 'add' then
    -- Check if the warp is at a current location
    if args.Length >= 2 then
      -- Test for empty strings
      if param ~= '' or param ~= ' ' then
        -- Add a new warp
        Warp:Add(player, param, x, y, z)
      end
    else
      -- Send message to player
      Warp:SendMessage(player, self.Config.Messages.SyntaxCommandWarp)
    end
    -- Check if the command is to delete a warp
  elseif cmd == 'del' then
    -- Check if param is valid
    if param ~= '' and param ~= ' ' then
      -- Delete a warp
      Warp:Del(player, param)
    end
    -- Check if the command is to use a warp
  elseif cmd == 'go' then
    -- Check if param is valid
    if param ~= '' and param ~= ' ' then
      -- Use a Warp
      Warp:Use(player, param)
    end
    -- Check if the command is to go back before warp
  elseif cmd == 'back' then
    -- Go Back to the Previous location to Warp
    Warp:Back(player)
  elseif cmd == 'list' then
    -- List Warps
    Warp:List(player)
  else
    -- Send message to player
    Warp:SendMessage(player, 'Warp command '..cmd..' is not valid!' )
    
    -- Check if player is Allowed
    if Warp:IsAllowed(player) then
      -- Send admin warp commands
      Warp:SendMessage(player, self.Config.Messages.HelpAdmin)
    else
      -- Send user warp commands
      Warp:SendMessage(player, self.Config.Messages.HelpAUser)
    end
  end
end

-- -----------------------------------------------------------------------------
-- Warp:Add(player, name, x, y, z)
-- -----------------------------------------------------------------------------
-- Add a new warp.
-- -----------------------------------------------------------------------------
function Warp:Add(player, name, x, y, z)
  -- Get current location
  local loc = player.transform.position

  -- Check if was sent any loc
  if x ~= 0 and y ~= 0 and z ~= 0 then
    -- Save new location
    local loc = {}
    -- Set new loc
    loc.x = math.floor(x)
    loc.y = math.floor(y)
    loc.z = math.floor(z)
  end

  -- Check if the player is allowed to run the command.
  if self:IsAllowed(player) then
    -- Check if Warp already exists
    if Warp.Data.WarpPoints[name] == nil then
      -- Check for coordinates
      if x == 0 and y == 0 and z == 0 then
        -- Add Warp at player current location
        Warp.Data.WarpPoints[name] = {x = loc.x, y = loc.y, z = loc.z}
      else
        -- Add Warp at the the position
        Warp.Data.WarpPoints[name] = {x = loc.x, y = loc.y, z = loc.z}
      end

      -- Save data
      self.ox:SaveData()

      -- Send message to player
      self:SendMessage(player, self.Messages.Save:format(name, loc.x, loc.y, loc.z) )
    else
      -- Send message to player
      self:SendMessage(player, self.Messages.Exists:format(name))
    end
  else
    -- Send message to player
    self:SendMessage(player, self.Messages.AuthNeeded:format('/warp add'))
  end
end

-- -----------------------------------------------------------------------------
-- Warp:Del(player, name)
-- -----------------------------------------------------------------------------
-- Delete a warp.
-- -----------------------------------------------------------------------------
function Warp:Del(player, name)
  -- Check if the player is allowed to run the command.
  if self:IsAllowed(player) then
    -- Check if Warp exists
    if Warp.Data.WarpPoints[name] ~= nil then
      -- Delete warp
      Warp.Data.WarpPoints[name] = nil

      -- Save data
      self.ox:SaveData()
      -- Send message to player
      self:SendMessage(player, self.Config.Messages.Delete:format(name))
    else
      -- Send message to player
      self:SendMessage(player, self.Config.Messages.NotFound)
    end
  else
    -- Send message to player
    self:SendMessage(player, self.Config.Messages.AuthNeeded:format('/warp del'))
  end
end

-- -----------------------------------------------------------------------------
-- Warp:Ren(player, oldname, newname)
-- -----------------------------------------------------------------------------
-- Rename a warp.
-- -----------------------------------------------------------------------------
function Warp:Ren(player, oldname, newname)
  -- Check if the player is allowed to run the command.
  if self:IsAllowed(player) then
    -- Check if Warp exists
    if Warp.Data.WarpPoints[oldname] ~= nil then
      -- Check if Warp new exists
      if Warp.Data.WarpPoints[newname] == nil then
        -- Create a new warp
        Warp.Data.WarpPoints[newname] = Warp.Data.WarpPoints[oldname]
        -- Delete warp
        Warp.Data.WarpPoints[oldname] = nil

        -- Save data
        self.ox:SaveData()
        -- Send message to player
        self:SendMessage(player, self.Messages.Ren:format(newname, oldname))
      else
        -- Send message to player
        self:SendMessage( player, self.Messages.Exists:format(newname))
      end
    else
      -- Send message to player
      self:SendMessage(player, self.Messages.WarpNotFound:format(oldname))
    end
  else
    -- Send message to player
    self:SendMessage( player, self.Messages.AuthNeeded:format('/warp ren'))
  end
end

-- -----------------------------------------------------------------------------
-- Warp:Use(player, name)
-- -----------------------------------------------------------------------------
-- Use a Warp to teleport player to a location.
-- -----------------------------------------------------------------------------
function Warp:Use(player, name)
  -- Check if Warp exists
  if Warp.Data.WarpPoints[name] ~= nil then
    -- Teleport Player to Location
    self:Start(player, Warp.Data.WarpPoints[name].x, Warp.Data.WarpPoints[name].y, Warp.Data.WarpPoints[name].z, self.Messages.Warped:format(name), true)
  else
    -- Send message to player
    self:SendMessage(player, self.Messages.NotFound)
  end
end

-- -----------------------------------------------------------------------------
-- Warp:Back(player)
-- -----------------------------------------------------------------------------
-- Go back to a point where the player was
-- -----------------------------------------------------------------------------
function Warp:Back(player)
  -- Get PlayerID
  local playerID = rust.UserIDFromPlayer(player)

  -- Check if player already used the Warp
  if Warp.TPPrevious[playerID] ~= nil then
    -- Teleport Player to Location
    self:Start(player, Warp.TPPrevious[playerID].x, Warp.TPPrevious[playerID].y, Warp.TPPrevious[playerID].z. self.Messages.Back, false)
  end
end

-- -----------------------------------------------------------------------------
-- Warp:List(player)
-- -----------------------------------------------------------------------------
-- List all the saved warps
-- -----------------------------------------------------------------------------
function Warp:List(player)
  -- Count the Warp Points
  if self:Count(Warp.Data.WarpPoints) >= 1 then
    -- Send message to player
    self:SendMessage(player, self.Messages.List)

    -- Loop through all the saved locations and print them one by one.
    for location, coordinates in pairs(Warp.Data.WarpPoints) do
      self:SendMessage(player, location..": "..math.floor(coordinates.x).." "..math.floor(coordinates.y).." "..math.floor(coordinates.z))
    end
  else
    -- Send message to player
    self:SendMessage(player, self.Config.Messages.ListEmpty)
  end
end

-- -----------------------------------------------------------------------------
-- Warp:Count(tbl)
-- -----------------------------------------------------------------------------
-- Counts the elements of a table.
-- -----------------------------------------------------------------------------
-- Credit: m-Teleportation
function Warp:Count(tbl)
  local count = 0

  if type(tbl) == "table" then
    for _ in pairs(tbl) do
      count = count + 1
    end
  end

  return count
end

-- -----------------------------------------------------------------------------
-- Warp:Go(player, destination)
-- -----------------------------------------------------------------------------
-- Teleports a player to a specific location.
-- -----------------------------------------------------------------------------
-- Credit: m-Teleportation
function Warp:Go(player, destination)
  -- Let the player sleep to prevent the player from falling through objects.
  player:StartSleeping()

  -- Change the player's position.
  rust.ForcePlayerPosition(player, destination.x, destination.y, destination.z)

  -- Set the player flag to receiving snapshots and update the player.
  player:SetPlayerFlag(global.PlayerFlags.ReceivingSnapshot, true)
  player:UpdateNetworkGroup()
  player:SendFullSnapshot()
end

-- -----------------------------------------------------------------------------
-- Warp:SendMessage(player, message)
-- -----------------------------------------------------------------------------
-- Sends a chatmessage to a player.
-- -----------------------------------------------------------------------------
function Warp:SendMessage(player, message)
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
        -- Send the message to player
        rust.SendChatMessage(player, self.Config.Settings.ChatName, message)
      end
    else
      self:Log("[" .. self.Config.Settings.ChatName .. "] "  .. message )
    end
  end
end

-- ----------------------------------------------------------------------------
-- PLUGIN:ParseRemainingTime( time )
-- ----------------------------------------------------------------------------
-- Returns an amount of seconds as a nice time string.
-- ----------------------------------------------------------------------------
-- Credit: m-Teleportation
function PLUGIN:ParseRemainingTime( time )
    local minutes  = nil
    local seconds  = nil
    local timeLeft = nil

    -- If the amount of seconds is higher than 60 we'll have minutes too, so
    -- start with grabbing the amount of minutes and then take the remainder as
    -- the seconds that are left on the timer.
    if time >= 60 then
        minutes = math.floor( time / 60 )
        seconds = time - ( minutes * 60 )
    else
        seconds = time
    end

    -- Build a nice string with the remaining time.
    if minutes and seconds > 0 then
        timeLeft = minutes .. " min " .. seconds .. " sec "
    elseif minutes and seconds == 0 then
        timeLeft = minutes .. " min "
    else    
        timeLeft = seconds .. " sec "
    end

    -- Return the time string.
    return timeLeft        
end

-- -----------------------------------------------------------------------------
-- PLUGIN:Start(player, x, y, z, sendBackSaveMSG)
-- -----------------------------------------------------------------------------
-- Teleports a player to a set of coordinates.
-- -----------------------------------------------------------------------------
-- Credit: m-Teleportation
function Warp:Start(player, x, y, z, doneMessage, sendBackSaveMSG)
      
  -- Get playerID          
  local playerID = rust.UserIDFromPlayer(player)
  
  -- Setup variables with todays date and the current timestamp.
  local timestamp   = time.GetUnixTimestamp()
  local currentDate = tostring(time.GetCurrentTime():ToString("d"))

  -- Check if there is saved teleport data available for the
  -- player.
  if Warp.Data.Usage[playerID] then
    if Warp.Data.Usage[playerID].date ~= currentDate then
        Warp.Data.Usage[playerID] = nil
    end
  end

  -- Grab the user his/her teleport data.
  Warp.Data.Usage[playerID] = Warp.Data.Usage[playerID] or {}
  Warp.Data.Usage[playerID].amount = Warp.Data.Usage[playerID].amount or 0
  Warp.Data.Usage[playerID].date = currentDate
  Warp.Data.Usage[playerID].timestamp = Warp.Data.Usage[playerID].timestamp or 0

  -- Check if the cooldown option is enabled and if it is make
  -- sure that the cooldown time has passed.
  if self.Settings.EnableCooldown and (timestamp-Warp.Data.Usage[playerID].timestamp) < self.Settings.Cooldown and (not self:IsAllowed(player) and not self.Settings.EnableCooldownForAdmin) then
    -- Get the remaining time.
    local remainingTime = self:ParseRemainingTime(self.Settings.Cooldown-(timestamp-Warp.Data.Usage[playerID].timestamp))
    -- Teleport is on cooldown, show a message to the player.
    self:SendMessage(player, self.Messages.Cooldown:format(remainingTime))
  
    return
  end

  -- Check if the teleports daily limit is enabled and make sure
  -- that the player has not yet reached the limit.
  if self.Settings.EnabledDailyLimit and Warp.Data.Usage[playerID].amount >= self.Settings.DailyLimit and (not self:IsAllowed(player) and not self.Settings.EnableDailyLimitForAdmin) then
    -- The player has reached the limit, show a message to the
    -- player.
    self:SendMessage(player, self.Messages.LimitReached:format(self.Settings.DailyLimit))
  
    return
  end

  -- Check if the player already has a teleport pending.
  if Warp.Timers[playerID] then
    -- Send a message to the player.
    self:SendMessage(player, self.Messages.Pending)

    return
  end
  
  -- no limits were reached so we ca
  -- teleport the player after a short delay.
  Warp.Timers[playerID] = timer.Once(self.Settings.Countdown, function()
    -- set the destination for the player.
    local destination = new(UnityEngine.Vector3._type, nil)
    destination.x = x
    destination.y = y
    destination.z = z
    
    -- Save current position
    Warp.TPPrevious[playerID] = {x = player.transform.position.x, y = player.transform.position.y, z = player.transform.position.z}
    
    -- Teleport the player to the destination.
    self:Go(player, destination)
    
    -- Modify the teleport amount and last teleport
    -- timestamp.
    Warp.Data.Usage[playerID].amount = Warp.Data.Usage[playerID].amount + 1
    Warp.Data.Usage[playerID].timestamp = timestamp
    self:SaveData()
    
    -- Show a message to the player.
    self:SendMessage(player, doneMessage)
    
    -- Check if we need send a "Back" message
    if sendBackSaveMSG then
      -- Send message to player
      self:SendMessage(player, self.Messages.BackSave)
    end    
    
    -- Remove the pending timer info.
    Warp.Timers[playerID] = nil
  end)
  
  -- Send message to player
  self:SendMessage(player, self.Messages.Started:format(self.Messages.Countdown))
end

-- -----------------------------------------------------------------------------
-- PLUGIN:OnRunCommand(args)
-- -----------------------------------------------------------------------------
-- Triggerd when any player send a chat message.
-- -----------------------------------------------------------------------------
function PLUGIN:OnRunCommand(arg)
  if not arg.connection then return end
  if not arg.cmd then return end
  local cmd = arg.cmd.namefull
  local chat = arg:GetString(0, "text")
  local player = arg.connection.player

  if cmd == "chat.say" and string.sub(chat, 1, 1) == "/" then
    -- Loop through all the saved locations and print them one by one.
    for location, _ in pairs(Warp.Data.WarpPoints) do
      -- Check for a Warp Location
      if chat == '/'..location then
        -- Use Warp
        self:WarpUse(player, location)
      end
    end
  end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SendHelpText(player)
-- -----------------------------------------------------------------------------------
-- HelpText plugin support for the command /help.
-- -----------------------------------------------------------------------------------
function PLUGIN:SendHelpText(player)
  -- Check if player is allowed
  if Warp:IsAllowed(player) then
    -- Send message to player
    Warp:SendMessage(player, self.Config.Messages.HelpAdmin)
  else
    -- Send message to player
    Warp:SendMessage(player, self.Config.Messages.HelpUser)
  end
end

-- ----------------------------------------------------------------------------
-- PLUGIN:OnEntityAttacked(entity, hitinfo)
-- ----------------------------------------------------------------------------
-- OnEntityAttacked Oxide Hook. This hook is triggered when an entity
-- (BasePlayer or BaseNPC) is attacked. This hook is used to interrupt
-- a teleport when a player takes damage.
-- ----------------------------------------------------------------------------
-- Credit: m-Teleportation
function PLUGIN:OnEntityAttacked(entity, hitinfo)
    -- Check if the entity taking damage is a player.
    if entity:ToPlayer() then
        -- The entity taking damage is a player, grab his/her Steam ID.
        local playerID = rust.UserIDFromPlayer( entity )

        -- Check if the player has a teleport pending.
        if Warp.Timers[playerID] ~= nil then
            -- Send a message to the players or to both players.
            Warp:SendMessage(entity, self.Config.Messages.Interrupted)

            -- Destroy the timer.
            Warp.Timers[playerID]:Destroy()

            -- Remove the table entry.
            Warp.Timers[playerID] = nil
        end

    end
end

-- ----------------------------------------------------------------------------
-- PLUGIN:OnPlayerDisconnected(player)
-- ----------------------------------------------------------------------------
-- OnPlayerDisconnected Oxide Hook. This hook is triggered when a player leaves
-- the server. This hook is used to cancel pending the teleport requests and
-- pending teleports for the disconnecting player.
-- ----------------------------------------------------------------------------
-- Credit: m-Teleportation
function PLUGIN:OnPlayerDisconnected(player)
    -- Grab the player his/her Steam ID.
    local playerID = rust.UserIDFromPlayer( player )

    -- Check if the player has a teleport in progress.
    if Warp.Timers[playerID] ~= nil then
        -- The player is about to be teleported, cancel the teleport and remove
        -- the table entry.
        Warp.Timers[playerID]:Destroy()
        Warp.Timers[playerID] = nil
    end
end