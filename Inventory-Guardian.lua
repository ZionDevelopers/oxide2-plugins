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
 Version 0.0.8 by Nexus on 01-18-2015 12:14 PM (GTM -03:00)
]]--

PLUGIN.Name = "Inventory-Guardian"
PLUGIN.Title = "Inventory Guardian"
PLUGIN.Description = "Keep players inventory after server wipes"
PLUGIN.Version = V(0, 0, 8)
PLUGIN.Author = "Nexus"
PLUGIN.HasConfig = true
PLUGIN.ResourceId = 773

-- Define Inventory Guardian class
local IG = {}
local ox = nil

-- Define Inventory Data
IG.Data = {}

-- Define Player deaths table
IG.PlayerDeaths = {}
IG.SaveProtocol = 0

-- Define Config version
IG.ConfigVersion = "0.0.3"

-- Define Local config Tables/Strings/Info 
IG.Settings = {
    ChatName = "Inventory Guardian",
    Enabled = true,
    RequiredAuthLevel = 2,
    ConfigVersion = "0.0.3",
    RestoreUponDeath = false,
    AutoRestore = true
}    
   
-- Plugin Messages:
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
      "/ig.authlevel <n/s> - Change Inventory Guardian required Auth Level."
    }   
}

-- -----------------------------------------------------------------------------------
-- IG.UpdateConfig()
-- -----------------------------------------------------------------------------------
-- It check if the config version is outdated
-- -----------------------------------------------------------------------------------
IG.UpdateConfig = function ()
    -- Check if the current config version differs from the saved
    if ox.Config.Settings.ConfigVersion ~= IG.ConfigVersion then
        -- Load the default
        ox:LoadDefaultConfig()
        -- Save config
        ox:SaveConfig()
    end
end


-- -----------------------------------------------------------------------------------
-- IG.SaveData
-- -----------------------------------------------------------------------------------
-- Saves the table with all the warpdata to a DataTable file.
-- -----------------------------------------------------------------------------------
IG.SaveData = function ()  
    -- Save the DataTable
    datafile.SaveDataTable( "Inventory-Guardian" )
end

-- -----------------------------------------------------------------------------------
-- IG.ClearSavedInventory(playerID)
-- -----------------------------------------------------------------------------------
-- Clear player's saved inventory on Data Table
-- -----------------------------------------------------------------------------------
IG.ClearSavedInventory = function (playerID)
    -- Reset inventory
    IG.Data.GlobalInventory [playerID] = {} 
    IG.Data.GlobalInventory [playerID]['belt'] = {}
    IG.Data.GlobalInventory [playerID]['main'] = {}
    IG.Data.GlobalInventory [playerID]['wear'] = {}
    -- Save Inventory
    IG.SaveData()
end

