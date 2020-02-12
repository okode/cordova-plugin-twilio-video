//
//  TwilioVideoViewController.m
//

#import "TwilioVideoViewController.h"

@implementation TwilioVideoViewController

#pragma mark - UIViewController

- (id)init {
    self = [super init];
    return self;
}

- (void)dealloc {
    if (self.call) {
        [self.call stopCamera];
    }
}

- (void)viewDidLoad {
    self.call.delegate = self;
    [[TwilioVideoEventManager getInstance] publishCallEvent: CALL_OPENED];

    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    [self logMessage:[NSString stringWithFormat:@"TwilioVideo v%@", [TwilioVideo version]]];
    
    // Disconnect and mic button will be displayed when client is connected to a room.
    self.micButton.hidden = YES;
    [self.micButton setImage:[UIImage imageNamed:@"mic"] forState: UIControlStateNormal];
    [self.micButton setImage:[UIImage imageNamed:@"no_mic"] forState: UIControlStateSelected];
    [self.videoButton setImage:[UIImage imageNamed:@"video"] forState: UIControlStateNormal];
    [self.videoButton setImage:[UIImage imageNamed:@"no_video"] forState: UIControlStateSelected];
    
    // Customize button colors
    NSString *primaryColor = [self.call.config primaryColorHex];
    if (primaryColor != NULL) {
        self.disconnectButton.backgroundColor = [TwilioVideoConfig colorFromHexString:primaryColor];
    }
    
    NSString *secondaryColor = [self.call.config secondaryColorHex];
    if (secondaryColor != NULL) {
        self.micButton.backgroundColor = [TwilioVideoConfig colorFromHexString:secondaryColor];
        self.videoButton.backgroundColor = [TwilioVideoConfig colorFromHexString:secondaryColor];
        self.cameraSwitchButton.backgroundColor = [TwilioVideoConfig colorFromHexString:secondaryColor];
    }
    
    [self showRoomUI:YES];

    [TwilioVideoPermissions requestRequiredPermissions:^(BOOL grantedPermissions) {
         if (grantedPermissions) {
             [self doConnect];
         } else {
             [[TwilioVideoManager getInstance] publishEvent: PERMISSIONS_REQUIRED];
             [self handleConnectionError: [self.config i18nConnectionError]];
         }
    }];
}

#pragma mark - UI listeners

- (IBAction)disconnectButtonPressed:(id)sender {
    [self.call endCall];
}

- (IBAction)micButtonPressed:(id)sender {
    [self.call performUIMuteAction:self.call.localAudioTrack.enabled];
}

- (IBAction)cameraSwitchButtonPressed:(id)sender {
    [self.call switchCamera];
}

- (IBAction)videoButtonPressed:(id)sender {
    [self.call disableVideo:self.call.localVideoTrack.isEnabled];
}

#pragma mark - Private

- (void)showLocalVideoTrack {
    // TVICameraCapturer is not supported with the Simulator.
    if ([self isSimulator]) {
        [self.previewView removeFromSuperview];
        return;
    }
    
    [self.call connectLocalVideoWithDelegate:self];
    
    if (!self.call.localVideoTrack) {
        [self logMessage:@"Failed to add video track"];
    } else {
        // Add renderer to video track for local preview
        [self.call.localVideoTrack addRenderer:self.previewView];
        
        [self logMessage:@"Video track created"];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self.call
                                                                              action:@selector(switchCamera)];
        
        self.videoButton.hidden = NO;
        self.cameraSwitchButton.hidden = NO;
        [self.previewView addGestureRecognizer:tap];
    }
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
    [self.micButton setSelected:self.call.localAudioTrack ? !self.call.localAudioTrack.isEnabled : false];
    [UIApplication sharedApplication].idleTimerDisabled = inRoom;
}

- (void)setRemoteParticipantDelegate {
    if (self.call.remoteParticipant) {
        self.call.remoteParticipant.delegate = self;
    }
}

- (void)showRemoteParticipantVideoTrack {
    if (self.call.remoteParticipant && [self.call.remoteParticipant.videoTracks count] > 0) {
        TVIRemoteVideoTrack *videoTrack = self.call.remoteParticipant.remoteVideoTracks[0].remoteTrack;
        [self setupRemoteView];
        [videoTrack addRenderer:self.remoteView];
    }
}

- (void)cleanupRemoteParticipant {
    if (self.call.remoteParticipant) {
        if ([self.call.remoteParticipant.videoTracks count] > 0) {
            TVIRemoteVideoTrack *videoTrack = self.call.remoteParticipant.remoteVideoTracks[0].remoteTrack;
            [videoTrack removeRenderer:self.remoteView];
            [self.remoteView removeFromSuperview];
        }
    }
}

