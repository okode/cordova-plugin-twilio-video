//
//  TwilioVideoViewController.h
//
//  Copyright © 2016-2017 Twilio, Inc. All rights reserved.
//
@import CallKit;
@import TwilioVideo;
#import "TwilioVideoEventManager.h"
#import "TwilioVideoConfig.h"

extern NSString *const CALL_OPENED;
extern NSString *const CALL_CONNECTED;
extern NSString *const CALL_CONNECT_FAILURE;
extern NSString *const CALL_DISCONNECTED;
extern NSString *const CALL_DISCONNECTED_WITH_ERROR;
extern NSString *const CALL_PARTICIPANT_CONNECTED;
extern NSString *const CALL_PARTICIPANT_DISCONNECTED;
extern NSString *const CALL_AUDIO_TRACK_ADDED;
extern NSString *const CALL_AUDIO_TRACK_REMOVED;
extern NSString *const CALL_VIDEO_TRACK_ADDED;
extern NSString *const CALL_VIDEO_TRACK_REMOVED;
extern NSString *const CALL_HANG_UP;
extern NSString *const CALL_CLOSED;

@protocol TwilioVideoCallDelegate <TVIRoomDelegate>
- (void)audioChanged:(BOOL)isMuted;
- (void)videoChanged:(BOOL)isDisabled;
- (void)callEnded;
@end

@interface TwilioVideoCall: NSObject <TVIRoomDelegate>
    
@property (nonatomic, weak) _Nullable id <TwilioVideoCallDelegate> delegate;

#pragma mark Twilio call context properties

@property (nonatomic, strong) NSString *roomName;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSUUID *callUuid;
@property (nonatomic, strong) TwilioVideoConfig *config;
@property BOOL isCallKitCall;

#pragma mark Video SDK components

@property (nonatomic, strong) TVIDefaultAudioDevice *audioDevice;
@property (nonatomic, strong) TVICameraCapturer *camera;
@property (nonatomic, strong) TVILocalVideoTrack *localVideoTrack;
@property (nonatomic, strong) TVILocalAudioTrack *localAudioTrack;
@property (nonatomic, strong) TVIRemoteParticipant *remoteParticipant;
@property (nonatomic, weak) TVIVideoView *remoteView;
@property (nonatomic, strong) TVIRoom *room;

#pragma mark Connection callback
@property (nonatomic, strong) void (^connectionCompletionHandler)(BOOL connected);

#pragma mark CallKit
@property (nonatomic, strong) CXCallController *callKitCallController;

- (id)initWithUUID:(NSUUID*)uuid room:(NSString*)roomName token:(NSString*)token isCallKitCall:(BOOL)isCallKitCall;
- (void)connectLocalVideoWithDelegate:(nullable id<TVICameraCapturerDelegate>)delegate;
- (void)connectToRoom:(void (^)(BOOL connected))completion;
- (void)endCall;
- (void)muteAudio:(BOOL)isMuted;
- (void)switchCamera;
- (void)disableVideo:(BOOL)isDisabled;
- (void)performCallKitMuteAction:(BOOL)isMuted;
- (void)performCallKitEndCallAction;
/*
- (void)connectToRoom:(NSString*)room token:(NSString *)token uuid:(NSUUID*)uuid completion:(void (^)(BOOL connected))completion;
- (void)disconnectRoom;
- (void)muteAudio:(BOOL)isMuted;
 */

@end


