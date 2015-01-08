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
local TeleportVectors = {}
local TeleportPreviousLocation = {}

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
        ChatName = "Warp",
        ConfigVersion = "0.0.1",
        WarpEnabled = true
    }
    
    -- Warp System Settings: 
    self.Config.Warp = {
        Cooldown = 600,
        Countdown = 15,
        DailyGotoLimit = 500,
        ModeratorsCanManageWarps = true,
        LocationRadius = 25,
        WarpNearDefaultDistance = 30
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
        WarpSave = "You have saved the {name} warp as {x}, {y}, {z}!",
        WarpDelete = "You have deleted the {name} warp!",
        WarpRen = 'You have renamed the warp {oldname} to {newname}!',
        WarpAuthNeeded = 'You don\'t have the right Auth Level to use "{command}!"',
        WarpExists = 'The warp {name} already exists!',

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
function PLUGIN:cmdWarp( player, _, args )
    -- Check if the Warp System is enabled.
    if not self.Config.Settings.WarpEnabled then return end
    
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
              self:WarpAdd( player, param, x, y, z )    
            end            
        else
            -- Send message to player
            self:SendMessage( player, self.Config.Messages.SyntaxCommandWarp )
        end
    -- Check if the command is to delete a warp
    elseif cmd == 'del' then
        -- Check if param is valid
        if param ~= '' and param ~= ' ' then
              -- Delete a warp
              self:WarpDel( player, param )    
        end
    -- Check if the command is to use a warp
    elseif cmd == 'go' then
        -- Check if param is valid
        if param ~= '' and param ~= ' ' then
            -- Use a Warp
            self:WarpUse(player, param)
        end
    -- Check if the command is to go back before warp
    elseif cmd == 'back' then
      -- Go Back to the Previous location to Warp
       self:WarpBack(player)
    elseif cmd == 'list' then
      -- List Warps
       self:WarpList(player)
    end
end

-- -----------------------------------------------------------------------------
-- PLUGIN:WarpAdd( player, name, x, y, z )
-- -----------------------------------------------------------------------------
-- Add a new warp.
-- -----------------------------------------------------------------------------
function PLUGIN:WarpAdd ( player, name, x, y, z ) 
    
    -- Check if the player is allowed to run the command.
    if self:IsAllowed( player ) then 
        -- Check if Warp already exists
        if WarpData.WarpPoints[name] == nil then
            -- Check for coordinates
            if x == 0 and y == 0 and z == 0 then
                -- Add Warp at player current location
                WarpData.WarpPoints[name] = player.transform.position
            else
                -- Add Warp at the the position
                WarpData.WarpPoints[name] = {x = x, y = y, z = z}
            end
            
            -- Save data
            self:SaveData()
            -- Send message to player
            self:SendMessage( player, self:Parse( self.Config.Messages.WarpSave, {name = name, x = player.transform.position.x, y = player.transform.position.y, z = player.transform.position.z} ) )
          else
              -- Send message to player
              self:SendMessage( player, self:Parse( self.Config.Messages.WarpExists, {name = name} ) )   
          end 
      else
          -- Send message to player
          self:SendMessage( player, self:Parse( self.Config.Messages.WarpAuthNeeded, {command = '/warp add'} ) ) 
      end
end

-- -----------------------------------------------------------------------------
-- PLUGIN:WarpDel( player, name )
-- -----------------------------------------------------------------------------
-- Delete a warp.
-- -----------------------------------------------------------------------------
function PLUGIN:WarpDel( player, name )
    -- Check if the player is allowed to run the command.
    if self:IsAllowed( player ) then 
      -- Check if Warp exists
      if WarpData.WarpPoints[name] ~= nil then
          -- Delete warp
          WarpData.WarpPoints[name] = nil        
                  
          -- Save data
          self:SaveData()
          -- Send message to player
          self:SendMessage( player, self:Parse( self.Config.Messages.WarpDeleted, {name = name} ) )
      else
        -- Send message to player
        self:SendMessage( player, self.Config.Messages.WarpNotFound )
      end      
    else
        -- Send message to player
        self:SendMessage( player, self:Parse( self.Config.Messages.WarpAuthNeeded, {command = '/warp del'} ) ) 
    end
end

-- -----------------------------------------------------------------------------
-- PLUGIN:WarpRen( player, oldname, newname )
-- -----------------------------------------------------------------------------
-- Rename a warp.
-- -----------------------------------------------------------------------------
function PLUGIN:WarpRen( player, name )
    -- Check if the player is allowed to run the command.
    if self:IsAllowed( player ) then 
      -- Check if Warp exists
      if WarpData.WarpPoints[oldname] ~= nil then
           -- Check if Warp new exists
          if WarpData.WarpPoints[newname] == nil then
              -- Create a new warp
              WarpData.WarpPoints[newname] = WarpData.WarpPoints[oldname] 
              -- Delete warp
              WarpData.WarpPoints[oldname] = nil        

              -- Save data
              self:SaveData()
              -- Send message to player
              self:SendMessage( player, self:Parse( self.Config.Messages.WarpRen, {name = name} ) )
          else
              -- Send message to player
              self:SendMessage( player, self:Parse( self.Config.Messages.WarpExists, {name = newname} ) )   
          end
      else
        -- Send message to player
        self:SendMessage( player, self.Config.Messages.WarpNotFound )
      end      
    else
        -- Send message to player
        self:SendMessage( player, self:Parse( self.Config.Messages.WarpAuthNeeded, {command = '/warp ren'} ) ) 
    end
end

-- -----------------------------------------------------------------------------
-- PLUGIN:WarpUse( player, name )
-- -----------------------------------------------------------------------------
-- Use a Warp to teleport player to a location.
-- -----------------------------------------------------------------------------
function PLUGIN:WarpUse( player, name )
    -- Check if Warp exists
    if WarpData.WarpPoints[name] ~= nil then
        -- Teleport Player to Location
        self:TeleportToPosition(player, WarpData.WarpPoints[name].x, WarpData.WarpPoints[name].y, WarpData.WarpPoints[name].z)
    else
      -- Send message to player
      self:SendMessage( player, self.Config.Messages.WarpNotFound )
    end  
end

-- -----------------------------------------------------------------------------
-- PLUGIN:WarpBack( player )
-- -----------------------------------------------------------------------------
-- Go back to a point where the player was
-- -----------------------------------------------------------------------------
function PLUGIN:WarpBack( player, name )
    -- Get PlayerID
    local playerID = rust.UserIDFromPlayer( player )
    
    -- Check if player already used the Warp
    if TeleportPreviousLocation[playerID] ~= nil then
      -- Teleport Player to Location
      self:TeleportToPosition(player, TeleportPreviousLocation[playerID].x, TeleportPreviousLocation[playerID].y, TeleportPreviousLocation[playerID].z)
    end    
end

-- -----------------------------------------------------------------------------
-- PLUGIN:WarpList( player )
-- -----------------------------------------------------------------------------
-- List all the saved warps
-- -----------------------------------------------------------------------------
function PLUGIN:WarpList(player)
    -- Send message to player
    self:SendMessage( player, self.Config.Messages.WarpList)
     
    -- Loop through all the saved locations and print them one by one.
    for location, coordinates in pairs( WarpData.WarpPoints ) do
        self:SendMessage( player, location .. ": " .. math.floor( coordinates.x ) .. " " .. math.floor( coordinates.y ) .. " " .. math.floor( coordinates.z ) )
    end 
end

-- -----------------------------------------------------------------------------
-- PLUGIN:Parse( message, values )
-- -----------------------------------------------------------------------------
-- Replaces the parameters in a message with the corresponding values.
-- -----------------------------------------------------------------------------
-- Credit: m-Teleportation
function PLUGIN:Parse( message, values )
    for k, v in pairs( values ) do
        -- Replace the variable in the message with the specified value.
        tostring(v):gsub("(%%)", "%%%%") 
        message = message:gsub( "{" .. k .. "}", v)
    end

    return message
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


-- -----------------------------------------------------------------------------
-- PLUGIN:Teleport( player, destination )
-- -----------------------------------------------------------------------------
-- Teleports a player to a specific location.
-- -----------------------------------------------------------------------------
-- Credit: m-Teleportation
function PLUGIN:Teleport( player, destination )
    local preTeleportLocation = new( UnityEngine.Vector3._type, nil )
    
    -- Generate values for the pre-teleportation location if these do not exist.
    if #TeleportVectors == 0 then
        local coordsArray = util.TableToArray( { 0, 0, 0 } )
        local tempValues = { 
            { x = 2000, y = 0, z = 2000 },
            { x = 2000, y = 0, z = -2000 },
            { x = -2000, y = 0, z = -2000 },
            { x = -2000, y = 0, z = 2000 }
        }

        for k, v in pairs( tempValues ) do
            util.ConvertAndSetOnArray( coordsArray, 0, v.x, System.Single._type )
            util.ConvertAndSetOnArray( coordsArray, 1, v.y, System.Single._type )
            util.ConvertAndSetOnArray( coordsArray, 2, v.z, System.Single._type )
            vector3 = new( UnityEngine.Vector3._type, coordsArray )
            table.insert( TeleportVectors, vector3 )
        end
    end
 
    -- Get a valid pre-teleport position, far enough from the current position
    -- and far enough from the destination.
    for _,vector3 in pairs( TeleportVectors ) do
        if UnityEngine.Vector3.Distance( player.transform.position, vector3 ) > 1000 and UnityEngine.Vector3.Distance( destination, vector3 ) > 1000 then
            preTeleportLocation = vector3
        end
    end
    
    -- Without the pre-teleport the teleport behavior on short range teleports
    -- is unreliable. Sometimes it would work, sometimes it wouldn't. Because
    -- of this we will first teleport the player to a further away position.
    player.transform.position = preTeleportLocation
    player:UpdateNetworkGroup()
    player:UpdatePlayerCollider(true, false)

    -- Add a little bit of height to the destination.
    destination.y = destination.y + 0.2

    -- Teleport the player to the location he wanted to go.
    player.transform.position = destination

    -- Set the player flag to receiving snapshots and update the player.
    player:SetPlayerFlag( global.PlayerFlags.ReceivingSnapshot, true )
    player:UpdateNetworkGroup()
    player:UpdatePlayerCollider(true, false)

    -- Let the player sleep, this will prevent the player from falling through
    -- objects while still loading.
    player:StartSleeping()
    
    -- Send the server snapshot to the player.
    player:SendFullSnapshot()

    -- Send the client an RPC Message as it is done in BasePlayer.Respawn()
    local RPCMessage    = new( ProtoBuf.RPCMessage._type, nil )
    RPCMessage.funcName = global.StringPool.Get.methodarray[1]:Invoke( nil, util.TableToArray( { "startloading" } ) )
    RPCMessage.data     = nil

    MessageClient:Invoke( nil , util.TableToArray( { player.net, player.net.connection, UnityEngine.MSG.RPC_MESSAGE, RPCMessage:ToProtoBytes() } ) )

    -- Send a networkupdate.
    player:SendNetworkUpdateImmediate()
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
-- PLUGIN:TeleportToPosition( player, x, y, z )
-- -----------------------------------------------------------------------------
-- Teleports a player to a set of coordinates.
-- -----------------------------------------------------------------------------
-- Credit: m-Teleportation
function PLUGIN:TeleportToPosition( player, x, y, z )
    local playerID = rust.UserIDFromPlayer( player )
    -- set the destination for the player.
    local destination = new( UnityEngine.Vector3._type, nil )
    destination.x = x 
    destination.y = y
    destination.z = z
    
    -- Save current position
    TeleportPreviousLocation[playerID] = {x = player.transform.position.x, y = player.transform.position.y, z = player.transform.position.z}

    -- Teleport the player to the destination.
    self:Teleport( player, destination )
end