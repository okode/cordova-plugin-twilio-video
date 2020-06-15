//
//  TwilioVideoViewController.h
//

@import CallKit;
@import TwilioVideo;
#import "TwilioVideoEventManager.h"
#import "TwilioVideoConfig.h"
#import "TwilioVideoUtils.h"

extern NSString * _Nonnull const CALL_OPENED;
extern NSString * _Nonnull const CALL_CONNECTED;
extern NSString * _Nonnull const CALL_CONNECT_FAILURE;
extern NSString * _Nonnull const CALL_DISCONNECTED;
extern NSString * _Nonnull const CALL_DISCONNECTED_WITH_ERROR;
extern NSString * _Nonnull const CALL_RECONNECTING;
extern NSString * _Nonnull const CALL_RECONNECTED;
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

typedef NS_ENUM(NSUInteger, State) {
    Initial = 0,
    Connecting,
    Connected,
    Disconnected,
    Failed
};

@interface TwilioVideoCall: NSObject <TVIRoomDelegate, TwilioVideoActionProducerDelegate>
    
@property (nonatomic, weak) _Nullable id <TwilioVideoCallDelegate> delegate;

#pragma mark Twilio call context properties

@property (nonatomic, strong) NSUUID * _Nonnull callUuid;
@property (nonatomic, strong) NSString * _Nullable businessId;
@property (nonatomic, strong) NSString * _Nullable roomName;
@property (nonatomic, strong) NSString * _Nullable accessToken;
@property (nonatomic, strong) TwilioVideoConfig * _Nullable config;
@property (nonatomic, strong) NSDictionary * _Nullable extras;
@property BOOL isCallKitCall;
@property BOOL isAnsweredByCallKit;
@property State callState;

#pragma mark Video SDK components

@property (nonatomic, strong) TVICameraSource * _Nullable camera;
@property (nonatomic, strong) TVILocalVideoTrack * _Nullable localVideoTrack;
@property (nonatomic, strong) TVILocalAudioTrack * _Nullable localAudioTrack;
@property (nonatomic, strong) TVIRemoteParticipant * _Nullable remoteParticipant;
@property (nonatomic, strong) TVIRoom * _Nullable room;

#pragma mark Connection callback
@property (nonatomic, strong) void (^ _Nullable connectionCompletionHandler)(BOOL connected, NSError * _Nullable error);
#pragma mark Disconnection callback
@property (nonatomic, strong) NSMutableArray<void (^)(void)> * _Nullable endCallSubscribers;

#pragma mark Flags
@property BOOL isEndCallNotifiedToCallKit;
@property BOOL isEndCallEventSent;
@property BOOL isMuteActionNotifiedToCallKit;
@property BOOL hasFrontAndBackCameraReady;

#pragma mark CallKit
@property (nonatomic, strong) CXCallController * _Nullable callKitCallController;

- (id _Nonnull )initWithUUID:(NSUUID*_Nullable)uuid room:(NSString*_Nullable)roomName token:(NSString*_Nullable)token isCallKitCall:(BOOL)isCallKitCall;
- (BOOL)connectLocalVideoWithRenderer:(nonnull TVIVideoView*)view
                             delegate:(nullable id<TVICameraSourceDelegate>)delegate;
- (void)connectToRoom:(void (^_Nullable)(BOOL connected, NSError * _Nullable error))completion;
- (void)endCall;
- (void)endCall:(void (^_Nullable)(void))completion;
- (void)muteAudio:(BOOL)isMuted;
- (void)switchCameraWithRenderer:(nonnull TVIVideoView*)view;
- (void)stopCamera;
- (void)disableVideo:(BOOL)isDisabled;
- (NSDictionary*_Nonnull)getMetadata;

@end


