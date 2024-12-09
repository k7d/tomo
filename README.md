# Tomo

Tomo is a desktop timer app, primarily intended for the [Pomodoro technique](https://en.wikipedia.org/wiki/Pomodoro_Technique).

<img src="images/tomo@2x.png" alt="Tomo" width="480"/>

<img src="images/timer@2x.png" alt="Timer" width="480"/>

<img src="images/settings@2x.png" alt="Settings" width="480"/>

<img src="images/timer-settings@2x.png" alt="Timer Settings" width="480"/>

## Features

* Access app and see current timer progress via system menubar
* Pause, extend or restart timer
* See daily total time for each timer
* Configure multiple timers with dependencies
* Configure completion sound effects
* Realtime sync of timer config, current state and history across multiple devices

## Implementation

Tomo is written in Dart using Flutter. At the moment only MacOS is supported, although it should't be too difficult to add support for other platforms.

Synchronization is implemented using Firebase. To enabled it, you need to configure Firebase first (see below).

## Running the app in development mode

1. Open `macos/Runner.xcodeproj` in Xcode, select `Runner` target and configure team.
2. Run `flutter run` from the root directory.

## Building the app

```sh
flutter build macos
```

Build results can be found in `macos/build/Release/`.

## Configuring Firebase

This is optional step which enables syncing timer config, current state and history between multiple devices.

1. Run `flutterfire configure`
2. Answer `y` to `? Generated FirebaseOptions file /Users/kaspars/projects/tomox/tomo/lib/firebase_options.dart already exists, do you want to override it?`
3. Select `<create a new project>`
4. Enter your choosen project ID (at least 6 characters)
5. Select `macos` for `? Which platforms should your configuration support (use arrow keys & space to select)? `
6. Go to [Firebase console](https://console.firebase.google.com/) > Authentication and enable Google provider.
7. Rerun `flutterfire configure` (this will update `GoogleService-Info.plist`)
8. Lookup `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` and add it as a new URL scheme to `macos/Runner/Info.plist`:

    ```xml
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>REVERSED_CLIENT_ID</string>
            </array>
        </dict>
    </array>
    ```