- (void)dismiss {
    [[TwilioVideoEventManager getInstance] publishCallEvent: CALL_CLOSED];
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark Utils

- (BOOL)isSimulator {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    return NO;
}

- (void)logMessage:(NSString *)msg {
    NSLog(@"%@", msg);
}

#pragma mark - TwilioVideoCallDelegate

- (void)didConnectToRoom:(TVIRoom *)room {
    [[TwilioVideoEventManager getInstance] publishCallEvent: CALL_CONNECTED];
    [self setRemoteParticipantDelegate];
}

- (void)room:(TVIRoom *)room didDisconnectWithError:(nullable NSError *)error {
    [self cleanupRemoteParticipant];
    [self showRoomUI:false];
    if (error != NULL) {
        [[TwilioVideoEventManager getInstance] publishCallEvent:CALL_DISCONNECTED_WITH_ERROR with:@{ @"code": [NSString stringWithFormat:@"%ld",[error code]] }];
    } else {
        [[TwilioVideoEventManager getInstance] publishCallEvent: CALL_DISCONNECTED];
    }
    [self dismiss];
}

- (void)room:(TVIRoom *)room didFailToConnectWithError:(nonnull NSError *)error{
    [self showRoomUI:NO];
    [[TwilioVideoEventManager getInstance] publishCallEvent: CALL_CONNECT_FAILURE];
    [self dismiss];
}

- (void)room:(TVIRoom *)room participantDidConnect:(TVIRemoteParticipant *)participant {
    [self setRemoteParticipantDelegate];
    [[TwilioVideoEventManager getInstance] publishCallEvent: CALL_PARTICIPANT_CONNECTED];
}

- (void)room:(TVIRoom *)room participantDidDisconnect:(TVIRemoteParticipant *)participant {
    [self cleanupRemoteParticipant];
    [[TwilioVideoEventManager getInstance] publishCallEvent: CALL_PARTICIPANT_DISCONNECTED];
}

- (void)audioChanged:(BOOL)isMuted {
    [self.micButton setSelected: isMuted];
}

- (void)videoChanged:(BOOL)isDisabled {
    [self.videoButton setSelected: isDisabled];
}

#pragma mark - TVIRemoteParticipantDelegate

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
      publishedVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    
    // Remote Participant has offered to share the video Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ published %@ video track .",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
    unpublishedVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    
    // Remote Participant has stopped sharing the video Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ unpublished %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
      publishedAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    
    // Remote Participant has offered to share the audio Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ published %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
    unpublishedAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    
    // Remote Participant has stopped sharing the audio Track.
    
    [self logMessage:[NSString stringWithFormat:@"Participant %@ unpublished %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)subscribedToVideoTrack:(TVIRemoteVideoTrack *)videoTrack
                   publication:(TVIRemoteVideoTrackPublication *)publication
                forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are subscribed to the remote Participant's audio Track. We will start receiving the
    // remote Participant's video frames now.
    
    [self logMessage:[NSString stringWithFormat:@"Subscribed to %@ video track for Participant %@",
                      publication.trackName, participant.identity]];
    
    [[TwilioVideoEventManager getInstance] publishCallEvent: CALL_VIDEO_TRACK_ADDED];

    if (self.call.remoteParticipant == participant) {
        [self setupRemoteView];
        [videoTrack addRenderer:self.remoteView];
    }
}

- (void)unsubscribedFromVideoTrack:(TVIRemoteVideoTrack *)videoTrack
                       publication:(TVIRemoteVideoTrackPublication *)publication
                    forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
    // remote Participant's video.
    
    [self logMessage:[NSString stringWithFormat:@"Unsubscribed from %@ video track for Participant %@",
                      publication.trackName, participant.identity]];
    
    [[TwilioVideoEventManager getInstance] publishCallEvent: CALL_VIDEO_TRACK_REMOVED];
    
    if (self.call.remoteParticipant == participant) {
        [videoTrack removeRenderer:self.remoteView];
        [self.remoteView removeFromSuperview];
    }
}

- (void)subscribedToAudioTrack:(TVIRemoteAudioTrack *)audioTrack
                   publication:(TVIRemoteAudioTrackPublication *)publication
                forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are subscribed to the remote Participant's audio Track. We will start receiving the
    // remote Participant's audio now.
    
    [self logMessage:[NSString stringWithFormat:@"Subscribed to %@ audio track for Participant %@",
                      publication.trackName, participant.identity]];
    
    [[TwilioVideoEventManager getInstance] publishCallEvent: CALL_AUDIO_TRACK_ADDED];
}

- (void)unsubscribedFromAudioTrack:(TVIRemoteAudioTrack *)audioTrack
                       publication:(TVIRemoteAudioTrackPublication *)publication
                    forParticipant:(TVIRemoteParticipant *)participant {
    
    // We are unsubscribed from the remote Participant's audio Track. We will no longer receive the
    // remote Participant's audio.
    
    [self logMessage:[NSString stringWithFormat:@"Unsubscribed from %@ audio track for Participant %@",
                      publication.trackName, participant.identity]];
    
    [[TwilioVideoEventManager getInstance] publishCallEvent: CALL_AUDIO_TRACK_REMOVED];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
        enabledVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ enabled %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
       disabledVideoTrack:(TVIRemoteVideoTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ disabled %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
        enabledAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ enabled %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(TVIRemoteParticipant *)participant
       disabledAudioTrack:(TVIRemoteAudioTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ disabled %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)failedToSubscribeToAudioTrack:(TVIRemoteAudioTrackPublication *)publication
                                error:(NSError *)error
                       forParticipant:(TVIRemoteParticipant *)participant {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ failed to subscribe to %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)failedToSubscribeToVideoTrack:(TVIRemoteVideoTrackPublication *)publication
                                error:(NSError *)error
                       forParticipant:(TVIRemoteParticipant *)participant {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ failed to subscribe to %@ video track.",
                      participant.identity, publication.trackName]];
}

#pragma mark - TVICameraCapturerDelegate

- (void)cameraCapturer:(TVICameraCapturer *)capturer didStartWithSource:(TVICameraCaptureSource)source {
    self.previewView.mirror = (source == TVICameraCaptureSourceFrontCamera);
}

#pragma mark - TwilioVideoActionProducerDelegate

- (void)onDisconnect {
    [self.call endCall];
}

@end
