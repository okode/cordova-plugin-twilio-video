# cordova-plugin-twilio-video
Cordova Plugin for Twilio Video

**⚡️ Works with [Capacitor](https://capacitor.ionicframework.com/).⚡️**


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

Q: I get this compilation error on Android
```
ERROR: Manifest merger failed : Attribute application@appComponentFactory value=(android.support.v4.app.CoreComponentFactory) from [com.android.support:support-compat:28.0.0] AndroidManifest.xml:22:18-91
```
A: First, check if your project compiles without this plugin. In that case, verify that any of your transitive dependencies bring AndroidX library because this plugin is not compatible with AndroidX as it uses old Android Support Libraries. At this moment, most Cordova plugins don't use AndroidX library so when Cordova forces plugins community to use AndroidX, we will do it. Anyway, if it is a requirement to compile with AndroiX, try <a href="https://github.com/mikehardy/jetifier">Jetifier<a>.

