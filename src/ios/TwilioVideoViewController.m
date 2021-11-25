#import "TwilioVideoViewController.h"

@implementation TwilioVideoViewController

static TVIRoom *currentRoom;

#pragma mark - UIViewController

+ (TVIRoom*)getVideocallRoomInstance {
    return currentRoom;
}

- (void)dealloc {
    // We are done with current room
    if (currentRoom) {
        currentRoom = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[TwilioVideoManager getInstance] setActionDelegate:self];

    [[TwilioVideoManager getInstance] publishEvent:[CallEvent of:EVENT_OPENED]];
    [self.navigationController setNavigationBarHidden:YES animated:NO];

    [self logMessage:[NSString stringWithFormat:@"TwilioVideo v%@", [TwilioVideoSDK sdkVersion]]];

    // Configure access token for testing. Create one manually in the console
    // at https://www.twilio.com/console/video/runtime/testing-tools
    self.accessToken = @"TWILIO_ACCESS_TOKEN";

    // Preview our local camera track in the local video preview view.
    [self startPreview];

    // Disconnect and mic button will be displayed when client is connected to a room.
    self.micButton.hidden = YES;
    [self.micButton setImage:[UIImage imageNamed:@"mic"] forState: UIControlStateNormal];
    [self.micButton setImage:[UIImage imageNamed:@"no_mic"] forState: UIControlStateSelected];
    [self.videoButton setImage:[UIImage imageNamed:@"video"] forState: UIControlStateNormal];
    [self.videoButton setImage:[UIImage imageNamed:@"no_video"] forState: UIControlStateSelected];

    // Customize button colors
    NSString *primaryColor = [self.config primaryColorHex];
    if (primaryColor != NULL) {
        self.disconnectButton.backgroundColor = [TwilioVideoConfig colorFromHexString:primaryColor];
    }

    NSString *secondaryColor = [self.config secondaryColorHex];
    if (secondaryColor != NULL) {
        self.micButton.backgroundColor = [TwilioVideoConfig colorFromHexString:secondaryColor];
        self.videoButton.backgroundColor = [TwilioVideoConfig colorFromHexString:secondaryColor];
        self.cameraSwitchButton.backgroundColor = [TwilioVideoConfig colorFromHexString:secondaryColor];
    }
}

#pragma mark - Public

- (void)connectToRoom:(NSString*)room token:(NSString *)token {
    self.roomName = room;
    self.accessToken = token;
    [self showRoomUI:YES];

    [TwilioVideoPermissions requestRequiredPermissions:^(BOOL grantedPermissions) {
         if (grantedPermissions) {
             [self doConnect];
         } else {
             [[TwilioVideoManager getInstance] publishEvent:[CallEvent of:EVENT_PERMISSIONS_REQUIRED]];
             [self handleConnectionError];
         }
    }];
}

- (IBAction)disconnectButtonPressed:(id)sender {
    if ([self.config hangUpInApp]) {
        [[TwilioVideoManager getInstance] publishEvent:[[CallEvent of:EVENT_HANG_UP] withRoomCtx:currentRoom]];
    } else {
        [self onDisconnect];
    }
}

- (IBAction)micButtonPressed:(id)sender {
    // We will toggle the mic to mute/unmute and change the title according to the user action.

    if (self.localAudioTrack) {
        self.localAudioTrack.enabled = !self.localAudioTrack.isEnabled;
        // If audio not enabled, mic is muted and button crossed out
        [self.micButton setSelected: !self.localAudioTrack.isEnabled];
    }
}

- (IBAction)cameraSwitchButtonPressed:(id)sender {
    [self flipCamera];
}

- (IBAction)videoButtonPressed:(id)sender {
    if(self.localVideoTrack){
        self.localVideoTrack.enabled = !self.localVideoTrack.isEnabled;
        [self.videoButton setSelected: !self.localVideoTrack.isEnabled];
    }
}

#pragma mark - Private

- (BOOL)isSimulator {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    return NO;
}

