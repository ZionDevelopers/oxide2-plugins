--[[ 
 Inventory Guardian
 
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
 Version 0.1.2 by Nexus on 02-04-2015 03:02 PM (GTM -03:00)
]]--

PLUGIN.Name = "Inventory-Guardian"
PLUGIN.Title = "Inventory Guardian"
PLUGIN.Description = "Keep players inventory after server wipes"
PLUGIN.Version = V(0, 1, 2)
PLUGIN.Author = "Nexus"
PLUGIN.HasConfig = true
PLUGIN.ResourceId = 773

-- Define Inventory Guardian class
local IG = {}

-- Define Inventory Data
IG.Data = {}

-- Define Player deaths table
IG.PlayerDeaths = {}

-- Define default save protocol
IG.SaveProtocol = 0

-- Get a Copy of PLUGIN Class
IG.ox = PLUGIN

-- Define Config version
IG.ConfigVersion = "0.0.4"

-- Define Local config values
IG.Settings = {
    ChatName = "Inventory Guardian",
    Enabled = true,
    RequiredAuthLevel = 2,
    ConfigVersion = "0.0.4",
    RestoreUponDeath = false,
    AutoRestore = true,
    ChatFormat = "<color=#af5>%s:</color> %s",
    ChatPlayerIcon = true
}    
   
-- Define Plugin Messages:
IG.Messages = {
    Saved = "Your inventory was been saved!",
    Restored = "Your inventory has been restored!",
    RestoreUponDeathEnabled = "Restore Upon Death Enabled!",
    RestoreUponDeathDisabled = "Restore Upon Death Disabled!",
    RestoreEmpty = "You don't have any saved inventory, so cannot be restored!",
    DeletedInv = "Your saved inventory was deleted!",
    Enabled = "Inventory Guardian has been Enabled!",
    Disabled = "Inventory Guardian has been Disabled!",
    AutoRestoreDisabled = "Automatic Restoration has been disabled!",
    AutoRestoreEnabled = "Automatic Restoration has been enabled!",
    AuthLevelChanged = "You changed the required Auth Level to %s!",
    CantDoDisabled = "We are unable to run that command since the Inventory Guardian is disabled!",
    NotAllowed = "You cannot use that command because you don't have the required Auth Level %s!",
    InvalidAuthLevel = "You need pass a valid auth level like: admin, owner, mod, moderator, 1 or 2!",
    RestoredPlayerInventory = "Player \"%s\" inventory has been restored!",
    RestoreInit = "Initiating all players inventories restoration...",
    RestoreAll = "All players inventories has been restored!",
    SavedPlayerInventory = "Player \"%s\" inventory has been saved!",
    SaveInit = "Initiating all players inventories salvation...",
    SaveAll = "All players inventories has been saved!",
    PlayerNotFound = "The specified player couldn't be found please try again!",
    MultiplePlayersFound = "Found multiple players with that name!",
    DeletedPlayerInventory = "Player \"%s\" inventory has been deleted!",
    DeleteAll = "All players inventories has been deleted!",
    DeleteInit = "Initiating all players inventories deletion...",
    DeleteAll = "All players inventories has been deleted!",
    SelfStriped = "Your current inventory has been cleaned",
    PlayerStriped = "Your current inventory has been cleaned by \"%s\"",
    PlayerStripedBack = "Player's \"%s\" inventory has been cleaned",
    AutoRestoreDetected = "Map wipe was detected!",
    AutoRestoreNotDetected = "Forced map wipe not detected!",
     
    Help = {            
      "/ig.save - Save your inventory for later restoration!",
      "/ig.restore - Restore your saved inventory!",            
      "/ig.delsaved - Delete your saved inventory!",
      "/ig.save <name> - Save player's inventory for later restoration!",
      "/ig.restore <name> - Restore player's saved inventory!",            
      "/ig.delsaved <name> - Delete player's saved inventory!",
      "/ig.restoreupondeath - Toggles the Inventory restoration upon death for all players on the server!",
      "/ig.toggle - Toggle (Enable/Disable) Inventory Guardian!",
      "/ig.autorestore - Toggle (Enable/Disable) Automatic Restoration.",
      "/ig.authlevel <n/s> - Change Inventory Guardian required Auth Level.",
      "/ig.strip - Clear your current inventory.",
      "/ig.strip <name> - Clear player current inventory."
    }   
}

-- -----------------------------------------------------------------------------------
-- IG:UpdateConfig
-- -----------------------------------------------------------------------------------
-- It check if the config version is outdated
-- -----------------------------------------------------------------------------------
function IG:UpdateConfig ()
    -- Check if the current config version differs from the saved
    if self.ox.Config.Settings.ConfigVersion ~= self.ConfigVersion then
        -- Load the default
        self.ox:LoadDefaultConfig()
        -- Save config
        self.ox:SaveConfig()
    end
end

