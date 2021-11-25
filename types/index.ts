export interface TwilioVideoPlugin {
  /**
   * It opens a native Twilio Video controller and tries to start the videocall with the provided
   * configuration. All native videocall UI controls will be positioned above the current web view
   * by using a transparent native layout. In this way, we can put our own controls from the web
   * application that uses this plugin.
   *
   * @param token
   * @param roomName
   * @param {TwilioVideoAppConfig} config - (Optional) Videocall configuration.
   * @param {Callback} onEvent - (Optional) It will be fired any time that a videocall event is sent from the plugin.
   */
  openRoom(
    token: string,
    roomName: string,
    config?: TwilioVideoAppConfig,
    onEvent?: (event: TwilioVideoAppEvent) => void
  ): void;

  /**
   * It closes the videocall room if it is running
   */
  closeRoom(): Promise<void>;

  /**
   * It returns basic info of the running twilio video room
   */
  getRoom(): Promise<TwilioVideoAppRoom>;

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

export interface TwilioVideoAppConfig {
  /**
   * Hex primary brand color for your project. It will be used to customize the videocall experience.
   */
  primaryColor: string;
  /**
   * Hex secondary brand color for your project.  It will be used to customize the videocall experience.
   */
  secondaryColor?: string;
  /**
   * (Default = false) Flag to handle videocall close from web side by explicitly calling 'closeRoom'.
   * Example: Useful when it is needed to invoke a backend service before closing the Twilio videocall.
   */
  hangUpInApp?: boolean;
  /**
   * (Only Android) (Default = false) Flag to disable back button while the videocall is running.
   */
  disableBackButton?: boolean;
}

export interface TwilioVideoAppEvent {
  eventId: 'BAD_CONNECTION_REQUEST' | 'OPENED' | 'CONNECTED' | 'CONNECT_FAILURE' | 'DISCONNECTED' |
           'DISCONNECTED_WITH_ERROR' | 'RECONNECTING' | 'RECONNECTED' | 'PARTICIPANT_CONNECTED' |
           'PARTICIPANT_DISCONNECTED' | 'REMOTE_VIDEO_TRACK_ADDED' | 'REMOTE_VIDEO_TRACK_REMOVED' |
           'HANG_UP' | 'CLOSED' | 'PERMISSIONS_REQUIRED';
  room?: TwilioVideoAppRoom;
  error?: TwilioVideoAppError;
}

export interface TwilioVideoAppRoom {
  sid?: string;
  localParticipant?: TwilioVideoAppParticipant;
  remoteParticipants: TwilioVideoAppParticipant[];
  /**
   * (Android) It's a string
   * (iOS) It's a number
   */
  state?: string | number;
}

export interface TwilioVideoAppParticipant {
  sid?: string;
  /**
   * (Android) It's a string
   * (iOS) It's a number
   */
  networkQualityLevel?: string | number;
  /**
   * (Android) It's a string
   * (iOS) It's a number
   */
  state?: string | number;
  audioTracks?: TwilioVideoAppTrack[];
  videoTracks?: TwilioVideoAppTrack[];
}

export interface TwilioVideoAppTrack {
  sid?: string;
  /**
   * (Android) It's a string
   * (iOS) It's a number
   */
  name?: string;
  /**
   * (Android) It's a string
   * (iOS) It's a number
   */
  isEnabled?: boolean;
}

export interface TwilioVideoAppError {
  code?: number;
  message?: string;
}