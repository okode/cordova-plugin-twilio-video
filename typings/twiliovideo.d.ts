declare module TwilioVideo {
  interface TwilioVideoPlugin {
    /**
     * It opens a native Twilio Video controller and tries to start the videocall with the provided
     * configuration. All native videocall UI controls will be positioned above the current web view
     * by using a transparent native layout. In this way, we can put our own controls from the web
     * application that uses this plugin.
     *
     * @param token
     * @param roomName
     * @param {Object} config - (Optional) Videocall configuration.
     * @param config.primaryColor - Hex primary brand color for your project.
     * @param config.secondaryColor - Hex secondary brand color for your project.
     * @param config.hangUpInApp - (Default = false) Flag to handle videocall close from web side by explicitly calling 'closeRoom'.
     *                              Example: Useful when it is needed to invoke a backend service before closing the Twilio videocall.
     * @param config.disableBackButton - (Only Android) (Default = false) Flag to disable back button while the videocall is running.
     * @param {Callback} onEvent - (Optional) It will be fired any time that a videocall event is received.
     */
    openRoom(
      token: string,
      roomName: string,
      config?: any,
      onEvent?: (event: { name: string, data?: any }) => void
    ): void;

    /**
     * It closes the videocall room if it is running
     */
    closeRoom(): Promise<void>;

    /**
     * It returns basic info of the running twilio video room
     */
    getRoom(): Promise<{
      localParticipant?: {
        networkQualityLevel?: string | number;
        state?: string | number;
      };
      remoteParticipants: {
        networkQualityLevel?: string | number;
        state?: string | number;
      }[];
      state?: string | number;
    }>;

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