-- -----------------------------------------------------------------------------------
-- IG:ClearSavedInventory(playerID)
-- -----------------------------------------------------------------------------------
-- Clear player's saved inventory on Data Table
-- -----------------------------------------------------------------------------------
function IG:ClearSavedInventory (playerID)
    -- Reset inventory
    self.Data.GlobalInventory [playerID] = {} 
    self.Data.GlobalInventory [playerID]['belt'] = {}
    self.Data.GlobalInventory [playerID]['main'] = {}
    self.Data.GlobalInventory [playerID]['wear'] = {}
    -- Save Inventory
    self.ox:SaveData()
end

-- -----------------------------------------------------------------------------------
-- IG:DeletePlayerSavedInventory(player)
-- -----------------------------------------------------------------------------------
-- Clear player's saved inventory
-- -----------------------------------------------------------------------------------
function IG:DeletePlayerSavedInventory (player)
    -- Check if Inventory Guardian is enabled
    if self.ox.Config.Settings.Enabled then
        -- Grab the player his/her SteamID.
        local playerID = rust.UserIDFromPlayer( player )  
        -- Clear Saved inventory
        self:ClearSavedInventory(playerID)
        -- Send message to user
        self:SendMessage(player, self.ox.Config.Messages.DeletedInv)  
    end    
end

-- -----------------------------------------------------------------------------------
-- IG:SavePlayerInventory (player)
-- -----------------------------------------------------------------------------------
-- Save player inventory
-- -----------------------------------------------------------------------------------
 function IG:SaveInventory (player)
    -- Grab the player his/her SteamID.
    local playerID = rust.UserIDFromPlayer( player )
    
    -- Get Player inventory list
    local belt = player.inventory.containerBelt
    local main = player.inventory.containerMain
    local wear = player.inventory.containerWear
    
    -- Enumerate inventory list
    local beltItems = belt.itemList:GetEnumerator()
    local mainItems = main.itemList:GetEnumerator()
    local wearItems = wear.itemList:GetEnumerator()
    -- Reset counts
    local beltCount = 0
    local mainCount = 0
    local wearCount = 0
    
    -- Reset saved inventory
    self:ClearSavedInventory(playerID)
    
    -- Loop by the Belt Items
    while beltItems:MoveNext() do
      -- Save current item to player's inventory table
      self.Data.GlobalInventory [playerID] ['belt'] [tostring(beltCount)] = {name = tostring(beltItems.Current.info.shortname), amount = beltItems.Current.amount}    
      -- Increment the count
      beltCount = beltCount + 1
    end
    
    -- Loop by the Main Items
    while mainItems:MoveNext() do
        -- Save current item to player's inventory table
        self.Data.GlobalInventory [playerID] ['main'] [tostring(mainCount)] = {name = tostring(mainItems.Current.info.shortname), amount = mainItems.Current.amount}
        -- Increment the count
        mainCount = mainCount + 1
    end
    
    -- Loop by the Wear Items
    while wearItems:MoveNext() do
        -- Save current item to player's inventory table
        self.Data.GlobalInventory [playerID] ['wear'] [tostring(wearCount)] = {name = tostring(wearItems.Current.info.shortname), amount = wearItems.Current.amount}    
        -- Increment the count
        wearCount = wearCount + 1
    end
    
    -- Save inventory data
    self.ox:SaveData()
end

-- -----------------------------------------------------------------------------------
-- IG:SavePlayerInventory (player)
-- -----------------------------------------------------------------------------------
-- Save player inventory and send message
-- -----------------------------------------------------------------------------------
function IG:SavePlayerInventory (player)  
    -- Check if Inventory Guardian is enabled
    if self.ox.Config.Settings.Enabled then 
        -- Save player inventory
        self:SaveInventory(player) 
        -- Send message to user
        self:SendMessage(player, self.ox.Config.Messages.Saved)
    end
end

-- -----------------------------------------------------------------------------------
-- IG:SavedInventoryIsEmpty ( playerID )
-- -----------------------------------------------------------------------------------
-- Check if player's saved inventory is empty
-- -----------------------------------------------------------------------------------
function IG:SavedInventoryIsEmpty (playerID)
    -- Check if player's inventory is null
    if self.Data.GlobalInventory [playerID] == nil then
        return true
    else
        -- Check if all inventory containers are empty too
        return self:Count(self.Data.GlobalInventory [playerID] ['belt']) == 0 and self:Count(self.Data.GlobalInventory [playerID] ['main']) == 0 and self:Count(self.Data.GlobalInventory [playerID] ['wear'] )== 0
    end
end

-- -----------------------------------------------------------------------------
-- PLUGIN:Count( tbl )
-- -----------------------------------------------------------------------------
-- Counts the elements of a table.
-- -----------------------------------------------------------------------------
-- Credit: m-Teleportation
function IG:Count( tbl ) 
    local count = 0

    if type( tbl ) == "table" then
        for _ in pairs( tbl ) do 
            count = count + 1 
        end
    end

    return count
end

