declare module TwilioVideo {
    interface TwilioVideoPlugin {
        /**
         * It opens Twilio Video controller and tries to start the videocall.
         * All videocall UI controls will be positioned on the current view, so we can put
         * our own controls from the application that uses the plugin.
         * @param token 
         * @param roomName 
         * @param onEvent - (Optional) It will be fired any time that a call event is received
         * @param {Object} config
         * @param config.primaryColor - Hex primary color that the app will use
         * @param config.secondaryColor - Hex secondary color that the app will use
         */
        openRoom(token: string, roomName: string, onEvent?: Function, config?: any): void;
    }
}

declare var TwilioVideo: TwilioVideo.TwilioVideoPlugin;
