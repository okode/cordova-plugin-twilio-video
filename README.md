# cordova-plugin-twilio-video
Cordova Plugin for Twilio Video

**⚡️ Works with [Capacitor](https://capacitor.ionicframework.com/).⚡️**

**⚡️ CallKit support on [Capacitor projects⚡️](https://capacitor.ionicframework.com/)**

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

Q: I get this compilation error on Android
```
ERROR: Manifest merger failed : Attribute application@appComponentFactory value=(android.support.v4.app.CoreComponentFactory) from [com.android.support:support-compat:28.0.0] AndroidManifest.xml:22:18-91
```
A: First, check if your project compiles without this plugin. In that case, verify that any of your transitive dependencies bring AndroidX library because this plugin is not compatible with AndroidX as it uses old Android Support Libraries. At this moment, most Cordova plugins don't use AndroidX library so when Cordova forces plugins community to use AndroidX, we will do it. Anyway, if it is a requirement to compile with AndroiX, try <a href="https://github.com/mikehardy/jetifier">Jetifier<a>.