-- -----------------------------------------------------------------------------------
-- IG:RestorePlayerInventory (player)
-- -----------------------------------------------------------------------------------
-- Restore player inventory
-- -----------------------------------------------------------------------------------
function IG:RestoreInventory (player)       
        
    -- Clear player Inventory
    player.inventory:Strip()
    
    -- This fixes the incomplete restoration process
    timer.Once (1, function ()     
        -- Grab the player his/her SteamID.
        local playerID = rust.UserIDFromPlayer( player )
        -- Get Player inventory list
        local belt = player.inventory.containerBelt
        local main = player.inventory.containerMain
        local wear = player.inventory.containerWear
        local Inventory = {}
        
        -- Set inventory
        Inventory ['belt'] = belt
        Inventory ['main'] = main
        Inventory ['wear'] = wear
        
        -- Loop by player's saved inventory slots
        for slot, items in pairs( self.Data.GlobalInventory [playerID] ) do
            --Loop by slots
            for i, item in pairs( items ) do
    
              -- Create an inventory item
              local itemEntity = global.ItemManager.CreateByName(item.name, item.amount)
              
              -- Set that created inventory item to player
              player.inventory:GiveItem(itemEntity, Inventory [slot])
            end
         end
    end)
end

-- -----------------------------------------------------------------------------------
-- IG:RestorePlayerInventory ()
-- -----------------------------------------------------------------------------------
-- Restore player inventory
-- -----------------------------------------------------------------------------------
function IG:RestorePlayerInventory ( player )  
    -- Check if Inventory Guardian is enabled
    if self.ox.Config.Settings.Enabled then  
        -- Grab the player his/her SteamID.
        local playerID = rust.UserIDFromPlayer( player )
        
        -- Check if saved inventory is empty
        if self:SavedInventoryIsEmpty (playerID) then
            -- Send message
            self:SendMessage(player, self.ox.Config.Messages.RestoreEmpty)
        else          
          -- Restore Inventory
          self:RestoreInventory(player)
          
          -- Send message to user
          self:SendMessage(player, self.ox.Config.Messages.Restored)
        end
    end
end

-- -----------------------------------------------------------------------------
-- IG:SendMessage( target, message )
-- -----------------------------------------------------------------------------
-- Sends a chatmessage to a player.
-- -----------------------------------------------------------------------------
function IG:SendMessage ( player, message )
    -- Check if the message is a table with multiple messages.
    if type( message ) == "table" then
        -- Loop by table of messages and send them one by one
        for i, message in pairs( message ) do
           self:SendMessage( player, message )
        end
    else
        -- Check if we have an existing target to send the message to.
        if player ~= nil then
            -- Check if player is connected
            if player then
                -- Send the message to the targetted player.
                player:SendConsoleCommand( "chat.add", self.ox.Config.Settings.ChatPlayerIcon, self.ox.Config.Settings.ChatFormat:format(self.ox.Config.Settings.ChatName, message) )
            end
        else
            self:Log("[" .. self.ox.Config.Settings.ChatName .. "] "  .. message )
        end
    end
end

-- -----------------------------------------------------------------------------------
-- IG:RestoreUponDeath (player)
-- -----------------------------------------------------------------------------------
-- Toogle the config restore upon death
-- -----------------------------------------------------------------------------------
function IG:ToggleRestoreUponDeath (player)
    -- Check if Inventory Guardian is enabled
    if self.ox.Config.Settings.Enabled then  
        -- Check if Restore Upon Death is enabled
        if self.ox.Config.Settings.RestoreUponDeath then
            -- Disable Restore Upon Death
            self.ox.Config.Settings.RestoreUponDeath = false
            -- Send Message to Player
            self:SendMessage(player, self.ox.Config.Messages.RestoreUponDeathDisabled)
        else
            -- Enable Restore Upon Death
            self.ox.Config.Settings.RestoreUponDeath = true
            -- Send Message to Player
            self:SendMessage(player, self.ox.Config.Messages.RestoreUponDeathEnabled)
        end
        
        -- Save the config.
        self.ox:SaveConfig()
    end
end

-- -----------------------------------------------------------------------------------
-- IG:ToggleInventoryGuardian ( player )
-- -----------------------------------------------------------------------------------
-- Enable/Disable Inventory Guardian
-- -----------------------------------------------------------------------------------
function IG:ToggleInventoryGuardian ( player )
      -- Check if Inventory Guardian is enabled
      if self.ox.Config.Settings.Enabled then
          -- Disable Inventory Guardian
          self.ox.Config.Settings.Enabled = false
          -- Send Message to Player
          self:SendMessage(player, self.ox.Config.Messages.Disabled)
      else
          -- Enable Inventory Guardian
          self.ox.Config.Settings.Enabled = true
          -- Send Message to Player
          self:SendMessage(player, self.ox.Config.Messages.Enabled)
      end
      
      -- Save the config.
      self.ox:SaveConfig()
end


-- -----------------------------------------------------------------------------------
-- IG:ToggleAutoRestore ( player )
-- -----------------------------------------------------------------------------------
-- Enable/Disable Automatic restoration
-- -----------------------------------------------------------------------------------
function IG:ToggleAutoRestore ( player )
      -- Check if Inventory Guardian is enabled
      if self.ox.Config.Settings.AutoRestore then
          -- Disable Inventory Guardian's Auto restore
          self.ox.Config.Settings.AutoRestore = false
          -- Send Message to Player
          self:SendMessage(player, self.ox.Config.Messages.AutoRestoreDisabled)
      else
          -- Enable Inventory Guardian's Auto restore
          self.ox.Config.Settings.AutoRestore = true
          -- Send Message to Player
          self:SendMessage(player, self.ox.Config.Messages.AutoRestoreEnabled)
      end
      
      -- Save the config.
      self.ox:SaveConfig()
