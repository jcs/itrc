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

on choose menu item theObject
	set fullMachineURI to "eppc://" & contents of default entry "MachineURI" of user defaults
	if name of theObject is "menu-updatepodcast" then
		using terms from application "iTunes"
			tell application "iTunes" of machine fullMachineURI to updateAllPodcasts
		end using terms from
	else if name of theObject is "menu-subscribe" then
		set thePanel to window "win-subscribe"
		display panel thePanel attached to window "win-main"
	else if name of theObject is "menu-prefs" then
		display panel window "win-prefs" attached to window "win-main"
	else if name of theObject is "menu-open" then
		tell application "Finder" of machine fullMachineURI to open "/Applications/iTunes.app" as POSIX file
	else if name of theObject is "menu-refreshrate" then
		set contents of default entry "refreshRate" of user defaults to (title of current menu item of theObject)
	else if name of theObject is "menu-mutecomp" then
		set state of theObject to not (state of theObject as boolean)
		tell application "iTunes" of machine fullMachineURI to set volume output muted not (output muted of (get volume settings))
	else if name of theObject is "menu-rate" then
		set starRating to title of current menu item of theObject
		set songRating to (starRating * 20)
		using terms from application "iTunes"
			tell application "iTunes" of machine fullMachineURI to set rating of current track to songRating
		end using terms from
	end if
end choose menu item

on will close theObject
	set visible of theObject to false
end will close

on clicked theObject
	set fullMachineURI to "eppc://" & contents of default entry "MachineURI" of user defaults
	if name of theObject is "but-checkupdates" then
		set contents of default entry "SUCheckAtStartup" of user defaults to state of theObject
	else if name of theObject is "but-showprogress" then
		set contents of default entry "ShowProgress" of user defaults to state of theObject
		set visible of progress indicator "pi-dur" of window "win-main" to state of theObject
	else if name of theObject is "but-quit" then
		set contents of default entry "QuitiTunes" of user defaults to state of theObject
	else if name of theObject is "but-update" then
		set contents of default entry "UpdateMoreOften" of user defaults to state of theObject
	else if name of theObject is "but-addplay" then
		set contents of default entry "IncreasePlayCount" of user defaults to state of theObject
	else if name of theObject is "but-up" then
		using terms from application "iTunes"
			tell application "iTunes" of machine fullMachineURI to set sound volume to 100
		end using terms from
		set contents of slider "sl-volume" of window "win-main" to 100
	else if name of theObject is "but-down" then
		using terms from application "iTunes"
			tell application "iTunes" of machine fullMachineURI to set sound volume to 0
		end using terms from
		set contents of slider "sl-volume" of window "win-main" to 0
	else if name of theObject is "but-subscribe" then
		set podcastURL to contents of text field "tf-podcasturl" of window "win-subscribe"
		if podcastURL is not "" then
			using terms from application "iTunes"
				tell application "iTunes" of machine fullMachineURI to subscribe podcastURL
			end using terms from
			close panel (window of theObject)
		else
			close panel (window of theObject)
		end if
	else if name of theObject is "but-close" then
		close panel (window of theObject)
	end if
end clicked