-- -----------------------------------------------------------------------------------
-- IG.DeletePlayerSavedInventory(player)
-- -----------------------------------------------------------------------------------
-- Clear player's saved inventory
-- -----------------------------------------------------------------------------------
IG.DeletePlayerSavedInventory = function (player)
    -- Check if Inventory Guardian is enabled
    if ox.Config.Settings.Enabled then
        -- Grab the player his/her SteamID.
        local playerID = rust.UserIDFromPlayer( player )  
        -- Clear Saved inventory
        IG.ClearSavedInventory(playerID)
        -- Send message to user
        IG.SendMessage(player, ox.Config.Messages.DeletedInv)  
    end    
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SavePlayerInventory (player)
-- -----------------------------------------------------------------------------------
-- Save player inventory
-- -----------------------------------------------------------------------------------
IG.SaveInventory = function (player)
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
    IG.ClearSavedInventory(playerID)
    
    -- Loop by the Belt Items
    while beltItems:MoveNext() do
      -- Save current item to player's inventory table
      IG.Data.GlobalInventory [playerID] ['belt'] [tostring(beltCount)] = {name = tostring(beltItems.Current.info.shortname), amount = beltItems.Current.amount}    
      -- Increment the count
      beltCount = beltCount + 1
    end
    
    -- Loop by the Main Items
    while mainItems:MoveNext() do
        -- Save current item to player's inventory table
        IG.Data.GlobalInventory [playerID] ['main'] [tostring(mainCount)] = {name = tostring(mainItems.Current.info.shortname), amount = mainItems.Current.amount}
        -- Increment the count
        mainCount = mainCount + 1
    end
    
    -- Loop by the Wear Items
    while wearItems:MoveNext() do
        -- Save current item to player's inventory table
        IG.Data.GlobalInventory [playerID] ['wear'] [tostring(wearCount)] = {name = tostring(wearItems.Current.info.shortname), amount = wearItems.Current.amount}    
        -- Increment the count
        wearCount = wearCount + 1
    end
    
    -- Save inventory data
    IG.SaveData()
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SavePlayerInventory (player)
-- -----------------------------------------------------------------------------------
-- Save player inventory and send message
-- -----------------------------------------------------------------------------------
IG.SavePlayerInventory = function (player)  
    -- Check if Inventory Guardian is enabled
    if ox.Config.Settings.Enabled then 
        -- Save player inventory
        IG.SaveInventory(player) 
        -- Send message to user
        IG.SendMessage(player, ox.Config.Messages.Saved)
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SavedInventoryIsEmpty ( playerID )
-- -----------------------------------------------------------------------------------
-- Check if player's saved inventory is empty
-- -----------------------------------------------------------------------------------
IG.SavedInventoryIsEmpty = function (playerID)
    if IG.Data.GlobalInventory [playerID] == nil then
        return true
    else
        return #IG.Data.GlobalInventory [playerID] ['belt'] == 0 and #IG.Data.GlobalInventory [playerID] ['main'] == 0 and #IG.Data.GlobalInventory [playerID] ['wear'] == 0
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:RestorePlayerInventory (player)
-- -----------------------------------------------------------------------------------
-- Restore player inventory
-- -----------------------------------------------------------------------------------
IG.RestoreInventory = function (player)       
        
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
        for slot, items in pairs( IG.Data.GlobalInventory [playerID] ) do
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
-- PLUGIN:RestorePlayerInventory ()
-- -----------------------------------------------------------------------------------
-- Restore player inventory
-- -----------------------------------------------------------------------------------
IG.RestorePlayerInventory = function ( player )  
    -- Check if Inventory Guardian is enabled
    if ox.Config.Settings.Enabled then  
        -- Grab the player his/her SteamID.
        local playerID = rust.UserIDFromPlayer( player )
        
        -- Check if saved inventory is empty
        if IG.SavedInventoryIsEmpty (playerID) then
            -- Send message
            IG.SendMessage(player, ox.Config.Messages.RestoreEmpty)
        else
          
          -- Restore Inventory
          IG.RestoreInventory(player)
          -- Send message to user
          IG.SendMessage(player, ox.Config.Messages.Restored)
        end
    end
end

