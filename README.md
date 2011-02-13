# iTRC

fork of [iTunes Remote Control](http://www.them.ws/itrc/) with bug fixes and new features

maintained by [joshua stein](http://jcs.org/)

latest binary download: [https://github.com/downloads/jcs/itrc/iTRC.zip](https://github.com/downloads/jcs/itrc/iTRC.zip)

bug fixes:
	- fixed a bug on machines with no mute/volume controls (when using digital
	  audio output) which caused unrelated errors about undefined variables to
	  popup
	- fixed other bugs that caused error messages to popup and cause iTRC to
	  stop receiving updates

new features:
	- added next album and previous album controls

enhancements:
	- passes identifier to growl to coalesce notifications, so when skipping a
	  bunch of tracks, multiple growl announcements will not backlog on the
	  screen
	- growl notifications show iTunes star ratings for songs that have them


### vim:ts=4:tw=80