end

-- -----------------------------------------------------------------------------------
-- IG:ChangeAuthLevel ( player, authLevel )
-- -----------------------------------------------------------------------------------
-- Change Auth Level required to use Inventory Guardian
-- -----------------------------------------------------------------------------------
function IG:ChangeAuthLevel ( player, authLevel )
    -- Check if Inventory Guardian is enabled
    if self.ox.Config.Settings.Enabled then            
        -- Check for Admin
        if authLevel == "admin" or authLevel == "owner" or authLevel == "2" then
            -- Set required auth level to admin
            self.ox.Config.Settings.RequiredAuthLevel = 2
            -- Send message to player
            self:SendMessage(player, self.ox.Config.Messages.AuthLevelChanged:format("2"))
        -- Check for Mod
        elseif authLevel == "mod" or authLevel == "moderator" or authLevel == "1" then
            -- Set required auth level to moderator
            self.ox.Config.Settings.RequiredAuthLevel = 1
            -- Send message to player
            self:SendMessage(player, self.ox.Config.Messages.AuthLevelChanged:format("1"))
        else
            -- Send message to player
            self:SendMessage(player, self.ox.Config.Messages.InvalidAuthLevel)
        end           
        
        -- Save the config.
        self.ox:SaveConfig()
    end
end

-- -----------------------------------------------------------------------------------
-- IG:IsAllowed( player )
-- -----------------------------------------------------------------------------------
-- Checks if the player is allowed to run an admin (or moderator or user) only command.
-- -----------------------------------------------------------------------------------
function IG:IsAllowed( player )
    -- Grab the player his AuthLevel and set the required AuthLevel.
    local playerAuthLevel = player:GetComponent("BaseNetworkable").net.connection.authLevel

    -- Compare the AuthLevel with the required AuthLevel, if it's higher or equal
    -- then the user is allowed to run the command.
    if playerAuthLevel >= self.ox.Config.Settings.RequiredAuthLevel then
        return true
    end

    return false
end

-- -----------------------------------------------------------------------------------
-- IG:Check ( player )
-- -----------------------------------------------------------------------------------
-- Checks if the player is allowed to run and save Inventory
-- -----------------------------------------------------------------------------------
function IG:Check (player)
    -- Check if Inventory Guardian is enabled
    if not self.ox.Config.Settings.Enabled then        
        -- Send message to player
        self:SendMessage(player, self.ox.Config.Messages.CantDoDisabled)
        
        return false
    -- Check if player is allowed and Inventory Guardian is enabled
    elseif not self:IsAllowed( player ) then    
        -- Send message to player
        self:SendMessage(player, self.ox.Config.Messages.NotAllowed:format(tostring(self.ox.Config.Settings.RequiredAuthLevel)))
        
        return false
    else
        return true
    end
end

-- -----------------------------------------------------------------------------------
-- IG:RestoreAll ( )
-- -----------------------------------------------------------------------------------
-- Restore all players inventories
-- -----------------------------------------------------------------------------------
function IG:RestoreAll ()
    -- Send message
    self:LogWarning(self.ox.Config.Messages.RestoreInit)
    
    -- Get all players
    local players = UnityEngine.Object.FindObjectsOfTypeAll(global.BasePlayer._type)
    local player = nil
    local playerID = 0
    
    -- Loop by all players
    for i = 0, tonumber(players.Length - 1) do
        -- Get current player
        player = players[i]  
        
        -- Check if player is valid
        if player.displayName then
          -- Get PlayerID
          playerID = rust.UserIDFromPlayer(player)
          -- Check if player have a valid Player ID
            if playerID ~= "0" then
                -- Check if player have a saved inventory
                if not self:SavedInventoryIsEmpty(playerID) then
                    -- Restore Inventory
                    self:RestoreInventory(player)
                    -- Send message to player
                    self:SendMessage(nil, self.ox.Config.Messages.RestoredPlayerInventory:format(player.displayName))
                end
            end
        end
    end
    -- Send message
    self:LogWarning(self.ox.Config.Messages.RestoreAll)     
end

-- -----------------------------------------------------------------------------------
-- IG:SaveAll ( )
-- -----------------------------------------------------------------------------------
-- Save all players inventories
-- -----------------------------------------------------------------------------------
function IG:SaveAll ()
    -- Send message
    self:LogWarning(self.ox.Config.Messages.SaveInit)
    
    -- Get all players
    local players = UnityEngine.Object.FindObjectsOfTypeAll(global.BasePlayer._type)
    local player = nil
    local playerID = 0
    
    -- Loop by all players
    for i = 0, tonumber(players.Length - 1) do
        -- Get current player
        player = players[i]  
        
        -- Check if player is valid
        if player.displayName then
          -- Get PlayerID
          playerID = rust.UserIDFromPlayer(player)
          -- Check if player have a valid Player ID
            if playerID ~= "0" then
                -- Save Inventory
                self:SaveInventory(player)
                -- Send message to console
                self:Log(self.ox.Config.Messages.SavedPlayerInventory:format(player.displayName))
            end
        end
    end
       -- Send message
    self:LogWarning(self.ox.Config.Messages.SaveAll)     
