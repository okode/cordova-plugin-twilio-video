# cordova-plugin-twilio-video
Cordova Plugin for Twilio Video

## Configuration steps to install the plugin in a Cordova project
- Add this to the 'config.xml' file:
    - In the root node (widget). The spec URL should point to the version you want.
    ```
    <plugin name="cordova-plugin-twilio-video" spec="https://github.com/okode/cordova-plugin-twilio-video#develop" />
    ```

    - In the iOS platform node (platform name="ios"). This allows you to install the Twilio iOS SDK by cocoapods instead of having the SDK versioned along with the project (bad practice).
    ```
    // Inside iOS platform
    <preference name="deployment-target" value="9.0" />
    <pods-config ios-min-version="9.0" />
    <pod name="TwilioVideo" version="2.0.0" />
    ```

- Add this to the 'package.json' file:
    - In the dependencies section. It should point to the version you want.
    ```
    "cordova-plugin-twilio-video": "https://github.com/okode/cordova-plugin-twilio-video#develop",
    "cordova-plugin-cocoapod-support": "1.5.0"
    ```

    - In the cordova section.
    ```
      "cordova-plugin-twilio-video": {},
      "cordova-plugin-cocoapod-support": {}
    ```