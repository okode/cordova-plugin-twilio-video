//
//  TwilioVideoViewController.m
//

#import "TwilioVideoCall.h"

NSString *const CALL_OPENED = @"OPENED";
NSString *const CALL_CONNECTED = @"CONNECTED";
NSString *const CALL_CONNECT_FAILURE = @"CONNECT_FAILURE";
NSString *const CALL_DISCONNECTED = @"DISCONNECTED";
NSString *const CALL_DISCONNECTED_WITH_ERROR = @"DISCONNECTED_WITH_ERROR";
NSString *const CALL_RECONNECTING = @"RECONNECTING";
NSString *const CALL_RECONNECTED = @"RECONNECTED";
NSString *const CALL_PARTICIPANT_CONNECTED = @"PARTICIPANT_CONNECTED";
NSString *const CALL_PARTICIPANT_DISCONNECTED = @"PARTICIPANT_DISCONNECTED";
NSString *const CALL_AUDIO_TRACK_ADDED = @"AUDIO_TRACK_ADDED";
NSString *const CALL_AUDIO_TRACK_REMOVED = @"AUDIO_TRACK_REMOVED";
NSString *const CALL_VIDEO_TRACK_ADDED = @"VIDEO_TRACK_ADDED";
NSString *const CALL_VIDEO_TRACK_REMOVED = @"VIDEO_TRACK_REMOVED";
NSString *const CALL_PERMISSIONS_REQUIRED = @"PERMISSIONS_REQUIRED";
NSString *const CALL_CLOSED = @"CLOSED";

@implementation TwilioVideoCall

- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class TwilioVideoCall"
                                 userInfo:nil];
    return nil;
}

- (id)initWithUUID:(NSUUID*)uuid room:(NSString*)roomName token:(NSString*)token isCallKitCall:(BOOL)isCallKitCall {
    self.callUuid = uuid;
    self.accessToken = token;
    self.roomName = roomName;
    self.isCallKitCall = isCallKitCall;
    self.config = [[TwilioVideoConfig alloc] init];
    self.callKitCallController = [[CXCallController alloc] init];
    self.endCallSubscribers = [NSMutableArray new];
    self.callState = Initial;
    return self;
}

- (void)connectToRoom:(void (^)(BOOL, NSError *))completion {
    self.connectionCompletionHandler = completion;
    [self doConnect];
    // Registering custom actions delegate
    [[TwilioVideoEventManager getInstance] setActionDelegate:self];
}

- (void)endCall {
    [self endCall: nil];
}

- (void)endCall:(void (^)(void))completion {
    if (!self.room) {
        completion();
        return;
    }
    if (!self.isEndCallEventSent && self.config.hangUpInApp) {
        [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.callhangup" with:[self getMetadata]];
        self.isEndCallEventSent = true;
    } else if (!self.isEndCallNotifiedToCallKit && self.isCallKitCall) {
        [self performCallKitEndCallAction:^(NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"Call ended anyway");
                [self disconnectRoom:completion];
            } else {
                [self addEndCallSubscriber:completion];
            }
        }];
    } else {
        [self disconnectRoom:completion];
    }
}

- (void)muteAudio:(BOOL)isMuted {
    if (!self.isMuteActionNotifiedToCallKit && self.isCallKitCall) {
        [self performCallKitMuteAction:isMuted with:^(NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"Mute call anyway");
                [self setAudioState:isMuted];
            } else {
                NSLog(@"Call muted");
            }
        }];
    } else {
        [self setAudioState:isMuted];
    }
}

- (void)switchCameraWithRenderer:(nonnull TVIVideoView*)view {
    if (!self.camera) { return; }
    
    AVCaptureDevice *newDevice = nil;
    
    if (self.camera.device.position == AVCaptureDevicePositionFront) {
        newDevice = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionBack];
    } else {
        newDevice = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionFront];
    }
    
    if (newDevice != nil) {
        [self.camera selectCaptureDevice:newDevice completion:^(AVCaptureDevice *device, TVIVideoFormat *format, NSError *error) {
            if (error != nil) {
                [TwilioVideoUtils logMessage:[NSString stringWithFormat:@"Error selecting capture device.\ncode = %lu error = %@", error.code, error.localizedDescription]];
            } else {
                view.mirror = (device.position == AVCaptureDevicePositionFront);
            }
        }];
    }

}