-- -----------------------------------------------------------------------------
-- PLUGIN:SendMessage( target, message )
-- -----------------------------------------------------------------------------
-- Sends a chatmessage to a player.
-- -----------------------------------------------------------------------------
IG.SendMessage = function ( player, message )
    -- Check if the message is a table with multiple messages.
    if type( message ) == "table" then
        -- Loop by table of messages and send them one by one
        for i, message in pairs( message ) do
            IG.SendMessage( player, message )
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
-- PLUGIN:RestoreUponDeath (player)
-- -----------------------------------------------------------------------------------
-- Toogle the config restore upon death
-- -----------------------------------------------------------------------------------
function PLUGIN:ToggleRestoreUponDeath (player)
    -- Check if Inventory Guardian is enabled
    if self.Config.Settings.Enabled then  
        -- Check if Restore Upon Death is enabled
        if self.Config.Settings.RestoreUponDeath then
            -- Disable Restore Upon Death
            self.Config.Settings.RestoreUponDeath = false
            -- Send Message to Player
            self:SendMessage(player, self.Config.Messages.RestoreUponDeathDisabled)
        else
            -- Enable Restore Upon Death
            self.Config.Settings.RestoreUponDeath = true
            -- Send Message to Player
            self:SendMessage(player, self.Config.Messages.RestoreUponDeathEnabled)
        end
        
        -- Save the config.
        self:SaveConfig()
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ToggleInventoryGuardian ( player )
-- -----------------------------------------------------------------------------------
-- Enable/Disable Inventory Guardian
-- -----------------------------------------------------------------------------------
function PLUGIN:ToggleInventoryGuardian ( player )
      -- Check if Inventory Guardian is enabled
      if self.Config.Settings.Enabled then
          -- Disable Inventory Guardian
          self.Config.Settings.Enabled = false
          -- Send Message to Player
          self:SendMessage(player, self.Config.Messages.Disabled)
      else
          -- Enable Inventory Guardian
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
-- Change Auth Level required to use Inventory Guardian
-- -----------------------------------------------------------------------------------
function PLUGIN:ChangeAuthLevel ( player, authLevel )
    -- Check if Inventory Guardian is enabled
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
        else
            -- Send message to player
            self:SendMessage(player, self.Config.Messages.InvalidAuthLevel)
        end           
        
        -- Save the config.
        self:SaveConfig()
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SendHelpText( player )
-- -----------------------------------------------------------------------------------
-- HelpText plugin support for the command /help.
-- -----------------------------------------------------------------------------------
function PLUGIN:SendHelpText(player)
    -- Check if user is admin
    if self:IsAllowed( player ) then
        -- Send message to player
        self:SendMessage(player, self.Config.Messages.Help)
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
-- PLUGIN:Check ( player )
-- -----------------------------------------------------------------------------------
-- Checks if the player is allowed to run and save Inventory
-- -----------------------------------------------------------------------------------
function PLUGIN:Check (player)
    -- Check if Inventory Guardian is enabled
    if not self.Config.Settings.Enabled then        
        -- Send message to player
        self:SendMessage(player, self.Config.Messages.CantDoDisabled)
        
        return false
    -- Check if player is allowed and Inventory Guardian is enabled
    elseif not self:IsAllowed( player ) then    
        -- Send message to player
        self:SendMessage(player, self:Parse(self.Config.Messages.NotAllowed, {required = tostring(self.Config.Settings.RequiredAuthLevel)}))
        
        return false
    else
        return true
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:RestoreAll ( )
-- -----------------------------------------------------------------------------------
-- Restore all players inventories
-- -----------------------------------------------------------------------------------
function PLUGIN:RestoreAll ()
    -- Send message
    self:SendMessage(nil, self.Config.Messages.RestoreInit)
    
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
                    self:SendMessage(nil, self:Parse(self.Config.Messages.RestoredPlayerInventory, {player = player.displayName}))
                end
            end
        end
    end
       -- Send message
    self:SendMessage(nil, self.Config.Messages.RestoreAll)     
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SaveAll ( )
-- -----------------------------------------------------------------------------------
-- Save all players inventories
-- -----------------------------------------------------------------------------------
function PLUGIN:SaveAll ()
    -- Send message
    self:SendMessage(nil, self.Config.Messages.SaveInit)
    
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
                -- Send message to player
                self:SendMessage(nil, self:Parse(self.Config.Messages.SavedPlayerInventory, {player = player.displayName}))
            end
        end
    end
       -- Send message
    self:SendMessage(nil, self.Config.Messages.SaveAll)     
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:DeleteAll ( )
-- -----------------------------------------------------------------------------------
-- Delete all players inventories
-- -----------------------------------------------------------------------------------
function PLUGIN:DeleteAll ()
    -- Send message
    self:SendMessage(nil, self.Config.Messages.DeleteInit)
    
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
                self:SendMessage(nil, self:Parse(self.Config.Messages.DeletedPlayerInventory, {player = player.displayName}))
            end
        end
    end
       -- Send message
    self:SendMessage(nil, self.Config.Messages.DeleteAll)     
end


