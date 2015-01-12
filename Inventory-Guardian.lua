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
 Version 0.0.3 by Nexus on 01-12-2015 07:10 PM (GTM -03:00)
]]--

PLUGIN.Name = "Inventory-Guardian"
PLUGIN.Title = "Inventory Guardian"
PLUGIN.Description = "Keep players inventory after server wipes"
PLUGIN.Version = V(0, 0, 3)
PLUGIN.Author = "Nexus"
PLUGIN.HasConfig = true
PLUGIN.ResourceId = 773

-- Define Inventory Data
local InventoryData = {}

-- Define Player deaths
local PlayerDeaths = {}

-- -----------------------------------------------------------------------------------
-- PLUGIN:Init()
-- -----------------------------------------------------------------------------------
-- On plugin initialisation the required in-game chat commands are registered and data
-- from the DataTable file is loaded.
-- -----------------------------------------------------------------------------------
function PLUGIN:Init ()
    -- Add chat commands
    command.AddChatCommand( "saveinv", self.Object, "SavePlayerInventory" )
    command.AddChatCommand( "restoreinv", self.Object, "RestorePlayerInventory" )
    command.AddChatCommand( "restoreupondeath", self.Object, "RestoreUponDeath" )
    command.AddChatCommand( "delsavedinv", self.Object, "DeleteSavedInventory" )
    -- Load default saved data
    self:LoadSavedData()
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
        ChatName = "Inventory Guardian",
        ConfigVersion = "0.0.0",
        RestoreUponDeath = false
    }
   
    -- Plugin Messages:
    self.Config.Messages = {
        Saved = "Your inventory was been saved!",
        Restored = "Your inventory has been restored!",
        RestoreUponDeathEnabled = "Restore Upon Death Enabled!",
        RestoreUponDeathDisabled = "Restore Upon Death Disabled!",
        RestoreEmpty = "You don't have any saved inventory, so cannot be restored!",
        DeletedInv = 'Your saved inventory was deleted!',
        
        HelpUser = {
            "/saveinv - Save your inventory for later restoration!",
            "/restoreinv - Restore your saved inventory!",
            "/delsavedinv - Delete your saved inventory!"            
        },
        HelpAdmin = {            
            "/saveinv - Save your inventory for later restoration!",
            "/restoreinv - Restore your saved inventory!",
            "/restoreupondeath - Toggles the Inventory restoration upon death for all players on the server!",
            "/delsavedinv - Delete your saved inventory!"
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
    InventoryData = datafile.GetDataTable( "Inventory-Guardian" )
    InventoryData = InventoryData or {}
    InventoryData.GlobalInventory =  InventoryData.GlobalInventory or {}      
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SaveData()
-- -----------------------------------------------------------------------------------
-- Saves the table with all the warpdata to a DataTable file.
-- -----------------------------------------------------------------------------------
function PLUGIN:SaveData()  
    -- Save the DataTable
    datafile.SaveDataTable( "Inventory-Guardian" )
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ClearSavedInventory(playerID)
-- -----------------------------------------------------------------------------------
-- Clear player's saved inventory on Data Table
-- -----------------------------------------------------------------------------------
function PLUGIN:ClearSavedInventory(playerID)
    -- Reset inventory
    InventoryData.GlobalInventory [playerID] = {} 
    InventoryData.GlobalInventory [playerID]['belt'] = {}
    InventoryData.GlobalInventory [playerID]['main'] = {}
    InventoryData.GlobalInventory [playerID]['wear'] = {}
    -- Save Inventory
    self:SaveData()
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:ClearSavedInventory(player
-- -----------------------------------------------------------------------------------
-- Clear player's saved inventory
-- -----------------------------------------------------------------------------------
function PLUGIN:DeleteSavedInventory(player)
    -- Grab the player his/her SteamID.
    local playerID = rust.UserIDFromPlayer( player )  
    -- Clear Saved inventory
    self:ClearSavedInventory(playerID)
    -- Send message to user
    self:SendMessage(player, self.Config.Messages.DeletedInv)      
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SavePlayerInventory ()
-- -----------------------------------------------------------------------------------
-- Save player inventory
-- -----------------------------------------------------------------------------------
function PLUGIN:SavePlayerInventory (player)   
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
      InventoryData.GlobalInventory [playerID] ['belt'] [tostring(beltCount)] = {name = tostring(beltItems.Current.info.shortname), amount = beltItems.Current.amount}    
      -- Increment the count
      beltCount = beltCount + 1
    end
    
    -- Loop by the Main Items
    while mainItems:MoveNext() do
        -- Save current item to player's inventory table
        InventoryData.GlobalInventory [playerID] ['main'] [tostring(mainCount)] = {name = tostring(mainItems.Current.info.shortname), amount = mainItems.Current.amount}
        -- Increment the count
        mainCount = mainCount + 1
    end
    
    -- Loop by the Wear Items
    while wearItems:MoveNext() do
        -- Save current item to player's inventory table
        InventoryData.GlobalInventory [playerID] ['wear'] [tostring(wearCount)] = {name = tostring(wearItems.Current.info.shortname), amount = wearItems.Current.amount}    
        -- Increment the count
        wearCount = wearCount + 1
    end
    
    -- Save inventory data
    self:SaveData()
    
    -- Send message to user
    self:SendMessage(player, self.Config.Messages.Saved)
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:SavedInventoryIsEmpty ( playerID )
-- -----------------------------------------------------------------------------------
-- Check if player's saved inventory is empty
-- -----------------------------------------------------------------------------------
function PLUGIN:SavedInventoryIsEmpty (playerID)
    return self:Count(InventoryData.GlobalInventory [playerID] ['belt']) == 0 and self:Count(InventoryData.GlobalInventory [playerID] ['main']) == 0 and self:Count(InventoryData.GlobalInventory [playerID] ['wear']) == 0
end

-- -----------------------------------------------------------------------------------
-- PLUGIN:RestorePlayerInventory ()
-- -----------------------------------------------------------------------------------
-- Restore player inventory
-- -----------------------------------------------------------------------------------
function PLUGIN:RestorePlayerInventory ( player )    
    -- Grab the player his/her SteamID.
    local playerID = rust.UserIDFromPlayer( player )
    
    -- Check if saved inventory is empty
    if self:SavedInventoryIsEmpty (playerID) then
        -- Send message
        self:SendMessage(player, self.Config.Messages.RestoreEmpty)
    else
      -- Get Player inventory list
      local belt = player.inventory.containerBelt
      local main = player.inventory.containerMain
      local wear = player.inventory.containerWear
      local Inventory = {}
      
      -- Set inventory
      Inventory ['belt'] = belt
      Inventory ['main'] = main
      Inventory ['wear'] = wear
      
      -- Clear player Inventory
      player.inventory:Strip()
      
      -- Loop by player's saved inventory slots
      for slot, items in pairs( InventoryData.GlobalInventory [playerID] ) do
          --Loop by slots
          for i, item in pairs( items ) do
  
            -- Create an inventory item
            local itemEntity = global.ItemManager.CreateByName(item.name, item.amount)
            
            -- Set that created inventory item to player
            player.inventory:GiveItem(itemEntity, Inventory [slot])
          end
       end
       
      -- Send message to user
      self:SendMessage(player, self.Config.Messages.Restored)
    end
end

-- -----------------------------------------------------------------------------
-- PLUGIN:SendMessage( target, message )
-- -----------------------------------------------------------------------------
-- Sends a chatmessage to a player.
-- -----------------------------------------------------------------------------
-- Credit: m-Teleportation
function PLUGIN:SendMessage( target, message )
    -- Check if we have an existing target to send the message to.
    if not target then return end
    if not target:IsConnected() then return end

    -- Check if the message is a table with multiple messages.
    if type( message ) == "table" then
        -- The message is a table with multiple messages, send them one by one.
        for _, message in pairs( message ) do
            self:SendMessage( target, message )
        end

        return
    end
    
    -- "Build" the message to be able to show it correctly.
    message = UnityEngine.StringExtensions.QuoteSafe( message )

    -- Send the message to the targetted player.
    target:SendConsoleCommand( "chat.add \"" .. self.Config.Settings.ChatName .. "\""  .. message );
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

-- -----------------------------------------------------------------------------------
-- PLUGIN:RestoreUponDeath (player)
-- -----------------------------------------------------------------------------------
-- Toogle the config restore upon death
-- -----------------------------------------------------------------------------------
function PLUGIN:RestoreUponDeath (player)
    -- Check if player is admin
    if player:GetComponent("BaseNetworkable").net.connection.authLevel == 2 then
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
-- PLUGIN:SendHelpText( player )
-- -----------------------------------------------------------------------------------
-- HelpText plugin support for the command /help.
-- -----------------------------------------------------------------------------------
function PLUGIN:SendHelpText(player)
    -- Check if user is admin
    if player:GetComponent("BaseNetworkable").net.connection.authLevel == 2 then
        -- Send message to player
        self:SendMessage(player, self.Config.Messages.HelpAdmin)
    else
        -- Send message to player
        self:SendMessage(player, self.Config.Messages.HelpUser)
    end
end