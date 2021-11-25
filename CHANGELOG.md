# 6.0
## Fixes
## New features
### Common
- Added 'BAD_CONNECTION_REQUEST' event to notify the client application that the params supplied to 'openRoom' method are invalid.
- Added 'getRoom' method to get videocall context data if it is needed while the videocall is running.

### Android
- Updated Twilio Android SDK to 7.0.1
- Added "com.twilio:audioswitch" dependency to handle audio devices easily. Now, bluetooth audio devices work properly.
    - Related to this, we added new project level configuration to use custom names for the audio devices.

### iOS
- Updated Twilio iOS SDK to 4.6.1

## Breaking changes
- Changes on 'openRoom' method
    - Videocall errors are not handled by the plugin anymore. The client app should listen plugin error events and handle them as they consider. Therefore, we have removed the following 'config' parameters:
        - handleErrorInApp
        - i18nConnectionError
        - i18nDisconnectedWithError
        - i18nAccept
    - Changed params order. Have a look at <a href="typings/twiliovideo.d.ts">definitions file</a>.
- Changed videocall event model to add context data about the videocall. Have a look at <a href="typings/twiliovideo.d.ts">definitions file</a>.