-- -----------------------------------------------------------------------------
-- PLUGIN:FindPlayersByName( playerName )
-- -----------------------------------------------------------------------------
-- Searches the online players for a specific name.
-- -----------------------------------------------------------------------------
-- Credit: m-Teleportation
function PLUGIN:FindPlayersByName( playerName )
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
-- PLUGIN:FindPlayerByName( oPlayer, playerName )
-- -----------------------------------------------------------------------------
-- Searches the online players for a specific name.
-- -----------------------------------------------------------------------------
function PLUGIN:FindPlayerByName (oPlayer, playerName)
    -- Get a list of matched players
    local players = self:FindPlayersByName(playerName)
    local player = nil
    
    -- Check if we found the targetted player.
    if #players == 0 then
        -- The targetted player couldn't be found, send a message to the player.
        self:SendMessage( oPlayer, self.Config.Messages.PlayerNotFound )
    
        return player
    end
    
    -- Check if we found multiple players with that partial name.
    if #players > 1 then
        -- Multiple players were found, send a message to the player.
        self:SendMessage( oPlayer, self.Config.Messages.MultiplePlayersFound )
    
        return player
    else
        -- Only one player was found, modify the targetPlayer variable value.
        player = players[1]
    end
    
    return player
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
    if self:Check( player ) then
        -- Check if any arg was passed
        if args.Length == 1 then
            -- Check if arg is not empty
            if args[0] ~= "" or args[0] ~= " " then
                -- Find a player by name
                tPlayer = self:FindPlayerByName( oPlayer, args[0] )
                
                -- Check if player is valid
                if tPlayer ~= nil then
                    -- Set player as the founded player
                    player = tPlayer  
                end       
            end
         end
        
        -- Save Player Inventory
        self:SavePlayerInventory (player)
        
         -- Check if oPlayer is the same then player
        if player ~= oPlayer then
            -- Send message to Oplayer
            self:SendMessage(oPlayer, self:Parse(self.Config.Messages.SavedPlayerInventory, {player = player.displayName}))
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
    if self:Check( player ) then
        -- Check if any arg was passed
        if args.Length == 1 then
            -- Check if arg is not empty
            if args[0] ~= "" or args[0] ~= " " then
                -- Find a player by name
                tPlayer = self:FindPlayerByName( oPlayer, args[0] )
                
                -- Check if player is valid
                if tPlayer ~= nil then
                    -- Set player as the founded player
                    player = tPlayer  
                end       
            end
        end
        
        -- Restore player Inventory
        self:RestorePlayerInventory (player)
        
        -- Check if oPlayer is the same then player
        if player ~= oPlayer then
            -- Send message to oPlayer
            self:SendMessage(oPlayer, self:Parse(self.Config.Messages.RestoredPlayerInventory, {player = player.displayName}))
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
    if self:Check( player ) then
        -- Check if any arg was passed
        if args.Length == 1 then
            -- Check if arg is not empty
            if args[0] ~= "" or args[0] ~= " " then
                -- Find a player by name
                tPlayer = self:FindPlayerByName( oPlayer, args[0] )
                
                -- Check if player is valid
                if tPlayer ~= nil then
                    -- Set player as the founded player
                    player = tPlayer  
                end       
            end
        end
        
        -- Restore player Inventory
        self:DeletePlayerSavedInventory (player)
        
         -- Check if oPlayer is the same then player
        if player ~= oPlayer then
            -- Send message to oPlayer
            self:SendMessage(oPlayer, self:Parse(self.Config.Messages.DeletedPlayerInventory, {player = player.displayName}))
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
    if self:IsAllowed( player ) then
        -- Restore Player inventory
        self:ToggleInventoryGuardian (player)
    else
        -- Send message to player
        self:SendMessage(player, self:Parse(self.Config.Messages.NotAllowed, {required = tostring(self.Config.Settings.RequiredAuthLevel)}))
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:cmdToggleRestoreOnce ( player )
-- -----------------------------------------------------------------------------------
-- Enable/Disable Automatic restoration
-- -----------------------------------------------------------------------------------
function PLUGIN:cmdToggleAutoRestore ( player )
    -- Check if Inventory Guardian is enabled and If player is allowed
    if self:Check( player ) then
        -- Toggle Automatic Restoration
        self:ToggleAutoRestore (player)
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:cmdChangeAuthLevel ( player, _, args )
-- -----------------------------------------------------------------------------------
-- Change required Auth Level
-- -----------------------------------------------------------------------------------
function PLUGIN:cmdChangeAuthLevel( player, _, args )
    -- Check if Inventory Guardian is enabled
    if self:Check( player ) then
        -- Check for passed args
        if args.Length == 1 then
            -- Change required Auth level
            self:ChangeAuthLevel(player, args[0])
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
    if self:Check( player ) then
        -- Toggle restore upon death
        self:ToggleRestoreUponDeath (player)
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
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ccmdToggleInventoryGuardian ()
-- -----------------------------------------------------------------------------------
-- Enable/Disable Inventory Guardian
-- -----------------------------------------------------------------------------------
function PLUGIN:ccmdToggleInventoryGuardian ()
    -- Restore Player inventory
    self:ToggleInventoryGuardian (nil)
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ccmdToggleRestoreOnce ()
-- -----------------------------------------------------------------------------------
-- Enable/Disable Automatic restoration
-- -----------------------------------------------------------------------------------
function PLUGIN:ccmdToggleAutoRestore ()
    -- Toggle automatic restoration
    self:ToggleAutoRestore (nil)
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ccmdToggleRestoreUponDeath ()
-- -----------------------------------------------------------------------------------
-- Enable/Disable Restoration upon death
-- -----------------------------------------------------------------------------------
function PLUGIN:ccmdToggleRestoreUponDeath ()
    -- Toggle restore upon death
    self:ToggleRestoreUponDeath (nil)
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ccmdRestoreAll ()
-- -----------------------------------------------------------------------------------
-- Restore All players inventories
-- -----------------------------------------------------------------------------------
function PLUGIN:ccmdRestoreAll ()
    -- Restore all players inventories
    self:RestoreAll ()
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ccmdSaveAll ()
-- -----------------------------------------------------------------------------------
-- Save All players inventories
-- -----------------------------------------------------------------------------------
function PLUGIN:ccmdSaveAll ()
    -- Save all players inventories
    self:SaveAll ()
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ccmdDeleteAll ()
-- -----------------------------------------------------------------------------------
-- Delete All players inventories
-- -----------------------------------------------------------------------------------
function PLUGIN:ccmdDeleteAll ()
    -- Save all players inventories
    self:DeleteAll ()
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:AutomaticRestoration ()
-- -----------------------------------------------------------------------------------
-- Detect and restore inventories
-- -----------------------------------------------------------------------------------
function PLUGIN:AutomaticRestoration () 
    if SaveProtocol ~= IG.Data.SaveProtocol then
        IG.Data.RestoreOnce = {}
        self:SaveData()
    end
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:Init()
-- -----------------------------------------------------------------------------------
-- On plugin initialisation the required in-game chat commands are registered and data
-- from the DataTable file is loaded.
-- -----------------------------------------------------------------------------------
function PLUGIN:Init ()
    -- Add chat commands
    command.AddChatCommand( "ig.save", IG.Object, "cmdSaveInventory" )
    command.AddChatCommand( "ig.restore", IG.Object, "cmdRestoreInventory" )
    command.AddChatCommand( "ig.restoreupondeath", IG.Object, "cmdToggleRestoreUponDeath" )
    command.AddChatCommand( "ig.delsaved", IG.Object, "cmdDeleteInventory" )
    command.AddChatCommand( "ig.toggle", IG.Object, "cmdToggleInventoryGuardian" )
    command.AddChatCommand( "ig.autorestore", IG.Object, "cmdToggleAutoRestore" )
    command.AddChatCommand( "ig.authlevel", IG.Object, "cmdChangeAuthLevel" )
    -- Add console commands
    command.AddConsoleCommand( "ig.authlevel", IG.Object, "ccmdChangeAuthLevel" )
    command.AddConsoleCommand( "ig.toggle", IG.Object, "ccmdToggleInventoryGuardian" )
    command.AddConsoleCommand( "ig.restoreupondeath", IG.Object, "ccmdToggleRestoreUponDeath" )
    command.AddConsoleCommand( "ig.autorestore", IG.Object, "ccmdToggleAutoRestore" )
    command.AddConsoleCommand( "ig.restoreall", IG.Object, "ccmdRestoreAll" )
    command.AddConsoleCommand( "ig.saveall", IG.Object, "ccmdSaveAll" )
    command.AddConsoleCommand( "ig.deleteall", IG.Object, "ccmdDeleteAll" )
    -- Load default saved data
    IG.LoadSavedData()
    -- Copy self to ox
    ox = self.Object
    -- Update config version
    IG.UpdateConfig()
    -- Add the current save protocol
    IG.SaveProtocol = Rust.Protocol.save