- (void)startPreview {
    // TVICameraCapturer is not supported with the Simulator.
    if ([self isSimulator]) {
        [self.previewView removeFromSuperview];
        return;
    }
    
    AVCaptureDevice *frontCamera = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionFront];
    AVCaptureDevice *backCamera = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionBack];

    if (frontCamera != nil || backCamera != nil) {
        self.camera = [[TVICameraSource alloc] initWithDelegate:self];
        self.localVideoTrack = [TVILocalVideoTrack trackWithSource:self.camera
                                                             enabled:YES
                                                                name:@"Camera"];
        if (!self.localVideoTrack) {
            [self logMessage:@"Failed to add video track"];
        } else {
            // Add renderer to video track for local preview
            [self.localVideoTrack addRenderer:self.previewView];

            [self logMessage:@"Video track created"];

            if (frontCamera != nil && backCamera != nil) {
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(flipCamera)];
                [self.previewView addGestureRecognizer:tap];
                self.cameraSwitchButton.hidden = NO;
            }

            self.videoButton.hidden = NO;

            [self.camera startCaptureWithDevice:frontCamera != nil ? frontCamera : backCamera
                 completion:^(AVCaptureDevice *device, TVIVideoFormat *format, NSError *error) {
                     if (error != nil) {
                         [self logMessage:[NSString stringWithFormat:@"Start capture failed with error.\ncode = %lu error = %@", error.code, error.localizedDescription]];
                     } else {
                         self.previewView.mirror = (device.position == AVCaptureDevicePositionFront);
                     }
            }];
        }
    } else {
       [self logMessage:@"No front or back capture device found!"];
   }
}

- (void)flipCamera {
    AVCaptureDevice *newDevice = nil;

    if (self.camera.device.position == AVCaptureDevicePositionFront) {
        newDevice = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionBack];
    } else {
        newDevice = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionFront];
    }

    if (newDevice != nil) {
        [self.camera selectCaptureDevice:newDevice completion:^(AVCaptureDevice *device, TVIVideoFormat *format, NSError *error) {
            if (error != nil) {
                [self logMessage:[NSString stringWithFormat:@"Error selecting capture device.\ncode = %lu error = %@", error.code, error.localizedDescription]];
            } else {
                self.previewView.mirror = (device.position == AVCaptureDevicePositionFront);
            }
        }];
    }
}

- (void)prepareLocalMedia {

    // We will share local audio and video when we connect to room.

    // Create an audio track.
    if (!self.localAudioTrack) {
        self.localAudioTrack = [TVILocalAudioTrack trackWithOptions:nil
                                                            enabled:YES
                                                               name:@"Microphone"];

        if (!self.localAudioTrack) {
            [self logMessage:@"Failed to add audio track"];
        }
    }

    // Create a video track which captures from the camera.
    if (!self.localVideoTrack) {
        [self startPreview];
    }
}

- (void)doConnect {
    if ([self.accessToken isEqualToString:@"TWILIO_ACCESS_TOKEN"]) {
        [self logMessage:@"Please provide a valid token to connect to a room"];
        return;
    }

    // Prepare local media which we will share with Room Participants.
    [self prepareLocalMedia];

    TVIConnectOptions *connectOptions = [TVIConnectOptions optionsWithToken:self.accessToken
                                                                      block:^(TVIConnectOptionsBuilder * _Nonnull builder) {
                                                                          builder.roomName = self.roomName;
                                                                          // Use the local media that we prepared earlier.
                                                                          builder.audioTracks = self.localAudioTrack ? @[ self.localAudioTrack ] : @[ ];
                                                                          builder.videoTracks = self.localVideoTrack ? @[ self.localVideoTrack ] : @[ ];
                                                                      }];

    // Connect to the Room using the options we provided.
    currentRoom = [TwilioVideoSDK connectWithOptions:connectOptions delegate:self];

    [self logMessage:@"Attempting to connect to room"];
}

- (void)setupRemoteView {
    // Creating `TVIVideoView` programmatically
    TVIVideoView *remoteView = [[TVIVideoView alloc] init];

    // `TVIVideoView` supports UIViewContentModeScaleToFill, UIViewContentModeScaleAspectFill and UIViewContentModeScaleAspectFit
    // UIViewContentModeScaleAspectFit is the default mode when you create `TVIVideoView` programmatically.
    remoteView.contentMode = UIViewContentModeScaleAspectFill;

    [self.view insertSubview:remoteView atIndex:0];
    self.remoteView = remoteView;

    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1
                                                                constant:0];
    [self.view addConstraint:centerX];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1
                                                                constant:0];
    [self.view addConstraint:centerY];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeWidth
                                                            multiplier:1
                                                              constant:0];
    [self.view addConstraint:width];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeHeight
                                                             multiplier:1
                                                               constant:0];
    [self.view addConstraint:height];
}

// Reset the client ui status
- (void)showRoomUI:(BOOL)inRoom {
    self.micButton.hidden = !inRoom;
    [UIApplication sharedApplication].idleTimerDisabled = inRoom;
}

- (void)cleanupRemoteParticipant {
    if (self.remoteParticipant) {
        if ([self.remoteParticipant.videoTracks count] > 0) {
            TVIRemoteVideoTrack *videoTrack = self.remoteParticipant.remoteVideoTracks[0].remoteTrack;
            [videoTrack removeRenderer:self.remoteView];
            [self.remoteView removeFromSuperview];
        }
        self.remoteParticipant = nil;
    }
}

