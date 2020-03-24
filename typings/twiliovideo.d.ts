declare module TwilioVideo {
  interface TwilioVideoPlugin {

    /**
     * @callback callEventCallback
     * 
     * @param event - Event name
     * 
     *  - Fired when the videocall view is presented
     * CONNECTED - Fired when the call is connected
     * CONNECT_FAILURE - Fired when the call cannot be connected
     * DISCONNECTED - Fired when the call is disconnected
     * DISCONNECTED_WITH_ERROR - Fired when it happens an error and the call is disconnected
     * RECONNECTING - (Only Android) Fired when the call is reconnecting
     * RECONNECTOPENEDED - (Only Android) Fired when the call is reconnected
     * PARTICIPANT_CONNECTED - Fired when a remote participant joins the call
     * PARTICIPANT_DISCONNECTED - Fired when a remote participant leaves the call
     * AUDIO_TRACK_ADDED - Fired when the remote audio is added
     * AUDIO_TRACK_REMOVED - Fired when the remote audio is removed
     * VIDEO_TRACK_ADDED - Fired when the remote video is added
     * VIDEO_TRACK_REMOVED - Fired when the remote video is removed
     * HANG_UP - Fired when the user hangs up the call and this was configured to be hanged up manually
     *           by "hangUpInApp" config param
     * PERMISSIONS_REQUIRED - Fired when the user didn't grant the required permissions for the call
     * CLOSED - Fired when the videocall view is dismissed
     *
     * @param data - Event call context data
     */

    /**
     * It opens Twilio Video controller and tries to start the videocall.
     * All videocall UI controls will be positioned on the current view, so we can put
     * our own controls from the application that uses the plugin.
     * 
     * @param token 
     * @param roomName 
     * @param {callEventCallback} [onEvent] - It will be fired any time that a call event is received
     * @param [config] - Call configuration
     * @param config.primaryColor - Hex primary color that the app will use
     * @param config.secondaryColor - Hex secondary color that the app will use
     * @param config.hangUpInApp - (Default = false) Flag to indicate the application should hang up the call by calling 'closeRoom'
     * @param config.businessId - (Only iOS) Business ID for the call.
     *                            It should be used if you want to ignore a CallKit incoming call with the same business ID
     */
    openRoom(token: string, roomName: string, onEvent?: (event: string, data?: any) => void, config?: any): void;

    /**
     * It closes the videocall room if it is running
     * 
     * @param [callUUID] - (Only iOS) Call UUID. If not set, the in-progress call will be closed.
     */
    closeRoom(callUUID?: string): Promise<void>;

    /**
     * @callback displayIncomingCallErrorCallback
     * 
     * @param err - Error data
     */

    /**
     * (Only iOS) It opens Twilio Video controller and starts the video of a CallKit incoming call by UUID.
     * All videocall UI controls will be positioned on the current view, so we can put
     * our own controls from the application that uses the plugin.
     * 
     * @param uuid - Call UUID that will be shown
     * @param {callEventCallback} [onEvent] - It will be fired any time that a call event is received
     * @param {displayIncomingCallErrorCallback} [onError] - It will be fired any time that there is an error
     */
    displayIncomingCall(callUUID: string, onEvent?: (event: string, data?: any) => void, onError?: (err: any) => void): void;

    /**
     * @callback addListenerEventCallback
     * 
     * @param eventName - Event name
     * 
     * twiliovideo.incomingcall.loading - Fired when the call is answered and is connecting
     * twiliovideo.incomingcall.success - Fired when the call was connected successfully
     * twiliovideo.incomingcall.error - Fired when it happens an error connecting the call
     * twiliovideo.videorequested - Fired when the user requested to have a videocall from callkit view
     * twiliovideo.callhangup -  Fired when the user hangs up a callkit call and this was configured to be hanged up manually
     *                           by "hangUpInApp" config param
     * twiliovideo.calldisconnected - Fired when the call is disconnected
     * 
     * @param eventData - Call context data
     */

    /**
     * (Only iOS) Allows you to register a plugin event listener. Global plugin events will be recieved through this listener.
     *
     * @param {addListenerEventCallback} eventCallback 
     */
    addListener(eventCallback: (eventName: string, eventData: any) => void);

    /**
     * Check if the user granted all required permissions (Camera and Microphone)
     * 
     * @return If user has granted all permissions or not
     */
    hasRequiredPermissions(): Promise<boolean>;

    /**
     * Request required permissions (Camera and Microphone)
     * 
     * @return If user has granted all permissions or not
     */
    requestPermissions(): Promise<boolean>;
  }
}

declare var twiliovideo: TwilioVideo.TwilioVideoPlugin;