- (void)stopCamera {
    if (!self.camera) { return; }
    [self.camera stopCapture];
    self.camera = nil;
}

- (void)disableVideo:(BOOL)isDisabled {
    if (!self.localVideoTrack) { return; }
    self.localVideoTrack.enabled = !isDisabled;
    if (self.delegate) { [self.delegate videoChanged:isDisabled]; }
}

- (BOOL)connectLocalVideoWithRenderer:(nonnull TVIVideoView*)view
    delegate:(nullable id<TVICameraSourceDelegate>)delegate {
    // Set local video track
    AVCaptureDevice *frontCamera = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionFront];
    AVCaptureDevice *backCamera = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionBack];
    
    if (frontCamera != nil || backCamera != nil) {
        self.camera = [[TVICameraSource alloc] initWithDelegate:delegate];
        self.localVideoTrack = [TVILocalVideoTrack trackWithSource:self.camera
                                                             enabled:YES
                                                                name:@"Camera"];
        if (!self.localVideoTrack) {
            NSLog(@"Failed to add video track");
            return false;
        } else {
            NSLog(@"Video track created");
            
            // Add renderer to video track for local preview
            [self.localVideoTrack addRenderer:view];

            if (frontCamera != nil && backCamera != nil) { self.hasFrontAndBackCameraReady = true; }
                        
            [self.camera startCaptureWithDevice:frontCamera != nil ? frontCamera : backCamera
                 completion:^(AVCaptureDevice *device, TVIVideoFormat *format, NSError *error) {
                     if (error != nil) {
                         [TwilioVideoUtils logMessage:[NSString stringWithFormat:@"Start capture failed with error.\ncode = %lu error = %@", error.code, error.localizedDescription]];
                     } else {
                         view.mirror = (device.position == AVCaptureDevicePositionFront);
                     }
            }];

            // Publish video if room is already created/connected
            if (self.room && self.room.localParticipant) {
                [self.room.localParticipant publishVideoTrack:self.localVideoTrack];
            }
            
            return true;
        }
    } else {
        NSLog(@"No front or back capture device found!");
        return false;
   }

}

- (NSDictionary*)getMetadata {
    return @{
        @"callUUID": [self.callUuid UUIDString],
        @"businessId": self.businessId ? self.businessId : [NSNull new],
        @"extras": self.extras ? self.extras : [NSNull new]
    };
}

#pragma mark Private

- (void)createLocalAudio {
    // Set local audio track
    self.localAudioTrack = [TVILocalAudioTrack trackWithOptions:nil
                                                        enabled:YES
                                                            name:@"Microphone"];
}

- (void)doConnect {
    [self createLocalAudio];
    TVIConnectOptions *connectOptions = [TVIConnectOptions optionsWithToken:self.accessToken block:^(TVIConnectOptionsBuilder * _Nonnull builder) {
        {
            builder.roomName = self.roomName;
            // The CallKit UUID to assoicate with this Room.
            if (self.callUuid != nil) {
                builder.uuid = self.callUuid;
            }
            // Use the local media that we prepared earlier.
            builder.audioTracks = self.localAudioTrack ? @[ self.localAudioTrack ] : @[ ];
            builder.videoTracks = self.localVideoTrack ? @[ self.localVideoTrack ] : @[ ];
        }
    }];
    // Connect to the Room using the options we provided.
    self.callState = Connecting;
    self.room = [TwilioVideoSDK connectWithOptions:connectOptions delegate:self];
}

- (void)performCallKitEndCallAction:(void (^)(NSError *_Nullable error))completion {
    CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:self.callUuid];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];
    [self.callKitCallController requestTransaction:transaction completion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"EndCallAction transaction request failed: %@", error.localizedDescription);
        } else {
            NSLog(@"EndCallAction transaction request successful");
        }
        if (completion) { completion(error); }
    }];
}