- (void)logMessage:(NSString *)msg {
    NSLog(@"%@", msg);
}

- (void)handleConnectionError {
    [self logMessage: @"Connection error happened. Finishing videocall..."];
    [self dismiss];
}

- (void) dismiss {
    [[TwilioVideoManager getInstance] publishEvent:[CallEvent of:EVENT_CLOSED]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:NO completion:nil];
    });
}

#pragma mark - TwilioVideoActionProducerDelegate

- (void)onDisconnect {
    if (currentRoom != NULL) {
        [currentRoom disconnect];
    }
}

#pragma mark - TVIRoomDelegate

- (void)didConnectToRoom:(nonnull TVIRoom *)room {
    // At the moment, this example only supports rendering one Participant at a time.
    [self logMessage:[NSString stringWithFormat:@"Connected to room %@ as %@", room.name, room.localParticipant.identity]];
    [[TwilioVideoManager getInstance] publishEvent:[[CallEvent of:EVENT_CONNECTED] withRoomCtx:room]];

    if (room.remoteParticipants.count > 0) {
        self.remoteParticipant = room.remoteParticipants[0];
        self.remoteParticipant.delegate = self;
    }
}

- (void)room:(nonnull TVIRoom *)room didFailToConnectWithError:(nonnull NSError *)error {
    [self logMessage:[NSString stringWithFormat:@"Failed to connect to room, error = %@", error]];
    [[TwilioVideoManager getInstance] publishEvent:[[CallEvent of:EVENT_CONNECT_FAILURE withError:error] withRoomCtx:room]];
    currentRoom = nil;

    [self showRoomUI:NO];
    [self handleConnectionError];
}

- (void)room:(nonnull TVIRoom *)room didDisconnectWithError:(nullable NSError *)error {
    [self logMessage:[NSString stringWithFormat:@"Disconnected from room %@, error = %@", room.name, error]];

    [self cleanupRemoteParticipant];
    currentRoom = nil;

    [self showRoomUI:NO];
    if (error != NULL) {
        [[TwilioVideoManager getInstance] publishEvent:[[CallEvent of:EVENT_DISCONNECTED_WITH_ERROR withError:error] withRoomCtx:room]];
        [self handleConnectionError];
    } else {
        [[TwilioVideoManager getInstance] publishEvent:[[CallEvent of:EVENT_DISCONNECTED] withRoomCtx:room]];
        [self dismiss];
    }
}

- (void)room:(nonnull TVIRoom *)room isReconnectingWithError:(nonnull NSError *)error {
    [[TwilioVideoManager getInstance] publishEvent:[[CallEvent of:EVENT_RECONNECTING withError:error] withRoomCtx:room]];
}

- (void)didReconnectToRoom:(nonnull TVIRoom *)room {
    [[TwilioVideoManager getInstance] publishEvent:[[CallEvent of:EVENT_RECONNECTED] withRoomCtx:room]];
}

- (void)room:(nonnull TVIRoom *)room participantDidConnect:(nonnull TVIRemoteParticipant *)participant {
    if (!self.remoteParticipant) {
        self.remoteParticipant = participant;
        self.remoteParticipant.delegate = self;
    }
    [self logMessage:[NSString stringWithFormat:@"Participant %@ connected with %lu audio and %lu video tracks",
                      participant.identity,
                      (unsigned long)[participant.audioTracks count],
                      (unsigned long)[participant.videoTracks count]]];
    [[TwilioVideoManager getInstance] publishEvent:[[CallEvent of:EVENT_PARTICIPANT_CONNECTED] withRoomCtx:room]];
}

- (void)room:(nonnull TVIRoom *)room participantDidDisconnect:(nonnull TVIRemoteParticipant *)participant {
    if (self.remoteParticipant == participant) {
        [self cleanupRemoteParticipant];
    }
    [self logMessage:[NSString stringWithFormat:@"Room %@ participant %@ disconnected", room.name, participant.identity]];
    [[TwilioVideoManager getInstance] publishEvent:[[CallEvent of:EVENT_PARTICIPANT_DISCONNECTED] withRoomCtx:room]];
}


