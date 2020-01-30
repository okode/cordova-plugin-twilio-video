//
//  TwilioVideoViewController.m
//
//  Copyright © 2016-2017 Twilio, Inc. All rights reserved.
//

#import "TwilioVideoCall.h"

NSString *const CALL_OPENED = @"OPENED";
NSString *const CALL_CONNECTED = @"CONNECTED";
NSString *const CALL_CONNECT_FAILURE = @"CONNECT_FAILURE";
NSString *const CALL_DISCONNECTED = @"DISCONNECTED";
NSString *const CALL_DISCONNECTED_WITH_ERROR = @"DISCONNECTED_WITH_ERROR";
NSString *const CALL_PARTICIPANT_CONNECTED = @"PARTICIPANT_CONNECTED";
NSString *const CALL_PARTICIPANT_DISCONNECTED = @"PARTICIPANT_DISCONNECTED";
NSString *const CALL_AUDIO_TRACK_ADDED = @"AUDIO_TRACK_ADDED";
NSString *const CALL_AUDIO_TRACK_REMOVED = @"AUDIO_TRACK_REMOVED";
NSString *const CALL_VIDEO_TRACK_ADDED = @"VIDEO_TRACK_ADDED";
NSString *const CALL_VIDEO_TRACK_REMOVED = @"VIDEO_TRACK_REMOVED";
NSString *const CALL_CLOSED = @"CLOSED";

@implementation TwilioVideoCall

- (id)initWithUUID:(NSUUID*)uuid room:(NSString*)roomName token:(NSString*)token isCallKitCall:(BOOL)isCallKitCall {
    self = [self init];
    self.callUuid = uuid;
    self.accessToken = token;
    self.roomName = roomName;
    self.isCallKitCall = isCallKitCall;
    self.config = [[TwilioVideoConfig alloc] init];
    self.callKitCallController = [[CXCallController alloc] init];
    return self;
}

- (void)connectToRoom:(void (^)(BOOL))completion {
    self.connectionCompletionHandler = completion;
    [self doConnect];
}

- (void)endCall {
    [self endCall:nil];
}

- (void)endCall:(void (^)(void))completion {
    self.endCallCompletionHandler = completion;
    if (!self.room) {
        if (self.endCallCompletionHandler) { self.endCallCompletionHandler(); }
        return;
    }
    [self.room disconnect];
    if (self.delegate) { [self.delegate callEnded]; }
}

- (void)muteAudio:(BOOL)isMuted {
    if (!self.localAudioTrack) { return; }
    self.localAudioTrack.enabled = !isMuted;
    if (self.delegate) { [self.delegate audioChanged:isMuted]; }
}

- (void)switchCamera {
    if (!self.camera) { return; }
    if (self.camera.source == TVICameraCaptureSourceFrontCamera) {
        [self.camera selectSource:TVICameraCaptureSourceBackCameraWide];
    } else {
        [self.camera selectSource:TVICameraCaptureSourceFrontCamera];
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

- (void)connectLocalVideoWithDelegate:(nullable id<TVICameraCapturerDelegate>)delegate {
    // Set local video track
    self.camera = [[TVICameraCapturer alloc] initWithSource:TVICameraCaptureSourceFrontCamera delegate:delegate];
    self.localVideoTrack = [TVILocalVideoTrack trackWithCapturer:self.camera
                                                         enabled:YES
                                                     constraints:nil
                                                            name:@"Camera"];
    if (self.localVideoTrack && self.room && self.room.localParticipant) {
        [self.room.localParticipant publishVideoTrack:self.localVideoTrack];
    }
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
    self.room = [TwilioVideo connectWithOptions:connectOptions delegate:self];
}

- (void) performCallKitMuteAction:(BOOL)isMuted {
    if (self.isCallKitCall) {
        CXSetMutedCallAction *muteAction = [[CXSetMutedCallAction alloc] initWithCallUUID:self.callUuid muted:isMuted];
        CXTransaction *transaction = [[CXTransaction alloc] initWithAction:muteAction];
        
        [self.callKitCallController requestTransaction:transaction completion:^(NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"CXSetMutedCallAction transaction request failed: %@", error.localizedDescription);
                return;
            }
            NSLog(@"CXSetMutedCallAction transaction request successful");
        }];
    } else {
        [self muteAudio:isMuted];
    }
}

- (void) performCallKitEndCallAction {
    if (self.isCallKitCall) {
        CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:self.callUuid];
        CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];
        
        [self.callKitCallController requestTransaction:transaction completion:^(NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"EndCallAction transaction request failed: %@", error.localizedDescription);
                NSLog(@"Call ended anyway");
                [self endCall];
                return;
            }
            NSLog(@"EndCallAction transaction request successful");
        }];
    } else {
        [self endCall];
    }
}

#pragma mark - Utils

- (void)logMessage:(NSString *)msg {
    NSLog(@"%@", msg);
}

#pragma mark - TVIRoomDelegate

- (void)didConnectToRoom:(TVIRoom *)room {
    // At the moment, this example only supports rendering one Participant at a time.
    if (room.remoteParticipants.count > 0) {
        self.remoteParticipant = room.remoteParticipants[0];
    }
    
    self.connectionCompletionHandler(true);

    if (self.delegate) { [self.delegate didConnectToRoom:room]; }
}

- (void)room:(TVIRoom *)room didDisconnectWithError:(nullable NSError *)error {
    self.room = nil;
    self.connectionCompletionHandler = nil;
    
    if (self.delegate) { [self.delegate room:room didDisconnectWithError:error]; }
    
    if (self.endCallCompletionHandler) { self.endCallCompletionHandler(); }
}

- (void)room:(TVIRoom *)room didFailToConnectWithError:(nonnull NSError *)error{
    self.room = nil;
    self.connectionCompletionHandler(false);
    
    if (self.delegate) { [self.delegate room:room didFailToConnectWithError:error]; }
}

- (void)room:(TVIRoom *)room participantDidConnect:(TVIRemoteParticipant *)participant {
    self.remoteParticipant = participant;
    if (self.delegate) { [self.delegate room:room participantDidConnect:participant]; }
}

- (void)room:(TVIRoom *)room participantDidDisconnect:(TVIRemoteParticipant *)participant {
    [self logMessage:[NSString stringWithFormat:@"Room %@ participant %@ disconnected", room.name, participant.identity]];
    if (self.delegate) { [self.delegate room:room participantDidDisconnect:participant]; }
    self.remoteParticipant = nil;
}

@end
