//
//  TwilioVideoViewController.h
//

@import CallKit;
@import TwilioVideo;
#import "TwilioVideoEventManager.h"
#import "TwilioVideoConfig.h"

extern NSString * _Nonnull const CALL_OPENED;
extern NSString * _Nonnull const CALL_CONNECTED;
extern NSString * _Nonnull const CALL_CONNECT_FAILURE;
extern NSString * _Nonnull const CALL_DISCONNECTED;
extern NSString * _Nonnull const CALL_DISCONNECTED_WITH_ERROR;
extern NSString * _Nonnull const CALL_PARTICIPANT_CONNECTED;
extern NSString * _Nonnull const CALL_PARTICIPANT_DISCONNECTED;
extern NSString * _Nonnull const CALL_AUDIO_TRACK_ADDED;
extern NSString * _Nonnull const CALL_AUDIO_TRACK_REMOVED;
extern NSString * _Nonnull const CALL_VIDEO_TRACK_ADDED;
extern NSString * _Nonnull const CALL_VIDEO_TRACK_REMOVED;
extern NSString * _Nonnull const CALL_PERMISSIONS_REQUIRED;
extern NSString * _Nonnull const CALL_HANG_UP;
extern NSString * _Nonnull const CALL_CLOSED;

@protocol TwilioVideoCallDelegate <TVIRoomDelegate>
- (void)audioChanged:(BOOL)isMuted;
- (void)videoChanged:(BOOL)isDisabled;
@end

@interface TwilioVideoCall: NSObject <TVIRoomDelegate, TwilioVideoActionProducerDelegate>
    
@property (nonatomic, weak) _Nullable id <TwilioVideoCallDelegate> delegate;

#pragma mark Twilio call context properties

@property (nonatomic, strong) NSString * _Nullable roomName;
@property (nonatomic, strong) NSString * _Nullable accessToken;
@property (nonatomic, strong) NSUUID * _Nullable callUuid;
@property (nonatomic, strong) TwilioVideoConfig * _Nullable config;
@property (nonatomic, strong) NSDictionary * _Nullable extras;
@property BOOL isCallKitCall;

#pragma mark Video SDK components

// @property (nonatomic, strong) TVIDefaultAudioDevice *audioDevice;
@property (nonatomic, strong) TVICameraCapturer * _Nullable camera;
@property (nonatomic, strong) TVILocalVideoTrack * _Nullable localVideoTrack;
@property (nonatomic, strong) TVILocalAudioTrack * _Nullable localAudioTrack;
@property (nonatomic, strong) TVIRemoteParticipant * _Nullable remoteParticipant;
@property (nonatomic, strong) TVIRoom * _Nullable room;

#pragma mark Connection callback
@property (nonatomic, strong) void (^ _Nullable connectionCompletionHandler)(BOOL connected, NSError * _Nullable error);
#pragma mark Disconnection callback
@property (nonatomic, strong) NSMutableArray<void (^)(void)> * _Nullable endCallSubscribers;

#pragma mark Flag
@property BOOL isEndCallNotifiedToCallKit;
@property BOOL isEndCallEventSent;

#pragma mark CallKit
@property (nonatomic, strong) CXCallController * _Nullable callKitCallController;

- (id _Nonnull )initWithUUID:(NSUUID*_Nullable)uuid room:(NSString*_Nullable)roomName token:(NSString*_Nullable)token isCallKitCall:(BOOL)isCallKitCall;
- (void)connectLocalVideoWithDelegate:(nullable id<TVICameraCapturerDelegate>)delegate;
- (void)connectToRoom:(void (^_Nullable)(BOOL connected, NSError * _Nullable error))completion;
- (void)endCall;
- (void)endCall:(void (^_Nullable)(void))completion;
- (void)muteAudio:(BOOL)isMuted;
- (void)switchCamera;
- (void)stopCamera;
- (void)disableVideo:(BOOL)isDisabled;
- (void)performUIMuteAction:(BOOL)isMuted;

@end


