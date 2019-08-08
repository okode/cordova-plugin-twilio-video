# cordova-plugin-twilio-video
Cordova Plugin for Twilio Video

## Configuration steps to install the plugin in a Cordova project
- Add this to the 'config.xml' file:
    - In the root node (widget). The spec URL should point to the version you want.
    ```
    <plugin name="cordova-plugin-twilio-video" spec="https://github.com/okode/cordova-plugin-twilio-video" />
    ```

- Add this to the 'package.json' file:
    - In the dependencies section. It should point to the version you want.
    ```
    "cordova-plugin-twilio-video": "https://github.com/okode/cordova-plugin-twilio-video",
    ```

    - In the cordova section.
    ```
      "cordova-plugin-twilio-video": {},
    ```