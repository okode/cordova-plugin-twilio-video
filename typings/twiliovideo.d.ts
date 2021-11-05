declare module TwilioVideo {
  interface TwilioVideoPlugin {
    /**
     * It opens Twilio Video controller and tries to start the videocall.
     * All videocall UI controls will be positioned on the current view, so we can put
     * our own controls from the application that uses the plugin.
     * @param token
     * @param roomName
     * @param onEvent - (Optional) It will be fired any time that a call event is received
     * @param {Object} config - (Optional) Call configuraiton
     * @param config.primaryColor - Hex primary color that the app will use
     * @param config.secondaryColor - Hex secondary color that the app will use
     * @param config.hangUpInApp - (Default = false) Flag to indicate the application should hang up the call by calling 'closeRoom'
     * @param config.disableBackButton - (Only Android) (Default = false) Flag to disable back button
     */
    openRoom(token: string, roomName: string, onEvent?: Function, config?: any): void;

    /**
     * It closes the videocall room if it is running
     */
    closeRoom(): Promise<void>;

    /**
     * Check if the user granted all required permissions (Camera and Microphone)
     * @return If user has granted all permissions or not
     */
    hasRequiredPermissions(): Promise<boolean>;

    /**
     * Request required permissions (Camera and Microphone)
     * @return If user has granted all permissions or not
     */
    requestPermissions(): Promise<boolean>;
  }
}

declare var twiliovideo: TwilioVideo.TwilioVideoPlugin;
