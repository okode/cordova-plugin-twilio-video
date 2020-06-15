# cordova-plugin-twilio-video
Cordova Plugin for Twilio Video

**⚡️ Works with [Capacitor](https://capacitor.ionicframework.com/).⚡️**

**⚡️ CallKit support on [Capacitor projects⚡️](https://capacitor.ionicframework.com/)**

**Important**: This plugin only works on Cordova/Capacitor projects that are using Android with AndroidX. So, if you don't want to have dependency with AndroidX in your Android project for some reason, please use a plugin version earlier than 4.0.

## Installation

### Cordova project
- Add this to the 'package.json'
    - In the 'devDependencies' section:
    ```
    "cordova-plugin-twilio-video": "https://github.com/okode/cordova-plugin-twilio-video"
    ```

    - In the cordova plugins section:
    ```
      "cordova-plugin-twilio-video": {}
    ```

### Capacitor project
- Add this dependency to the 'package.json' in the 'dependencies' section:
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

## CallKit integration
First of all, make your app be able to receive VOIP notifications and once you receive VOIP notifications, follow the next steps. Have a look at Apple documentation and other VOIP plugins in order to add this feature to your project. We didn't add VOIP notifications support into this plugin because we preferred to decouple this integration in order to allow developers to have other integrations with VOIP notifications.

- Report your VOIP notifications to Twilio video plugin setting up the configuration you want for the call. Once this is set up, every time you receive a VOIP notification, this plugin will report the call to CallKit. Example:

```
    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        let incomingCall = TwilioVideoCallKitIncomingCall()
        incomingCall.uuid = UUID.init()
        incomingCall.roomName = payload.dictionaryPayload["roomName"]
        incomingCall.token = payload.dictionaryPayload["token"]
        incomingCall.caller = "MyApp"
        TwilioVideoCallKit.getInstance().reportIncomingCall(with: incomingCall, completion: {
            (error) in
            completion();
        })
    }
```


## Troubleshooting guide

Q: I get compilation errors on Android

A: First, check if your project compiles without this plugin. In that case, verify the plugin version you are using on your project because since 4.0 version we just support Cordova/Capacitor projects that are using Android with AndroidX. Below 4.0 version, take into account that this plugin is not compatible with AndroidX as it uses old Android Support Libraries. In that case, to migrate the plugin code to AndroidX, you can do the following:

- Doing what @neerajsaxena0711 says here if you are working on a Cordova project: https://github.com/okode/cordova-plugin-twilio-video/issues/13#issuecomment-639301160

- Or using Jetifier if you are using this plugin on a Capacitor project:
https://github.com/mikehardy/jetifier



