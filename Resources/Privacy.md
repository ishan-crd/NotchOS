# Privacy Policy

**Last updated: 22 August 2026**

NotchOS does not collect, store, transmit, or sell any personal information. There
are no analytics, no tracking, no advertising identifiers, and no accounts.

## What stays on your Mac

Everything. The following data is processed entirely on-device and never leaves it:

- **Dropped files** — files you drag onto the notch are copied into the app's own
  sandbox container and deleted automatically after the retention period you choose
  in Settings. They are never uploaded anywhere.
- **Quick notes** — stored locally in the app's preferences.
- **Calendar events** — read from the system Calendar via EventKit, purely to show
  today's events in the notch. Events are displayed and discarded; nothing is copied
  out or retained.
- **Now playing information** — track title, artist, album, and playback position are
  read from Spotify or Apple Music via AppleScript in order to display them. Nothing
  is logged or stored.
- **Preferences** — language, appearance, and retention settings are stored in
  standard macOS user defaults.

## Network access

NotchOS makes network requests for exactly one purpose: downloading album artwork
from the artwork URL that Spotify provides for the currently playing track. Requests
go to Spotify's artwork servers only. No identifying information is attached, and no
other network connections are made.

## Permissions NotchOS asks for

- **Calendar** — to display your upcoming events. Decline and the rest of the app
  works normally.
- **Automation (Apple Events)** — limited to Spotify and Apple Music, to read the
  current track and send play/pause/skip commands. NotchOS cannot control any other
  application.

## Third parties

NotchOS uses no third-party analytics, crash reporting, or advertising SDKs.

## Contact

Questions about this policy: ishangupta3121@gmail.com

Source code: https://github.com/ishan-crd/NotchOS