end

-- -----------------------------------------------------------------------------------
-- IG:DeleteAll ( )
-- -----------------------------------------------------------------------------------
-- Delete all players inventories
-- -----------------------------------------------------------------------------------
function IG:DeleteAll ()
    -- Send message
    self:LogWarning(self.ox.Config.Messages.DeleteInit)
    
    -- Get all players
    local players = UnityEngine.Object.FindObjectsOfTypeAll(global.BasePlayer._type)
    local player = nil
    local playerID = 0
    
    -- Loop by all players
    for i = 0, tonumber(players.Length - 1) do
        -- Get current player
        player = players[i]  
        
        -- Check if player is valid
        if player.displayName then
          -- Get PlayerID
          playerID = rust.UserIDFromPlayer(player)
          -- Check if player have a valid Player ID
            if playerID ~= "0" then
                -- Delete player Inventory
                self:ClearSavedInventory(playerID)
                -- Send message to player
                self:SendMessage(nil, self.ox.Config.Messages.DeletedPlayerInventory:format(player.displayName))
            end
        end
    end
       -- Send message
    self:LogWarning(self.ox.Config.Messages.DeleteAll)     
end


-- -----------------------------------------------------------------------------
-- IG:FindPlayersByName( playerName )
-- -----------------------------------------------------------------------------
-- Searches the online players for a specific name.
-- -----------------------------------------------------------------------------
-- Credit: m-Teleportation
function IG:FindPlayersByName( playerName )
    -- Check if a player name was supplied.
    if not playerName then return end

    -- Set the player name to lowercase to be able to search case insensitive.
    playerName = string.lower( playerName )

    -- Setup some variables to save the matching BasePlayers with that partial
    -- name.
    local matches = {}
    local itPlayerList = global.BasePlayer.activePlayerList:GetEnumerator()
    
    -- Iterate through the online player list and check for a match.
    while itPlayerList:MoveNext() do
        -- Get the player his/her display name and set it to lowercase.
        local displayName = string.lower( itPlayerList.Current.displayName )
        
        -- Look for a match.
        if string.find( displayName, playerName, 1, true ) then
            -- Match found, add the player to the list.
            table.insert( matches, itPlayerList.Current )
        end
    end

    -- Return all the matching players.
    return matches
end

-- -----------------------------------------------------------------------------
-- IG:findPlayerByName( oPlayer, playerName )
-- -----------------------------------------------------------------------------
-- Searches the online players for a specific name.
-- -----------------------------------------------------------------------------
function IG:findPlayerByName (oPlayer, playerName)
    -- Get a list of matched players
    local players = self:FindPlayersByName(playerName)
    local player = nil
    
    -- Check if we found the targetted player.
    if self:Count(players) == 0 then
        -- The targetted player couldn't be found, send a message to the player.
        self:SendMessage( oPlayer, self.ox.Config.Messages.PlayerNotFound )
    
        return player
    end
    
    -- Check if we found multiple players with that partial name.
    if self:Count(players) > 1 then
        -- Multiple players were found, send a message to the player.
        self:SendMessage( oPlayer, self.ox.Config.Messages.MultiplePlayersFound )
    
        return player
    else
        -- Only one player was found, modify the targetPlayer variable value.
        player = players[1]
    end
    
    return player
end

-- -----------------------------------------------------------------------------------
-- IG:AutomaticRestoration ()
-- -----------------------------------------------------------------------------------
-- Detect and restore inventories
-- -----------------------------------------------------------------------------------
function IG:AutomaticRestoration () 
    -- Check if protocols are detected
    if self.ox.Config.Settings.AutoRestore then
        -- Check if the current Save Protocol is different then the last saved
        if self.SaveProtocol ~= self.Data.SaveProtocol and self.Data.SaveProtocol ~= 0 then
            -- Wipe Restore Once list
            self.Data.RestoreOnce = {}
            -- Send message to console
            self:LogWarning("[" .. self.ox.Config.Settings.ChatName .. "] "  .. self.ox.Config.Messages.AutoRestoreDetected)
        end
    end

    -- Set data save protocol
    self.Data.SaveProtocol = self.SaveProtocol
    -- Save SaveProtocol
    self.ox:SaveData()
end

-- -----------------------------------------------------------------------------------
-- IG:Log (message)
-- -----------------------------------------------------------------------------------
-- Log normal
-- -----------------------------------------------------------------------------------
-- Credit: HooksTest
-- -----------------------------------------------------------------------------------
function IG:Log(message)
    local arr = util.TableToArray({ message })
    UnityEngine.Debug.Log.methodarray[0]:Invoke(nil,arr)
end

-- -----------------------------------------------------------------------------------
-- IG:LogWarning (message)
-- -----------------------------------------------------------------------------------
-- Log Warning
-- -----------------------------------------------------------------------------------
-- Credit: HooksTest
-- -----------------------------------------------------------------------------------
function IG:LogWarning(message)
    local arr = util.TableToArray({ message })
    UnityEngine.Debug.LogWarning.methodarray[0]:Invoke(nil,arr)