end

-- -----------------------------------------------------------------------------------
-- PLUGIN:Init()
-- -----------------------------------------------------------------------------------
-- On plugin initialisation the required in-game chat commands are registered and data
-- from the DataTable file is loaded.
-- -----------------------------------------------------------------------------------
function PLUGIN:OnServerInitialize()
    -- Run automatic restoration
    IG.AutomaticRestoration()
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


-- -----------------------------------------------------------------------------------
-- PLUGIN:OnPlayerDisconnected(player)
-- -----------------------------------------------------------------------------------
-- Run on Player Disconnect
-- -----------------------------------------------------------------------------------
function PLUGIN:OnPlayerDisconnected(player)
    -- Save player inventory
    self:SavePlayerInventory(player)  
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
        PlayerDeaths[playerID] = true
        -- Check if the Restore upon death is enabled
        if self.Config.Settings.RestoreUponDeath then
            -- Save player inventory
            self:SavePlayerInventory(player) 
        else    
          -- Reset saved inventory
          self:ClearSavedInventory(playerID)
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
    
    -- Check if the Restore upon death is enabled and if player just died or If player never died = First spawn
    if (self.Config.Settings.RestoreUponDeath and PlayerDeaths[playerID] == true) or PlayerDeaths[playerID] == nil then
        -- Check if saved inventory is empty
        if not self:SavedInventoryIsEmpty (playerID) then
            -- Restore player inventory
            self:RestorePlayerInventory ( player )  
        end
    end
    
    -- Remove PlayerID from player deaths list
    PlayerDeaths[playerID] = nil
end