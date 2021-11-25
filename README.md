# cordova-plugin-twilio-video
Cordova Plugin for Twilio Video SDK.

**⚡️ Works with [Capacitor](https://capacitor.ionicframework.com/).⚡️**

**Important**: This plugin only works on Cordova/Capacitor projects that are using Android with AndroidX. So, if you don't want to have dependency with AndroidX in your Android project for some reason, please use a plugin version earlier than 4.0.

## Installation

### Cordova project
- Add this to the 'package.json'
    - In the dependencies section:
    ```
    "cordova-plugin-twilio-video": "https://github.com/okode/cordova-plugin-twilio-video"
    ```

    - In the cordova plugins section:
    ```
      "cordova-plugin-twilio-video": {}
    ```

### Capacitor project
- Add this dependency to the 'package.json':
    ```
    "cordova-plugin-twilio-video": "https://github.com/okode/cordova-plugin-twilio-video",
    ```

## API

### Usage
The plugin is available in the global scope so you can invoke its API like this:

- Javascript

```Javascript
window.twiliovideo.[METHOD]
```

- Typescript

```Typescript
(window as any).twiliovideo.[METHOD]
```

- Typescript with typings
    - Declare a variable at the top of your Typescript file and import `TwilioVideoPlugin`
    ```Typescript
    declare const twiliovideo: TwilioVideoPlugin;
    ```
    - Invoke the plugin like this in any place of this file
    ```Typescript
    twiliovideo.[METHOD]
    ```

### Methods
Have a look at <a href="typings/twiliovideo.d.ts">definitions file</a> where the API is documented.

### Videocall events
Manage the events emitted by the plugin while the videocall is running.

EVENT LIST
------------
- `BAD_CONNECTION_REQUEST`: fired when the params supplied to 'openRoom' method are invalid. [UNRECOVERABLE STATE(*)].
- `OPENED`: fired when the videocall is opened.
- `CONNECTED`: fired when the videocall is stablished successfully.
- `CONNECT_FAILURE`: fired when the videocall connection fails. [UNRECOVERABLE STATE(*)].
- `DISCONNECTED`: fired when the videocall is disconnected without error.
- `DISCONNECTED_WITH_ERROR`: fired when the videocall is disconnected due to an error. The error data is provided along with the event. [UNRECOVERABLE STATE(*)].
- `RECONNECTING`: fired when the connection was lost and Twilio is trying to reconnect the videocall automatically.
- `RECONNECTED`: fired when the videocall was stablished again after a videocall connection lost.
- `PARTICIPANT_CONNECTED`: fired when a participant gets into the videocall.
- `PARTICIPANT_DISCONNECTED`: fired when a participant leaves the videocall.
- `REMOTE_VIDEO_TRACK_ADDED`: fired when a participant adds a video track to the videocall.
- `REMOTE_VIDEO_TRACK_REMOVED`: fired when a participant removes a video track from the videocall.
- `HANG_UP`: fired when the user presses on the hang up button and the videocall has to be closed explicetly by calling the `closeRoom` method.
- `CLOSED`: fired when the videocall is closed
- `PERMISSIONS_REQUIRED`: fired when the user doesn't grant the required permissions (audio and video) and the videocall cannot be started.

(*): Unrecoverable state means that it is needed to invoke 'openRoom' again to retry the videocall connection. This plugin doesn't manage retries. It would be recommended to show the user an error screen that contains a button to retry the videocall.

## Customization at project level

### Android

- Set custom audio device names if you don't like the default ones.

    Add this lines to the `strings.xml` of your Android project and use the desired string values:

    ```
        <string name="twilio_audio_bluetooth_device_name">Auricular bluetooth</string>
        <string name="twilio_audio_wired_headset_device_name">Auricular con cable</string>
        <string name="twilio_audio_speakerphone_device_name">Altavoz</string>
        <string name="twilio_audio_earpiece_device_name">Auricular del teléfono</string>
    ```
    Note: this example translates audio device names to Spanish.

## Troubleshooting guide

Q: I get compilation errors on Android

A: First, check if your project compiles without this plugin. In that case, verify the plugin version you are using on your project because since 4.0 version we just support Cordova/Capacitor projects that are using Android with AndroidX. Below 4.0 version, take into account that this plugin is not compatible with AndroidX as it uses old Android Support Libraries. In that case, to migrate the plugin code to AndroidX, you can do the following:

- Doing what @neerajsaxena0711 says here if you are working on a Cordova project: https://github.com/okode/cordova-plugin-twilio-video/issues/13#issuecomment-639301160

- Or using Jetifier if you are using this plugin on a Capacitor project:
https://github.com/mikehardy/jetifier


