//
//  TwilioVideoViewController.m
//
//  Copyright © 2016-2017 Twilio, Inc. All rights reserved.
//

#import "TwilioVideoCallKit.h"

@implementation TwilioVideoCallKit

#pragma mark - Public API

+ (instancetype)getInstance {
    static TwilioVideoCallKit *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    
    CXProviderConfiguration *config = [[CXProviderConfiguration alloc] initWithLocalizedName: @"CallKit"];
    config.maximumCallGroups = 1;
    config.maximumCallsPerCallGroup = 1;
    config.supportsVideo = true;
    config.supportedHandleTypes = [[NSSet alloc] initWithObjects:[NSNumber numberWithInt: CXHandleTypeGeneric], nil];
    
    self.callKitProvider = [[CXProvider alloc] initWithConfiguration:config];
    
    [self.callKitProvider setDelegate:self queue:nil];
    
    self.callManager = [[TwilioVideoCallManager alloc] init];
    
    return self;
}

- (void) reportIncomingCall:(UIViewController*)vc uuid:(NSUUID*)uuid roomName:(NSString*)roomName token:(NSString*)token completion:(void (^)(NSError *_Nullable error))completion {
    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:roomName != nil ? roomName : @""];
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    [callUpdate setRemoteHandle:callHandle];
    [callUpdate setSupportsDTMF:false];
    [callUpdate setSupportsGrouping:false];
    [callUpdate setSupportsUngrouping:false];
    [callUpdate setHasVideo:true];
    
    [self.callKitProvider reportNewIncomingCallWithUUID:uuid update:callUpdate completion:^(NSError * _Nullable error) {
        if (error == nil) {
            NSLog(@"Incoming call successfully reported.");
            self.rootViewController = vc;
            TwilioVideoCall *call = [[TwilioVideoCall alloc] initWithUUID:uuid room:roomName token:token isCallKitCall:true];
            [self.callManager addCall:call];
        } else {
            NSLog(@"Failed to report incoming call successfully: %@", error.localizedDescription);
        }
        completion(error);
    }];
}

#pragma mark - Callkit delegate

- (void)providerDidReset:(CXProvider *)provider {
    if (self.anserCall == nil) {
        return;
    }
    
    [self.anserCall.audioDevice setEnabled:true];
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    if (self.anserCall == nil) {
        return;
    }
    
    [self.anserCall.audioDevice setEnabled:true];
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
    if (self.anserCall == nil) {
        return;
    }
    
    [self.anserCall.audioDevice setEnabled:false];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    TwilioVideoCall *call = [self.callManager callWithUUID:action.callUUID];
    
    if (call == nil) {
        [action fail];
        return;
    }
    /*
     * Configure the audio session, but do not start call audio here, since it must be done once
     * the audio session has been activated by the system after having its priority elevated.
     */
    // Stop the audio unit by setting isEnabled to `false`.
    [call setAudioDevice:false];
    // Configure the AVAudioSession by executign the audio device's `block`.
    [call.audioDevice block];
    /*
     Perform room connect
     */
    [call connectToRoom:^(BOOL connected) {
        if (connected) {
            [action fulfillWithDateConnected:[[NSDate alloc] init]];
            self.anserCall = call;
            [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.incomingcall" with:@{ @"code": call.callUuid }];
            // TwilioVideoConfig *config = [[TwilioVideoConfig alloc] init];
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"TwilioVideo" bundle:nil];
            TwilioVideoViewController *vc = [sb instantiateViewControllerWithIdentifier:@"TwilioVideoViewController"];
            // vc.config = config;
            vc.call = call;
            [self.rootViewController presentViewController:vc animated:NO completion:^{
                NSLog(@"Test");
            }];
        } else {
            [action fail];
        }
    }];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    TwilioVideoCall *call = [self.callManager callWithUUID:action.callUUID];
    if (call == nil) {
        [action fail];
        return;
    }
    [call endCall];
    [action fulfill];
    [self.callManager removeCallByUUID:call.callUuid];
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
    TwilioVideoCall *call = [self.callManager callWithUUID:action.callUUID];
    if (call == nil) {
        [action fail];
        return;
    }
    [call muteAudio:action.isMuted];
    [action fulfill];
}

@end