- (void)addEndCallSubscriber:(void (^)(void))completion {
    if (completion == nil) { return; }
    [self.endCallSubscribers addObject:completion];
}

- (void)notifyEndCallSubscribers {
    for (int i = 0; i < [self.endCallSubscribers count]; i++) {
        [self.endCallSubscribers objectAtIndex:i]();
    }
    [self.endCallSubscribers removeAllObjects];
}
        
- (void)disconnectRoom:(void (^)(void))completion {
    [self addEndCallSubscriber:completion];
    if (!self.room) {
        [self notifyEndCallSubscribers];
        return;
    }
    [self.room disconnect];
}

- (void)performCallKitMuteAction:(BOOL)isMuted with:(void (^)(NSError *_Nullable error))completion {
    CXSetMutedCallAction *muteAction = [[CXSetMutedCallAction alloc] initWithCallUUID:self.callUuid muted:isMuted];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:muteAction];

    [self.callKitCallController requestTransaction:transaction completion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"CXSetMutedCallAction transaction request failed: %@", error.localizedDescription);
        } else {
            NSLog(@"CXSetMutedCallAction transaction request successful");
        }
        if (completion) { completion(error); }
    }];
}

- (void)setAudioState:(BOOL)isMuted {
    if (!self.localAudioTrack) { return; }
    self.localAudioTrack.enabled = !isMuted;
    if (self.delegate) { [self.delegate audioChanged:isMuted]; }
}

#pragma mark - TVIRoomDelegate

- (void)didConnectToRoom:(nonnull TVIRoom *)room {
    self.callState = Connected;
    // At the moment, this example only supports rendering one Participant at a time.
    if (room.remoteParticipants.count > 0) {
        self.remoteParticipant = room.remoteParticipants[0];
    }
    
    self.connectionCompletionHandler(true, nil);

    if (self.delegate) { [self.delegate didConnectToRoom:room]; }
}

- (void)room:(nonnull TVIRoom *)room didDisconnectWithError:(nullable NSError *)error {
    [TwilioVideoUtils logMessage:[NSString stringWithFormat:@"Disconnected from room %@, error = %@", room.name, error]];
    self.callState = Disconnected;
    self.room = nil;
    self.connectionCompletionHandler = nil;
    
    if (self.delegate) { [self.delegate room:room didDisconnectWithError:error]; }
    
    // Needed notify callkit if the call was remotely disconnected
    [self performCallKitEndCallAction:nil];
        
    [self notifyEndCallSubscribers];
    
    [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.calldisconnected" with:[self getMetadata]];
}

- (void)room:(nonnull TVIRoom *)room didFailToConnectWithError:(nonnull NSError *)error {
    self.callState = Failed;
    self.room = nil;
    self.connectionCompletionHandler(false, error);
    
    if (self.delegate) { [self.delegate room:room didFailToConnectWithError:error]; }
}

- (void)room:(nonnull TVIRoom *)room isReconnectingWithError:(nonnull NSError *)error {
    if (self.delegate) { [self.delegate room:room isReconnectingWithError:error]; }
}

- (void)didReconnectToRoom:(nonnull TVIRoom *)room {
    if (self.delegate) { [self.delegate didReconnectToRoom:room]; }
}

- (void)room:(TVIRoom *)room participantDidConnect:(TVIRemoteParticipant *)participant {
    self.remoteParticipant = participant;
    if (self.delegate) { [self.delegate room:room participantDidConnect:participant]; }
}

- (void)room:(TVIRoom *)room participantDidDisconnect:(TVIRemoteParticipant *)participant {
    [TwilioVideoUtils logMessage:[NSString stringWithFormat:@"Room %@ participant %@ disconnected", room.name, participant.identity]];
    if (self.delegate) { [self.delegate room:room participantDidDisconnect:participant]; }
    self.remoteParticipant = nil;
}

#pragma mark - TwilioVideoActionProducerDelegate

- (void)onDisconnect:(NSString*)callUUID {
    if (!callUUID || [[self.callUuid UUIDString] isEqualToString:callUUID]) {
        [self endCall];
    }
}

@end
