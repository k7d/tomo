# Changelog

## 4.1.1

- Fix status bar staying stuck at 0:00 when timer chains to next timer while app is unfocused

## 4.1.0

- Fix menu bar timer not updating when app is unfocused on macOS Tahoe
- Move status bar timer tick to native Swift to avoid Flutter engine throttling
- Render status bar item using button image instead of custom NSView subview
- Adjust menu bar item color brightness and text positioning

## 4.0.2

- Bump flutter dependencies
- Add local config for specifying Apple development team
- Upgrade AppDelegate

## 4.0.1

- Initial public release