end

-- -----------------------------------------------------------------------------------
-- IG:LogError (message)
-- -----------------------------------------------------------------------------------
-- Log Error
-- -----------------------------------------------------------------------------------
-- Credit: HooksTest
-- -----------------------------------------------------------------------------------
function IG:LogError(message)
    local arr = util.TableToArray({ message })
    UnityEngine.Debug.LogError.methodarray[0]:Invoke(nil,arr)
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:OnServerInitialized()
-- -----------------------------------------------------------------------------------
-- On server initialisation finished the required in-game chat commands are registered and data
-- from the DataTable file is loaded.
-- -----------------------------------------------------------------------------------
function PLUGIN:OnServerInitialized()        
    -- Add the current save protocol
    IG.SaveProtocol = Rust.Protocol.save
    
    -- Add chat commands
    command.AddChatCommand( "ig.save", self.Object, "cmdSaveInventory" )
    command.AddChatCommand( "ig.restore", self.Object, "cmdRestoreInventory" )
    command.AddChatCommand( "ig.restoreupondeath", self.Object, "cmdToggleRestoreUponDeath" )
    command.AddChatCommand( "ig.delsaved", self.Object, "cmdDeleteInventory" )
    command.AddChatCommand( "ig.toggle", self.Object, "cmdToggleInventoryGuardian" )
    command.AddChatCommand( "ig.autorestore", self.Object, "cmdToggleAutoRestore" )
    command.AddChatCommand( "ig.authlevel", self.Object, "cmdChangeAuthLevel" )
    command.AddChatCommand( "ig.strip", self.Object, "cmdStripInv" )
    
    -- Add console commands
    command.AddConsoleCommand( "ig.authlevel", self.Object, "ccmdChangeAuthLevel" )
    command.AddConsoleCommand( "ig.toggle", self.Object, "ccmdToggleInventoryGuardian" )
    command.AddConsoleCommand( "ig.restoreupondeath", self.Object, "ccmdToggleRestoreUponDeath" )
    command.AddConsoleCommand( "ig.autorestore", self.Object, "ccmdToggleAutoRestore" )
    command.AddConsoleCommand( "ig.restoreall", self.Object, "ccmdRestoreAll" )
    command.AddConsoleCommand( "ig.saveall", self.Object, "ccmdSaveAll" )
    command.AddConsoleCommand( "ig.deleteall", self.Object, "ccmdDeleteAll" )
    
    -- Load default saved data
    self:LoadSavedData()
    
    -- Update config version
    IG:UpdateConfig()
    
    -- Run automatic restoration
    IG:AutomaticRestoration()
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:LoadDefaultConfig()
-- -----------------------------------------------------------------------------------
-- The plugin uses a configuration file to save certain settings and uses it for
-- localized messages that are send in-game to the players. When this file doesn't
-- exist a new one will be created with these default values.
-- -----------------------------------------------------------------------------------
function PLUGIN:LoadDefaultConfig () 
    self.Config.Settings = IG.Settings
    self.Config.Messages = IG.Messages
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:OnPlayerDisconnected(player)
-- -----------------------------------------------------------------------------------
-- Run on Player Disconnect
-- -----------------------------------------------------------------------------------
function PLUGIN:OnPlayerDisconnected(player)
    -- Save player inventory
    IG:SavePlayerInventory(player)  
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:OnEntityDeath(entity)
-- -----------------------------------------------------------------------------------
-- When an entity dies
-- -----------------------------------------------------------------------------------
function PLUGIN:OnEntityDeath(entity)
    -- Convert entity to player
    local player = entity:ToPlayer()
    
    -- Check if entity is a player
    if player then
        -- Grab the player his/her SteamID.
        local playerID = rust.UserIDFromPlayer( player )
        
        -- Add playerID to player death list
        IG.PlayerDeaths[playerID] = true
        
        -- Check if the Restore upon death is enabled
        if self.Config.Settings.RestoreUponDeath then
            -- Save player inventory
            IG:SavePlayerInventory(player) 
        else    
          -- Reset saved inventory
          IG:ClearSavedInventory(playerID)
        end
    end 
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:OnPlayerSpawn(player)
-- -----------------------------------------------------------------------------------
-- When a player spawn
-- -----------------------------------------------------------------------------------
function PLUGIN:OnPlayerSpawn(player)
    -- Grab the player his/her SteamID.
    local playerID = rust.UserIDFromPlayer( player )    

    -- Check if saved inventory is empty
    if not IG:SavedInventoryIsEmpty (playerID) then
        -- Check if Once Restoration is enabled and if player never got once restored or if Once Restoration is disabled or if the Restore upon death is enabled and if player just died or If player never died = First spawn
        if IG.Data.RestoreOnce [playerID] == nil or (self.Config.Settings.RestoreUponDeath and IG.PlayerDeaths[playerID] == true) or IG.PlayerDeaths[playerID] == nil then
            -- Restore player inventory
            IG:RestorePlayerInventory ( player ) 
            -- Add Player ID to Once Restorated List
            IG.Data.RestoreOnce [playerID] = true
            -- Reset saved inventory
            timer.Once(3, function() IG:ClearSavedInventory(playerID) end)
        end 
    end
    
    -- Remove PlayerID from player deaths list
    IG.PlayerDeaths[playerID] = nil
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SendHelpText( player )
-- -----------------------------------------------------------------------------------
-- HelpText plugin support for the command /help.
-- -----------------------------------------------------------------------------------
function PLUGIN:SendHelpText(player)
    -- Check if user is admin
    if IG:IsAllowed( player ) then
        -- Send message to player
        IG:SendMessage(player, self.Config.Messages.Help)
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:cmdSaveInventory ( player, _, args )
-- -----------------------------------------------------------------------------------
-- Checks if the player is allowed to run and save Inventory
-- -----------------------------------------------------------------------------------
function PLUGIN:cmdSaveInventory ( player, _, args )
    -- Make a copy of the player what ran the command
    local oPlayer = player
    local tPlayer = nil
    
    -- Check if Inventory Guardian is enabled and If player is allowed
    if IG:Check( player ) then
        -- Check if any arg was passed
        if args.Length == 1 then
            -- Check if arg is not empty
            if args[0] ~= "" or args[0] ~= " " then
                -- Find a player by name
                tPlayer = IG:findPlayerByName( oPlayer, args[0] )
                
                -- Check if player is valid
                if tPlayer ~= nil then
                    -- Set player as the founded player
                    player = tPlayer  
                else                    
                    return nil
                end       
            end
         end
        
        -- Save Player Inventory
        IG:SavePlayerInventory (player)
        
         -- Check if oPlayer is the same then player
        if player ~= oPlayer then
            -- Send message to Oplayer
            IG:SendMessage(oPlayer, self.Config.Messages.SavedPlayerInventory:format(player.displayName))
        end
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:cmdRestoreInventory ( player, _, args )
-- -----------------------------------------------------------------------------------
-- Checks if the player is allowed to run and restore Inventory
-- -----------------------------------------------------------------------------------
function PLUGIN:cmdRestoreInventory ( player, _, args )
    -- Make a copy of the player what ran the command
    local oPlayer = player
    local tPlayer = nil
    
    -- Check if Inventory Guardian is enabled and If player is allowed
    if IG:Check( player ) then
        -- Check if any arg was passed
        if args.Length == 1 then
            -- Check if arg is not empty
            if args[0] ~= "" or args[0] ~= " " then
                -- Find a player by name
                tPlayer = IG:findPlayerByName( oPlayer, args[0] )
                
                -- Check if player is valid
                if tPlayer ~= nil then
                    -- Set player as the founded player
                    player = tPlayer  
                else
                    return nil
                end       
            end
        end
        
        -- Restore player Inventory
        IG:RestorePlayerInventory (player)
        
        -- Check if oPlayer is the same then player
        if player ~= oPlayer then
            -- Send message to oPlayer
            IG:SendMessage(oPlayer, self.Config.Messages.RestoredPlayerInventory:format(player.displayName))
        end
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:cmdDeleteInventory ( player, _, args )
-- -----------------------------------------------------------------------------------
-- Checks if the player is allowed to run and delete Inventory
-- -----------------------------------------------------------------------------------
function PLUGIN:cmdDeleteInventory ( player, _, args )
    -- Make a copy of the player what ran the command
    local oPlayer = player
    local tPlayer = nil
    
    -- Check if Inventory Guardian is enabled and If player is allowed
    if IG:Check( player ) then
        -- Check if any arg was passed
        if args.Length == 1 then
            -- Check if arg is not empty
            if args[0] ~= "" or args[0] ~= " " then
                -- Find a player by name
                tPlayer = IG:findPlayerByName( oPlayer, args[0] )
                
                -- Check if player is valid
                if tPlayer ~= nil then
                    -- Set player as the founded player
                    player = tPlayer  
                end       
            end
        end
        
        -- Restore player Inventory
        IG:DeletePlayerSavedInventory (player)
        
         -- Check if oPlayer is the same then player
        if player ~= oPlayer then
            -- Send message to oPlayer
            IG:SendMessage(oPlayer, self.Config.Messages.DeletedPlayerInventory:format(player.displayName))
        end
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:cmdToggleInventoryGuardian ( player )
-- -----------------------------------------------------------------------------------
-- Enable/Disable Inventory Guardian
-- -----------------------------------------------------------------------------------
function PLUGIN:cmdToggleInventoryGuardian ( player )
    -- Check if Inventory Guardian is enabled and If player is allowed
    if IG:IsAllowed( player ) then
        -- Restore Player inventory
        IG:ToggleInventoryGuardian (player)
    else
        -- Send message to player
        IG:SendMessage(player, self.Config.Messages.NotAllowed:format(tostring(self.Config.Settings.RequiredAuthLevel)))
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:cmdToggleRestoreOnce ( player )
-- -----------------------------------------------------------------------------------
-- Enable/Disable Automatic restoration
-- -----------------------------------------------------------------------------------
function PLUGIN:cmdToggleAutoRestore ( player )
    -- Check if Inventory Guardian is enabled and If player is allowed
    if IG:Check( player ) then
        -- Toggle Automatic Restoration
        IG:ToggleAutoRestore (player)
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:cmdChangeAuthLevel ( player, _, args )
-- -----------------------------------------------------------------------------------
-- Change required Auth Level
-- -----------------------------------------------------------------------------------
function PLUGIN:cmdChangeAuthLevel( player, _, args )
    -- Check if Inventory Guardian is enabled
    if IG:Check( player ) then
        -- Check for passed args
        if args.Length == 1 then
            -- Change required Auth level
            IG:ChangeAuthLevel(player, args[0])
        end
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:cmdToggleRestoreUponDeath ( player )
-- -----------------------------------------------------------------------------------
-- Enable/Disable Restoration upon death
-- -----------------------------------------------------------------------------------
function PLUGIN:cmdToggleRestoreUponDeath ( player )
    -- Check if Inventory Guardian is enabled
    if IG:Check( player ) then
        -- Toggle restore upon death
        IG:ToggleRestoreUponDeath (player)
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
        IG:ChangeAuthLevel(nil, arg.Args[0])
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ccmdToggleInventoryGuardian ()
-- -----------------------------------------------------------------------------------
-- Enable/Disable Inventory Guardian
-- -----------------------------------------------------------------------------------
function PLUGIN:ccmdToggleInventoryGuardian ()
    -- Restore Player inventory
    IG:ToggleInventoryGuardian (nil)
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ccmdToggleRestoreOnce ()
-- -----------------------------------------------------------------------------------
-- Enable/Disable Automatic restoration
-- -----------------------------------------------------------------------------------
function PLUGIN:ccmdToggleAutoRestore ()
    -- Toggle automatic restoration
    IG:ToggleAutoRestore (nil)
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ccmdToggleRestoreUponDeath ()
-- -----------------------------------------------------------------------------------
-- Enable/Disable Restoration upon death
-- -----------------------------------------------------------------------------------
function PLUGIN:ccmdToggleRestoreUponDeath ()
    -- Toggle restore upon death
    IG:ToggleRestoreUponDeath (nil)
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ccmdRestoreAll ()
-- -----------------------------------------------------------------------------------
-- Restore All players inventories
-- -----------------------------------------------------------------------------------
function PLUGIN:ccmdRestoreAll ()
    -- Restore all players inventories
    IG:RestoreAll ()
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ccmdSaveAll ()
-- -----------------------------------------------------------------------------------
-- Save All players inventories
-- -----------------------------------------------------------------------------------
function PLUGIN:ccmdSaveAll ()
    -- Save all players inventories
    IG:SaveAll ()
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ccmdDeleteAll ()
-- -----------------------------------------------------------------------------------
-- Delete All players inventories
-- -----------------------------------------------------------------------------------
function PLUGIN:ccmdDeleteAll ()
    -- Save all players inventories
    IG:DeleteAll ()
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:AutomaticRestoration ()
-- -----------------------------------------------------------------------------------
-- Strip player inventory
-- ----------------------------------------------------------------------------------
function PLUGIN:cmdStripInv (player, _, args)
    -- Copy origin player
    local oPlayer = player
    local tPlayer = nil
    
    -- Check if arg is not empty
    if args[0] ~= "" or args[0] ~= " " then
        -- Find a player by name
        tPlayer = IG:findPlayerByName( oPlayer, args[0] )
        
        -- Check if player is valid
        if tPlayer ~= nil then
            -- Set player as the founded player
            player = tPlayer  
        else                    
            return nil
        end       
    end

    -- Check if player is valid
    if player ~= nil then
        -- Clear player Inventory
        player.inventory:Strip()
    end
    
    -- Check if player is not oPlayer
    if player ~= oPlayer then
        -- Send message to target player
        IG:SendMessage(tPlayer, self.Config.Messages.PlayerStriped:format(oPlayer.displayName))
        -- Send message back to oPlayer
        IG:SendMessage(oPlayer, self.Config.Messages.PlayerStripedBack:format(player.displayName))  
    else
        -- Send message to oPlayer
        IG:SendMessage(oPlayer, self.Config.Messages.SelfStriped)       
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SaveData
-- -----------------------------------------------------------------------------------
-- Saves the table with all the warpdata to a DataTable file.
-- -----------------------------------------------------------------------------------
function PLUGIN:SaveData ()  
    -- Save the DataTable
    datafile.SaveDataTable( "Inventory-Guardian" )
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:LoadSavedData()
-- -----------------------------------------------------------------------------------
-- Load the DataTable file into a table or create a new table when the file doesn't
-- exist yet.
-- -----------------------------------------------------------------------------------
function PLUGIN:LoadSavedData ()
    IG.Data = datafile.GetDataTable( "Inventory-Guardian" )
    IG.Data = IG.Data or {}
    IG.Data.GlobalInventory = IG.Data.GlobalInventory or {}  
    IG.Data.RestoreOnce = IG.Data.RestoreOnce or {}  
    IG.Data.SaveProtocol = IG.Data.SaveProtocol or IG.SaveProtocol   
end