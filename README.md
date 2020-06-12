# cordova-plugin-twilio-video
Cordova Plugin for Twilio Video

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
The plugin is available in the global scope so it can be invoked like that:

```
window.twiliovideo.openRoom(token, room)
```

### Methods
Have a look at <a href="typings/twiliovideo.d.ts">definitions file</a> where the API is documented.

## Troubleshooting guide

Q: I get compilation errors on Android

A: First, check if your project compiles without this plugin. In that case, verify the plugin version you are using on your project because since 4.0 version we just support Cordova/Capacitor projects that are using Android with AndroidX. Below 4.0 version, take into account that this plugin is not compatible with AndroidX as it uses old Android Support Libraries. In that case, to migrate the plugin code to AndroidX, you can do the following:

- Doing what @neerajsaxena0711 says here if you are working on a Cordova project: https://github.com/okode/cordova-plugin-twilio-video/issues/13#issuecomment-639301160

- Or using Jetifier if you are using this plugin on a Capacitor project:
https://github.com/mikehardy/jetifier