#pragma mark - TVIRemoteParticipantDelegate

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didPublishVideoTrack:(nonnull TVIRemoteVideoTrackPublication *)publication {

    // Remote Participant has offered to share the video Track.

    [self logMessage:[NSString stringWithFormat:@"Participant %@ published %@ video track .",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didUnpublishVideoTrack:(nonnull TVIRemoteVideoTrackPublication *)publication {

    // Remote Participant has stopped sharing the video Track.

    [self logMessage:[NSString stringWithFormat:@"Participant %@ unpublished %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didPublishAudioTrack:(nonnull TVIRemoteAudioTrackPublication *)publication {

    // Remote Participant has offered to share the audio Track.

    [self logMessage:[NSString stringWithFormat:@"Participant %@ published %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didUnpublishAudioTrack:(nonnull TVIRemoteAudioTrackPublication *)publication {

    // Remote Participant has stopped sharing the audio Track.

    [self logMessage:[NSString stringWithFormat:@"Participant %@ unpublished %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)didSubscribeToVideoTrack:(nonnull TVIRemoteVideoTrack *)videoTrack
                     publication:(nonnull TVIRemoteVideoTrackPublication *)publication
                  forParticipant:(nonnull TVIRemoteParticipant *)participant {
    // We are subscribed to the remote Participant's audio Track. We will start receiving the
    // remote Participant's video frames now.

    [self logMessage:[NSString stringWithFormat:@"Subscribed to %@ video track for Participant %@",
                      publication.trackName, participant.identity]];
    [[TwilioVideoManager getInstance] publishEvent:[[CallEvent of:EVENT_REMOTE_VIDEO_TRACK_ADDED] withRoomCtx:currentRoom]];

    if (self.remoteParticipant == participant) {
        [self setupRemoteView];
        [videoTrack addRenderer:self.remoteView];
    }
}

- (void)didUnsubscribeFromVideoTrack:(nonnull TVIRemoteVideoTrack *)videoTrack
                         publication:(nonnull TVIRemoteVideoTrackPublication *)publication
                      forParticipant:(nonnull TVIRemoteParticipant *)participant {

    // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
    // remote Participant's video.

    [self logMessage:[NSString stringWithFormat:@"Unsubscribed from %@ video track for Participant %@",
                      publication.trackName, participant.identity]];
    [[TwilioVideoManager getInstance] publishEvent:[[CallEvent of:EVENT_REMOTE_VIDEO_TRACK_REMOVED] withRoomCtx:currentRoom]];

    if (self.remoteParticipant == participant) {
        [videoTrack removeRenderer:self.remoteView];
        [self.remoteView removeFromSuperview];
    }
}

- (void)didSubscribeToAudioTrack:(nonnull TVIRemoteAudioTrack *)audioTrack
                     publication:(nonnull TVIRemoteAudioTrackPublication *)publication
                  forParticipant:(nonnull TVIRemoteParticipant *)participant {

    // We are subscribed to the remote Participant's audio Track. We will start receiving the
    // remote Participant's audio now.

    [self logMessage:[NSString stringWithFormat:@"Subscribed to %@ audio track for Participant %@",
                      publication.trackName, participant.identity]];
}

- (void)didUnsubscribeFromAudioTrack:(nonnull TVIRemoteAudioTrack *)audioTrack
                         publication:(nonnull TVIRemoteAudioTrackPublication *)publication
                      forParticipant:(nonnull TVIRemoteParticipant *)participant {

    // We are unsubscribed from the remote Participant's audio Track. We will no longer receive the
    // remote Participant's audio.

    [self logMessage:[NSString stringWithFormat:@"Unsubscribed from %@ audio track for Participant %@",
                      publication.trackName, participant.identity]];
}

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didEnableVideoTrack:(nonnull TVIRemoteVideoTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ enabled %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didDisableVideoTrack:(nonnull TVIRemoteVideoTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ disabled %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didEnableAudioTrack:(nonnull TVIRemoteAudioTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ enabled %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didDisableAudioTrack:(nonnull TVIRemoteAudioTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ disabled %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)didFailToSubscribeToAudioTrack:(nonnull TVIRemoteAudioTrackPublication *)publication
                                 error:(nonnull NSError *)error
                        forParticipant:(nonnull TVIRemoteParticipant *)participant {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ failed to subscribe to %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)didFailToSubscribeToVideoTrack:(nonnull TVIRemoteVideoTrackPublication *)publication
                                 error:(nonnull NSError *)error
                        forParticipant:(nonnull TVIRemoteParticipant *)participant {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ failed to subscribe to %@ video track.",
                      participant.identity, publication.trackName]];
}

#pragma mark - TVIVideoViewDelegate

- (void)videoView:(nonnull TVIVideoView *)view videoDimensionsDidChange:(CMVideoDimensions)dimensions {
    NSLog(@"Dimensions changed to: %d x %d", dimensions.width, dimensions.height);
    [self.view setNeedsLayout];
}

#pragma mark - TVICameraSourceDelegate

- (void)cameraSource:(nonnull TVICameraSource *)source didFailWithError:(nonnull NSError *)error {
    [self logMessage:[NSString stringWithFormat:@"Capture failed with error.\ncode = %lu error = %@", error.code, error.localizedDescription]];
}

@end
