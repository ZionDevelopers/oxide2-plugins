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
        -- Admin TP System:
        AdminTP                        = "You teleported to {player}!",
        AdminTPTarget                  = "{player} teleported to you!",
        AdminTPPlayers                 = "You teleported {player} to {target}!",
        AdminTPPlayer                  = "{admin} teleported you to {player}!",
        AdminTPPlayerTarget            = "{admin} teleported {player} to you!",
        AdminTPCoordinates             = "You teleported to {coordinates}!",
        AdminTPTargetCoordinates       = "You teleported {player} to {coordinates}!",
        AdminTPOutOfBounds             = "You tried to teleport to a set of coordinates outside the map boundaries!",
        AdminTPBoundaries              = "X and Z values need to be between -{boundary} and {boundary} while the Y value needs to be between -100 and 2000!",
        AdminTPLocation                = "You teleported to {location}!",
        AdminTPLocationSave            = "You have saved the current location!",
        AdminTPLocationRemove          = "You have removed the location {location}!",
        AdminLocationList              = "The following locations are available:",
        AdminLocationListEmpty         = "You haven't saved any locations!",
        AdminTPBack                    = "You've teleported back to your previous location!",
        AdminTPBackSave                = "Your previous location has been saved, use /tpb to teleport back!",
        AdminTPTargetCoordinatesTarget = "{admin} teleported you to {coordinates}!",
        AdminTPConsoleTP               = "You were teleported to {destination}",
        AdminTPConsoleTPPlayer         = "You were teleported to {player}",

        -- Homes System:
        HomeTP                        = "You teleported to your home '{home}'!",
        HomeSave                      = "You have saved the current location as your home!",
        HomeSaveFoundationOnly        = "You can only save a home location on a foundation!",
        HomeFoundationNotOwned        = "You can't set your home on someone else's house.",
        HomeFoundationNotFriendsOwned = "You need to be in your own or in a friend's house to set your home!",
        HomeRemove                    = "You have removed your home {home}!",
        HomeList                      = "The following homes are available:",
        HomeListEmpty                 = "You haven't saved any homes!",
        HomeMaxLocations              = "Unable to set your home here, you have reached the maximum of {amount} homes!",
        HomeTPStarted                 = "Teleporting to your home {home} in {countdown} seconds!",
        HomeTPCooldown                = "Your teleport is currently on cooldown. You'll have to wait {time} for your next teleport.",
        HomeTPLimitReached            = "You have reached the daily limit of {limit} teleports today!",
        HomesListWiped                = "You have wiped all the saved home locations!",

        -- TPR System:
        Request              = "You've requested a teleport to {player}!",
        RequestTarget        = "{player} requested to be teleported to you! Use '/tpa' to accept!",
        PendingRequest       = "You already have a request pending, cancel that request or wait until it gets accepted or times out!",
        PendingRequestTarget = "The player you wish to teleport to already has a pending request, try again later!",
        NoPendingRequest     = "You have no pending teleport request!",
        AcceptOnRoof         = "You can't accept a teleport while you're on a ceiling, get to ground level!",
        Accept               = "{player} has accepted your teleport request! Teleporting in {countdown} seconds!",
        AcceptTarget         = "You've accepted the teleport request of {player}!",
        Success              = "You teleported to {player}!",
        SuccessTarget        = "{player} teleported to you!",
        TimedOut             = "{player} did not answer your request in time!",
        TimedOutTarget       = "You did not answer {player}'s teleport request in time!",
        Interrupted          = "Your teleport was interrupted!",
        InterruptedTarget    = "{player}'s teleport was interrupted!",
        TargetDisconnected   = "{player} has disconnected, your teleport was cancelled!",
        TPRCooldown          = "Your teleport requests are currently on cooldown. You'll have to wait {time} to send your next teleport request.",
        TPRLimitReached      = "You have reached the daily limit of {limit} teleport requests today!",

        -- General Messages:
        TPHelp = {
            General = {
                "Please specify the module you want to view the help of. ",
                "The available modules are: ",
            },
            admintp = {
                "As an admin you have access to the following commands:",
                "/tp <targetplayer> - Teleports yourself to the target player.",
                "/tp <player> <targetplayer> - Teleports the player to the target player.",
                "/tp <x> <y> <z> - Teleports you to the set of coordinates.",
                "/tpl - Shows a list of saved locations.",
                "/tpl <location name> - Teleports you to a saved location.",
                "/tpsave <location name> - Saves your current position as the location name.",
                "/tpremove <location name> - Removes the location from your saved list.",
                "/tpb - Teleports you back to the place where you were before teleporting."
            },

            home = {
                "With the following commands you can set your home location to teleport back to:",
                "/sethome <home name> - Saves your current position as the location name.",
                "/listhomes - Shows you a list of all the locations you have saved.",
                "/removehome <home name> - Removes the location of your saved homes.",
                "/home <home name> - Teleports you to the home location."
            },
            tpr = {
                "With these commands you can request to be teleported to a player or accept someone else's request:",
                "/tpr <player name> - Sends a teleport request to the player.",
                "/tpa - Accepts an incoming teleport request."
            }
        },

        TPSettings = {
            General = {
                "Please specify the module you want to view the settings of. ",
                "The available modules are: ",
            },
            home = {
                "Home System as the current settings enabled: ",
                "Time between teleports: {cooldown}",
                "Daily amount of teleports: {limit}",
                "Amount of saved Home locations: {amount}"
            },
            tpr = {
                "TPR System as the current settings enabled: ",
                "Time between teleports: {cooldown}",
                "Daily amount of teleports: {limit}"
            }
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
            "/warp go <name> - Goto a warp."
        }
    }
end