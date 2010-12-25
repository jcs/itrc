(*
Copyright (c) 2006 James Huston
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

property indexList : {}
property nameList : {}
property joinedList : {}
property tempList : {}
property selSongRow : null
property doWeRebuildPlaylist : true
property fullMachineURI : ""
property continueRefresh : false

on action theObject
	if name of theObject is "sl-volume" then
		set newVolume to float value of theObject
		using terms from application "iTunes"
			tell application "iTunes" of machine fullMachineURI to set sound volume to newVolume
		end using terms from
	else if name of theObject is "tf-search" then
		if contents of text field "tf-search" of window "win-main" is not "" then
			my searchiTunes(contents of text field "tf-search" of window "win-main")
		end if
	end if
end action

on clicked theObject
	try
		if name of theObject is "but-prev" then
			my skipTrack("prev")
		else if name of theObject is "but-next" then
			my skipTrack("next")
		else if name of theObject is "but-prevalbum" then
			my skipAlbum("prev")
		else if name of theObject is "but-nextalbum" then
			my skipAlbum("next")
		else if name of theObject is "but-mute" then
			my muteiTunes()
		else if name of theObject is "but-shuffle" then
			my shufflePlaylist()
			set doWeRebuildPlaylist to true
			if state of drawer "drawer-playlist" of window "win-main" is drawer opened then
				my makePlaylist()
			end if
		else if name of theObject is "but-reload" then
			my makePlaylist()
		else if name of theObject is "but-eq" then
			my setEQState(state of theObject)
		else if name of theObject is "but-play" then
			if title of theObject is "I>" then
				my playTrack(true)
			else if title of theObject is "II" then
				my playTrack(false)
			end if
		end if
	on error the error_message number the error_number
		if error_number is equal to -600 then
			my launchiTunes()
		else
			my showAlert(error_number, error_message, localized string "OKAY_BUTTON" from table "Localized", "", "", "win-main", true)
		end if
	end try
end clicked

on choose menu item theObject
	try
		if name of theObject is "menu-playlists" then
			set userPlaylist to name of current menu item of theObject
			my switchPlaylist(userPlaylist)
			set tool tip of theObject to "Current Playlist: " & userPlaylist
			set doWeRebuildPlaylist to true
			if state of drawer "drawer-playlist" of window "win-main" is drawer opened then
				my makePlaylist()
			end if
		else if name of theObject is "menu-eq" then
			set userEQ to name of current menu item of theObject
			my switchEQ(userEQ)
			set tool tip of theObject to "Current EQ: " & userEQ
		else if name of theObject is "menu-refresh" then
			my makePlaylistMenu()
			my makeEQMenu()
			my setState()
			if state of drawer "drawer-playlist" of window "win-main" is drawer opened then
				my makePlaylist()
			end if
			set continueRefresh to true
		else if name of theObject is "menu-quit" then
			set continueRefresh to false
			set title of window "win-main" to "iTunes Remote Control"
			using terms from application "iTunes"
				tell application "iTunes" of machine fullMachineURI to quit
			end using terms from
		end if
	on error the error_message number the error_number
		if error_number is equal to -600 then
			my launchiTunes()
		else
			my showAlert(error_number, error_message, localized string "OKAY_BUTTON" from table "Localized", "", "", "win-main", true)
		end if
	end try
end choose menu item

on activated theObject
	try
		if continueRefresh is true then
			my setState()
		end if
	on error the error_message number the error_number
		my showAlert(error_number, error_message, localized string "OKAY_BUTTON" from table "Localized", "", "", "win-main", true)
	end try
end activated

on idle theObject
	try
		if continueRefresh is true then
			my setState()
			if (contents of default entry "UpdateMoreOften" of user defaults as boolean) is false then
				return 5
			else if (contents of default entry "UpdateMoreOften" of user defaults as boolean) is true then
				return 2
			end if
		end if
	on error the error_message number the error_number
		if error_number is equal to -600 then
			my launchiTunes()
		else
			my showAlert(error_number, error_message, localized string "OKAY_BUTTON" from table "Localized", "", "", "win-main", true)
		end if
	end try
end idle

on double clicked theObject
	try
		set songID to contents of data cell "track_id" of data row selSongRow of data source of table view "tv-playlist" of scroll view "sv-playlist" of drawer "drawer-playlist" of window "win-main" as integer
		using terms from application "iTunes"
			tell application "iTunes" of machine fullMachineURI to play track songID of view of first browser window
		end using terms from
		if continueRefresh is true then
			my setState()
		end if
	on error the error_message number the error_number
		if error_number is equal to -600 then
			my launchiTunes()
		else
			my showAlert(error_number, error_message, localized string "OKAY_BUTTON" from table "Localized", "", "", "win-main", true)
		end if
	end try
end double clicked

on launched theObject
	try
		if fullMachineURI is not "eppc://" then
			my makePlaylistMenu()
			my makeEQMenu()
			my setState()
			set continueRefresh to true
		end if
	on error the error_message number the error_number
		if error_number is equal to -600 then
			my launchiTunes()
		else if error_number is not equal to -128 then
			my showAlert(error_number, error_message, localized string "OKAY_BUTTON" from table "Localized", "", "", "win-main", true)
		end if
	end try
end launched

on selection changed theObject
	set selSongRow to selected row of theObject
end selection changed

on awake from nib theObject
	set playlistTable to data source of table view "tv-playlist" of scroll view "sv-playlist" of drawer "drawer-playlist" of window "win-main"
	tell playlistTable
		make new data column at the end of the data columns with properties {name:"track_id", sort type:numerical, sort case sensitivity:case insensitive}
		make new data column at the end of the data columns with properties {name:"track_artist", sort type:alphabetical, sort case sensitivity:case insensitive}
		make new data column at the end of the data columns with properties {name:"track_title", sort type:alphabetical, sort case sensitivity:case insensitive}
	end tell
	set sorted of playlistTable to true
	set sort column of playlistTable to data column "track_id" of playlistTable
	set data source of theObject to playlistTable
end awake from nib

on opened theObject
	try
		if doWeRebuildPlaylist is true then
			my makePlaylist()
			set doWeRebuildPlaylist to false
		end if
	on error the error_message number the error_number
		my showAlert(error_number, error_message, localized string "OKAY_BUTTON" from table "Localized", "", "", "win-main", true)
	end try
end opened

on end editing theObject
	try
		if name of theObject is "tf-machineURI" then
			set machineURI to contents of text field "tf-machineuri" of window "win-prefs"
			set fullMachineURI to "eppc://" & machineURI
			set contents of default entry "MachineURI" of user defaults to machineURI
			if fullMachineURI is not "eppc://" then
				set continueRefresh to true
			end if
			my makePlaylistMenu()
			my makeEQMenu()
			my setState()
			if state of drawer "drawer-playlist" of window "win-main" is drawer opened then
				my makePlaylist()
			end if
		end if
	on error the error_message number the error_number
		my showAlert(error_number, error_message, localized string "OKAY_BUTTON" from table "Localized", "", "", "win-main", true)
	end try
end end editing

on will finish launching theObject
	make new default entry at end of default entries of user defaults with properties {name:"MachineURI", contents:""}
	make new default entry at end of default entries of user defaults with properties {name:"refreshRate", contents:"50"}
	make new default entry at end of default entries of user defaults with properties {name:"SUCheckAtStartup", contents:false}
	make new default entry at end of default entries of user defaults with properties {name:"QuitiTunes", contents:false}
	make new default entry at end of default entries of user defaults with properties {name:"ShowProgress", contents:true}
	make new default entry at end of default entries of user defaults with properties {name:"UpdateMoreOften", contents:false}
	make new default entry at end of default entries of user defaults with properties {name:"MainWindowPosition", contents:""}
	make new default entry at end of default entries of user defaults with properties {name:"IncreasePlayCount", contents:false}
	try
		set bounds of window "win-main" to contents of default entry "MainWindowPosition" of user defaults as list
	end try
	set visible of progress indicator "pi-dur" of window "win-main" to (contents of default entry "ShowProgress" of user defaults)
	set state of button "but-update" of window "win-prefs" to (contents of default entry "UpdateMoreOften" of user defaults)
	set state of button "but-checkupdates" of window "win-prefs" to (contents of default entry "SUCheckAtStartup" of user defaults)
	set state of button "but-showprogress" of window "win-prefs" to (contents of default entry "ShowProgress" of user defaults)
	set state of button "but-quit" of window "win-prefs" to (contents of default entry "QuitiTunes" of user defaults)
	set state of button "but-addplay" of window "win-prefs" to (contents of default entry "IncreasePlayCount" of user defaults)
	set machineURI to contents of default entry "MachineURI" of user defaults
	set refreshRate to contents of default entry "refreshRate" of user defaults
	if machineURI is "" then
		display dialog "Enter the address of the computer iTunes is on:" default answer "" buttons {"OK"} default button 1
		set machineURI to text returned of the result
		set contents of default entry "MachineURI" of user defaults to machineURI
	end if
	set contents of text field "tf-machineuri" of window "win-prefs" to machineURI
	set fullMachineURI to "eppc://" & machineURI
	set title of popup button "menu-refreshrate" of window "win-prefs" to refreshRate
	my registerGrowl()
	set background color of window "win-main" to {59135, 59135, 59135}
	tell window "win-main" to update
	set visible of window "win-main" to true
end will finish launching

on will quit theObject
	set contents of default entry "MainWindowPosition" of user defaults to bounds of window "win-main" as list
	if contents of default entry "QuitiTunes" of user defaults as boolean is true then
		using terms from application "iTunes"
			tell application "iTunes" of machine fullMachineURI to quit
		end using terms from
	end if
end will quit

(* START TRACK CONTROL FUNCTIONS *)

on playTrack(playingState) -- playingState true=playing false=paused/stopped
	using terms from application "iTunes"
		tell application "iTunes" of machine fullMachineURI to playpause
	end using terms from
	if playingState is true then
		set title of button "but-play" of window "win-main" to "II"
		set title of menu item "mi-play" of popup button "menu-dock" of window "win-hiden" to "Pause"
		my setState()
	else if playingState is false then
		set title of button "but-play" of window "win-main" to "I>"
		set title of menu item "mi-play" of popup button "menu-dock" of window "win-hiden" to "Play"
	end if
end playTrack

on stopTrack()
	using terms from application "iTunes"
		tell application "iTunes" of machine fullMachineURI to stop
	end using terms from
	set title of button "but-play" of window "win-main" to "I>"
end stopTrack

on skipTrack(direction) -- direction next=skip forward prev=skip backward
	set addPlay to contents of default entry "IncreasePlayCount" of user defaults as boolean
	using terms from application "iTunes"
		if direction is "next" then
			tell application "iTunes" of machine fullMachineURI
				if addPlay is true then
					try
						set played count of current track to ((played count of current track) + 1)
						set played date of current track to current date
					end try
				end if
				next track
			end tell
		else if direction is "prev" then
			tell application "iTunes" of machine fullMachineURI to back track
		end if
	end using terms from
	my setState()
	set contents of progress indicator "pi-dur" of window "win-main" to 0
end skipTrack

(* END TRACK CONTROL FUNCTIONS *)

(* BEGIN ALBUM CONTROL FUNCTIONS *)

on skipAlbum(direction) -- direction next=skip forward prev=skip backward
	using terms from application "iTunes"
		tell application "iTunes" of machine fullMachineURI
			set currentAlbum to the album of the current track
			if player state is playing then
				set wasPlaying to true
				pause
			else
				set wasPlaying to false
			end if
			
			repeat while the album of the current track is equal to currentAlbum
				if direction is "next" then
					next track
				else if direction is "prev" then
					back track
				end if
			end repeat
			
			-- for skipping back an album, we're now at the last track of this previous album,
			-- so go back again, then forward one 
			if direction is "prev" then
				set currentAlbum to the album of the current track
				repeat while the album of the current track is equal to currentAlbum
					back track
				end repeat
				next track
			end if
			
			if wasPlaying is true then
				play
			end if
		end tell
	end using terms from
	my setState()
	set contents of progress indicator "pi-dur" of window "win-main" to 0
end skipAlbum

(* END ALBUM CONTROL FUNCTIONS *)

(* BEGIN ITUNES CONTROL FUNCTIONS *)

on muteiTunes()
	using terms from application "iTunes"
		tell application "iTunes" of machine fullMachineURI to set mute to not (mute)
	end using terms from
end muteiTunes

on setEQState(eqState) --eqState=boolen value for on/off
	using terms from application "iTunes"
		tell application "iTunes" of machine fullMachineURI to set EQ enabled to eqState
	end using terms from
end setEQState

on shufflePlaylist()
	using terms from application "iTunes"
		tell application "iTunes" of machine fullMachineURI
			set shuffle of view of first browser window to not shuffle of view of first browser window
			set shufState to shuffle of view of first browser window
		end tell
	end using terms from
	set state of menu item "mi-shuffle" of popup button "menu-dock" of window "win-hiden" to shufState
end shufflePlaylist

on switchPlaylist(userPlaylist) -- userPlaylist=name of selected playlist
	using terms from application "iTunes"
		tell application "iTunes" of machine fullMachineURI
			try
				set view of first browser window to playlist userPlaylist
			on error
				set myCDs to every source whose kind is audio CD
				repeat with i from 1 to count of myCDs
					if name of audio CD playlist 1 of item i of myCDs = userPlaylist then
						set view of first browser window to audio CD playlist 1 of item i of myCDs
						exit repeat
					end if
				end repeat
			end try
			set shuffleState to shuffle of view of first browser window
		end tell
	end using terms from
	my stopTrack()
	my playTrack(true)
	set state of button "but-shuffle" of window "win-main" to shuffleState
end switchPlaylist

on switchEQ(userEQ) -- userEQ=name of selected EQ
	using terms from application "iTunes"
		tell application "iTunes" of machine fullMachineURI to set current EQ preset to EQ preset userEQ
	end using terms from
end switchEQ

(* END ITUNES CONTROL FUNCTIONS *)

(* BEGIN ITRC STATE FUNCTIONS *)

on setState()
	set iTunesInfo to my getiTunesInfo()
	if currentState of iTunesInfo is "playing" then
		set title of button "but-play" of window "win-main" to "II"
		set title of menu item "mi-play" of popup button "menu-dock" of window "win-hiden" to "Pause"
		my trackInfo(iTunesInfo)
	else if currentState of iTunesInfo is "paused" then
		set title of button "but-play" of window "win-main" to "I>"
		set title of menu item "mi-play" of popup button "menu-dock" of window "win-hiden" to "Play"
	else if currentState of iTunesInfo is "stopped" then
		set title of button "but-play" of window "win-main" to "I>"
		set title of menu item "mi-play" of popup button "menu-dock" of window "win-hiden" to "Play"
		set title of window "win-main" to "iTunes Remote Control"
	end if
	set contents of progress indicator "pi-dur" of window "win-main" to currentSongPosition of iTunesInfo
	set title of popup button "menu-playlists" of window "win-main" to currentPlaylist of iTunesInfo
	set title of popup button "menu-eq" of window "win-main" to currentEQ of iTunesInfo
	set title of popup button "menu-rate" of window "win-main" to currentSongStar of iTunesInfo
	set state of button "but-eq" of window "win-main" to eqState of iTunesInfo
	set state of button "but-mute" of window "win-main" to muteState of iTunesInfo
	set contents of slider "sl-volume" of window "win-main" to currentVolume of iTunesInfo
	set tool tip of popup button "menu-playlists" of window "win-main" to "Current Playlist: " & currentPlaylist of iTunesInfo
	set tool tip of popup button "menu-eq" of window "win-main" to "Current EQ: " & currentEQ of iTunesInfo
	set ratingStars to ""
	repeat with i from 1 to currentSongStar of iTunesInfo
		set ratingStars to ratingStars & (localized string "STAR" from table "Localized")
	end repeat
	set tool tip of popup button "menu-rate" of window "win-main" to "Current Rating: " & ratingStars
	set state of button "but-shuffle" of window "win-main" to shuffleState of iTunesInfo
	set state of every menu item of popup button "menu-dock" of window "win-hiden" to 0
	set state of menu item "mi-shuffle" of popup button "menu-dock" of window "win-hiden" to shuffleState of iTunesInfo
	set state of menu item "menu-mutecomp" of menu "menu-itunes" of main menu to computerMuted of iTunesInfo
	try
		my setCurSong(songID of iTunesInfo)
	end try
end setState

on getiTunesInfo()
	set theList to {}
	using terms from application "iTunes"
		tell application "iTunes" of machine fullMachineURI
			if player state is playing then
				set currentState to "playing"
				set currentSongRate to rating of current track
				set songID to get index of current track
				set currentSongPosition to player position
				set artistName to artist of current track
				set trackName to name of current track
				set albumName to album of current track
				set trackDur to duration of current track
			else if player state is paused then
				set currentState to "paused"
				set currentSongRate to rating of current track
				set songID to get index of current track
				set currentSongPosition to player position
				set artistName to artist of current track
				set trackName to name of current track
				set albumName to album of current track
				set trackDur to duration of current track
			else if player state is stopped then
				set currentState to "stopped"
				set currentSongStar to "0"
				set songID to 1
				set currentSongPosition to "0"
				set artistName to ""
				set trackName to ""
				set albumName to ""
				set trackDur to 0
			end if
			
			set currentPlaylist to name of view of first browser window
			set shuffleState to shuffle of view of first browser window
			set muteState to mute
			set currentVolume to sound volume
			set currentEQ to name of current EQ preset
			set eqState to EQ enabled
			set computerMuted to 0
			
			-- this fails when the computer is using digital audio output and has no volume control 
			try
				set computerMuted to output muted of (get volume settings) as integer
			end try
		end tell
	end using terms from
	
	if currentSongRate is 20 then
		set currentSongStar to "1"
	else if currentSongRate is 40 then
		set currentSongStar to "2"
	else if currentSongRate is 60 then
		set currentSongStar to "3"
	else if currentSongRate is 80 then
		set currentSongStar to "4"
	else if currentSongRate is 100 then
		set currentSongStar to "5"
	else
		set currentSongStar to "0"
	end if
	
	set theList to {currentState:currentState, currentPlaylist:currentPlaylist, shuffleState:shuffleState, currentSongPosition:currentSongPosition, currentSongStar:currentSongStar, muteState:muteState, currentVolume:currentVolume, currentEQ:currentEQ, songID:songID, eqState:eqState, computerMuted:computerMuted, artistName:artistName, trackName:trackName, albumName:albumName, trackDur:trackDur}
	return theList
end getiTunesInfo

on trackInfo(cachedTrackInfo)
	set oldTrackID to contents of text field "tf-title" of window "win-main" & contents of text field "tf-artist" of window "win-main" & contents of text field "tf-album" of window "win-main"
	set newTrackID to trackName of cachedTrackInfo & artistName of cachedTrackInfo & albumName of cachedTrackInfo
	set maximum value of progress indicator "pi-dur" of window "win-main" to trackDur of cachedTrackInfo
	set contents of text field "tf-artist" of window "win-main" to artistName of cachedTrackInfo
	set contents of text field "tf-title" of window "win-main" to trackName of cachedTrackInfo
	set contents of text field "tf-album" of window "win-main" to albumName of cachedTrackInfo
	set title of window "win-main" to "< " & artistName of cachedTrackInfo & " - " & trackName of cachedTrackInfo & " >"
	set tool tip of text field "tf-artist" of window "win-main" to artistName of cachedTrackInfo
	set tool tip of text field "tf-title" of window "win-main" to trackName of cachedTrackInfo
	set tool tip of text field "tf-album" of window "win-main" to albumName of cachedTrackInfo
	set enabled of menu item "mi-artist" of popup button "menu-dock" of window "win-hiden" to false
	set title of menu item "mi-artist" of popup button "menu-dock" of window "win-hiden" to artistName of cachedTrackInfo & " - " & trackName of cachedTrackInfo
	if newTrackID is not oldTrackID then
		my trackChangeGrowl(artistName of cachedTrackInfo, trackName of cachedTrackInfo, albumName of cachedTrackInfo)
	end if
end trackInfo

on makeEQMenu()
	using terms from application "iTunes"
		tell application "iTunes" of machine fullMachineURI to set eqList to name of every EQ preset
	end using terms from
	tell window "win-main"
		delete every menu item of menu of popup button "menu-eq"
		repeat with i from 1 to (count of eqList)
			set eqName to item i of eqList
			make new menu item at the end of menu items of menu of popup button "menu-eq" with properties {title:eqName, name:eqName, enabled:true}
		end repeat
	end tell
	set eqList to {}
end makeEQMenu

on makePlaylistMenu()
	using terms from application "iTunes"
		tell application "iTunes" of machine fullMachineURI
			set userPlaylists to name of every playlist
			if "iTRC Search Results" is not in userPlaylists then
				make new user playlist with properties {name:"iTRC Search Results"}
				copy "iTRC Search Results" to end of userPlaylists
			end if
			set myCDs to every source whose kind is audio CD
			repeat with i from 1 to count of myCDs
				copy name of item i of myCDs to end of userPlaylists
			end repeat
		end tell
	end using terms from
	set userPlaylists to my sortList(userPlaylists)
	tell window "win-main"
		delete every menu item of menu of popup button "menu-playlists"
		repeat with i from 1 to (count of userPlaylists)
			set playlistName to item i of userPlaylists
			make new menu item at the end of menu items of menu of popup button "menu-playlists" with properties {title:playlistName, name:playlistName, enabled:true}
		end repeat
	end tell
	set userPlaylists to {}
end makePlaylistMenu

on makePlaylist()
	try
		set refreshRate to contents of default entry "refreshRate" of user defaults as string
		set tempList to {}
		set indexList to {}
		using terms from application "iTunes"
			tell application "iTunes" of machine fullMachineURI
				try
					set indexList to index of every track of view of first browser window
					set artistList to artist of every track of view of first browser window
					set nameList to name of every track of view of first browser window
				end try
			end tell
		end using terms from
		set totalTracks to count of indexList
		delete every data row of data source of table view "tv-playlist" of scroll view "sv-playlist" of drawer "drawer-playlist" of window "win-main"
		
		if totalTracks > 0 then
			set playlistCounter to 0
			set continueRefresh to false
			set visible of progress indicator "pi-playlist" of window "win-main" to true
			set visible of progress indicator "pi-dur" of window "win-main" to false
			set maximum value of progress indicator "pi-playlist" of window "win-main" to totalTracks
			
			repeat with i from 1 to totalTracks
				set playlistCounter to playlistCounter + 1
				set contents of progress indicator "pi-playlist" of window "win-main" to i
				set tempList to {track_id:item i of indexList, track_artist:item i of artistList, track_title:item i of nameList}
				copy tempList to end of joinedList
				if playlistCounter as integer = refreshRate as integer then
					append data source of table view "tv-playlist" of scroll view "sv-playlist" of drawer "drawer-playlist" of window "win-main" with joinedList
					set joinedList to {}
					set playlistCounter to 0
				end if
				set testValue to ""
				set numlist to {}
				set tempList to {}
			end repeat
			append data source of table view "tv-playlist" of scroll view "sv-playlist" of drawer "drawer-playlist" of window "win-main" with joinedList
			
			if contents of default entry "ShowProgress" of user defaults as boolean is true then
				set visible of progress indicator "pi-dur" of window "win-main" to true
			end if
			
			set visible of progress indicator "pi-playlist" of window "win-main" to false
			set continueRefresh to true
			my setState()
			set joinedList to {}
			set doWeRebuildPlaylist to false
		end if
	on error the error_message number the error_number
	end try
end makePlaylist

on setCurSong(songID) -- songID=numeric ID of the song in the current playlist
	try
		set selected row of table view "tv-playlist" of scroll view "sv-playlist" of drawer "drawer-playlist" of window "win-main" to songID
	end try
end setCurSong

(* END ITRC STATE FUNCTIONS *)

(* BEGIN GROWL FUNCTIONS *)

on checkForGrowl()
	tell application "System Events" to set isGrowlRunning to count of (application processes whose (name is equal to "GrowlHelperApp"))
	return isGrowlRunning
end checkForGrowl

on registerGrowl()
	try
		if my checkForGrowl() is not 0 then
			set appName to "iTunes Remote Control"
			set notificationName to {"Track Changed"}
			using terms from application "GrowlHelperApp"
				tell application "GrowlHelperApp" to register as application appName all notifications notificationName default notifications notificationName icon of application "iTunes"
			end using terms from
		end if
	end try
end registerGrowl

on trackChangeGrowl(artistName, trackName, albumName)
	try
		if my checkForGrowl() is not 0 then
			using terms from application "GrowlHelperApp"
				tell application "GrowlHelperApp" to notify with name "Track Changed" title trackName application name "iTunes Remote Control" identifier "iTRC" description artistName & "
" & albumName
			end using terms from
		end if
	end try
end trackChangeGrowl

(* END GROWL FUNCTIONS *)

(* BEGIN SEARCH FUNCTIONS *)

on searchiTunes(searchTerm)
	set continuedRefresh to false
	if contents of default entry "ShowProgress" of user defaults as boolean is true then
		set visible of progress indicator "pi-dur" of window "win-main" to false
	end if
	set visible of progress indicator "pi-playlist" of window "win-main" to true
	set indeterminate of progress indicator "pi-playlist" of window "win-main" to true
	set uses threaded animation of progress indicator "pi-playlist" of window "win-main" to true
	tell progress indicator "pi-playlist" of window "win-main" to start
	using terms from application "iTunes"
		tell application "iTunes" of machine fullMachineURI
			set DestPlaylist to user playlist "iTRC Search Results"
			delete every track of DestPlaylist
			duplicate (every track of library playlist 1 whose album contains searchTerm or artist contains searchTerm or name contains searchTerm) to DestPlaylist
		end tell
	end using terms from
	set continuedRefresh to true
	tell progress indicator "pi-playlist" of window "win-main" to stop
	set indeterminate of progress indicator "pi-playlist" of window "win-main" to false
	my switchPlaylist("iTRC Search Results")
	set state of drawer "drawer-playlist" of window "win-main" to drawer opening
	set state of button "but-playlist" of window "win-main" to 1
	if state of drawer "drawer-playlist" of window "win-main" is drawer opened then
		my makePlaylist()
	else if contents of default entry "ShowProgress" of user defaults as boolean is true then
		set visible of progress indicator "pi-playlist" of window "win-main" to false
		set visible of progress indicator "pi-dur" of window "win-main" to true
		set doWeRebuildPlaylist to true
	end if
end searchiTunes

(* END SEARCH FUNCTIONS *)

on launchiTunes()
	set openiTunes to my showAlert(localized string "ITUNES_OPEN" from table "Localized", localized string "ITUNES_OPEN_TEXT" from table "Localized", localized string "OPEN_BUTTON" from table "Localized", localized string "CANCEL_BUTTON" from table "Localized", "", "win-main", false)
	if openiTunes = 1 then
		tell application "Finder" of machine fullMachineURI to open "/Applications/iTunes.app" as POSIX file
		my makePlaylistMenu()
		my makeEQMenu()
		my setState()
		set continueRefresh to true
	end if
	set userPlaylists to {}
end launchiTunes

on showAlert(dialogText, dialogMessage, defaultButtonTitle, alternateButtonTitle, otherButtonTitle, inWindow, asSheet)
	set continueRefresh to false
	set userPlaylists to {}
	if asSheet is true then
		display alert dialogText as informational message dialogMessage default button defaultButtonTitle alternate button alternateButtonTitle other button otherButtonTitle attached to window inWindow
	else if asSheet is false then
		set theReply to display alert dialogText as informational message dialogMessage default button defaultButtonTitle alternate button alternateButtonTitle other button otherButtonTitle
		if (button returned of theReply) is defaultButtonTitle then
			return 1
		else if (button returned of theReply) is alternateButtonTitle then
			return 2
		else if (button returned of theReply) is otherButtonTitle then
			return 3
		end if
	end if
end showAlert

on createHash(songInfo)
	set shellScript to "/bin/echo " & quoted form of songInfo & " | /usr/bin/openssl md5"
	set idHash to do shell script shellScript
	return idHash
end createHash

on sortList(my_list)
	set old_delims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to {ASCII character 10} -- always a linefeed
	set list_string to (my_list as string)
	set new_string to do shell script "echo " & quoted form of list_string & " | sort -f"
	set new_list to (paragraphs of new_string)
	set AppleScript's text item delimiters to old_delims
	return new_list
end sortList
