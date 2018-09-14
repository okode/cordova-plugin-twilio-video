declare module TwilioVideo {
    interface TwilioVideoPlugin {
        /**
         * It opens Twilio Video controller and tries to start the videocall.
         * All videocall UI controls will be positioned on the current view, so we can put
         * our own controls from the application that uses the plugin.
         * @param token 
         * @param roomName 
         * @param onEvent - (Optional) It will be fired any time that a call event is received
         */
        openRoom(token: string, roomName: string, onEvent?: Function): void;
    }
}

declare var TwilioVideo: TwilioVideo.TwilioVideoPlugin;
