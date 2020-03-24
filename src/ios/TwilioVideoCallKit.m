//
//  TwilioVideoViewController.m
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
    
    CXProviderConfiguration *config = [self getDefaultCallKitProviderConfig];
    
    self.callKitProvider = [[CXProvider alloc] initWithConfiguration:config];
    
    [self.callKitProvider setDelegate:self queue:nil];
        
    return self;
}

- (void)reportIncomingCallWith:(TwilioVideoCallKitIncomingCall*_Nonnull)incomingCall completion:(void (^_Nullable)(NSError *_Nullable error))completion {
    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:incomingCall.caller != nil ? incomingCall.caller : @""];
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    [callUpdate setRemoteHandle:callHandle];
    [callUpdate setSupportsDTMF:false];
    [callUpdate setSupportsGrouping:false];
    [callUpdate setSupportsUngrouping:false];
    [callUpdate setSupportsHolding:false];
    [callUpdate setHasVideo:true];
    
    [self.callKitProvider reportNewIncomingCallWithUUID:incomingCall.uuid update:callUpdate completion:^(NSError * _Nullable error) {
        if (error == nil) {
            NSLog(@"Incoming call successfully reported.");
            if ([self isBusinessCallAlreadyAnswered: incomingCall.businessId]) {
                NSLog(@"Ending call with businessId %@ because it was picked up previously", incomingCall.businessId);
                [self reportEndCallWith:incomingCall.uuid];
            } else {
                NSLog(@"Setting up call");
                TwilioVideoCall *call = [[TwilioVideoCall alloc] initWithUUID:incomingCall.uuid room:incomingCall.roomName token:incomingCall.token isCallKitCall:true];
                call.extras = incomingCall.extras;
                call.config = incomingCall.config;
                call.businessId = incomingCall.businessId;
                [[TwilioVideoCallManager getInstance] addCall:call];
                [self startHangUpDaemonIfCallNotAnswered:call];
            }
        } else {
            NSLog(@"Failed to report incoming call successfully: %@", error.localizedDescription);
        }
        completion(error);
    }];
}

- (void)reportEndCallWith:(NSUUID*)uuid {
    [self.callKitProvider reportCallWithUUID:uuid endedAtDate:nil reason:CXCallEndedReasonAnsweredElsewhere];
}

- (BOOL)handleContinueActivity:(NSUserActivity*)userActivity {
    TwilioVideoCall *answerCall = [TwilioVideoCallManager getInstance].answerCall;
    if (!answerCall) {
        NSLog(@"No inprogress twilio video calls");
        return false;
    }
    if (userActivity &&  [userActivity.activityType isEqualToString:@"INStartVideoCallIntent"]) {
        [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.videorequested" with:[answerCall getMetadata]];
        return true;
    }
    return false;
}

- (CXProviderConfiguration*)getDefaultCallKitProviderConfig {
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    CXProviderConfiguration *config = [[CXProviderConfiguration alloc] initWithLocalizedName: appName ? appName : @"TwilioCallKit"];
    config.maximumCallGroups = 1;
    config.maximumCallsPerCallGroup = 1;
    config.includesCallsInRecents = false;
    config.supportsVideo = true;
    UIImage *appIcon = [UIImage imageNamed:@"AppIcon"];
    config.iconTemplateImageData = UIImagePNGRepresentation(appIcon);
    config.supportedHandleTypes = [[NSSet alloc] initWithObjects:[NSNumber numberWithInt: CXHandleTypeGeneric], nil];
    return config;
}

- (BOOL)isBusinessCallAlreadyAnswered:(NSString*)businessId {
    if (!businessId) { return false; }
    TwilioVideoCall *answerCall = [TwilioVideoCallManager getInstance].answerCall;
    BOOL isAnswerCallConnectingOrConnected =
        answerCall &&
        (answerCall.callState == Initial
        || answerCall.callState == Connecting
        || answerCall.callState == Connected);
    return isAnswerCallConnectingOrConnected && [answerCall.businessId isEqualToString:businessId] ;
}

- (void)startHangUpDaemonIfCallNotAnswered:(TwilioVideoCall*)call {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!call.isAnsweredByCallKit) {
            NSLog(@"Call %@ not answered so it was hanged up", call.callUuid);
            [self reportEndCallWith:call.callUuid];
        }
    });
}

#pragma mark - Callkit delegate

- (void)providerDidReset:(CXProvider *)provider {
    if ([TwilioVideoCallManager getInstance].answerCall == nil) {
        return;
    }
    
    [[TwilioVideoCallManager getInstance].answerCall endCall];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    TwilioVideoCall *call = [[TwilioVideoCallManager getInstance] callWithUUID:action.callUUID];
    
    if (call == nil) {
        [action fail];
        return;
    }
    
    call.isAnsweredByCallKit = true;
        
    if ([TwilioVideoCallManager getInstance].answerCall != nil) {
        [[TwilioVideoCallManager getInstance].answerCall endCall:^{
            {
                NSLog(@"Call ended successfully");
                [self answerCallWith:call action:action];
            }
        }];
    } else {
         [self answerCallWith:call action:action];
    }
}

- (void)answerCallWith:(TwilioVideoCall *)call action:(CXAnswerCallAction *)action {
    [TwilioVideoCallManager getInstance].answerCall = call;
        
    [[AVAudioSession sharedInstance] setActive:NO    withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                  error:nil];
    
    [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.incomingcall.loading" with:[call getMetadata]];

    if (![TwilioVideoPermissions hasRequiredPermissions]) {
        [action fail];
        [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.incomingcall.error" with:
        @{
            @"errorCode": @"NO_REQUIRED_PERMISSIONS",
            @"call": [call getMetadata]
        }];
        return;
    }

    /*
     Perform room connect
     */
    [call connectToRoom:^(BOOL connected, NSError * _Nullable error) {
        if (connected) {
            [action fulfill];
            [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.incomingcall.success" with:[call getMetadata]];
        } else {
            [action fail];
            [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.incomingcall.error" with:
            @{
                @"errorCode": @"CONNECTION_ERROR",
                @"errorDescription": error ? error.description : [NSNull new],
                @"call": [call getMetadata]
            }];
        }
    }];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    TwilioVideoCall *call = [[TwilioVideoCallManager getInstance] callWithUUID:action.callUUID];
    if (call == nil) {
        [action fail];
        return;
    }
    call.isEndCallNotifiedToCallKit = true;
    [call endCall:^{
        NSLog(@"Ended call");
    }];
    [action fulfill];
    [[TwilioVideoCallManager getInstance] removeCallByUUID:call.callUuid];	
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
    TwilioVideoCall *call = [[TwilioVideoCallManager getInstance] callWithUUID:action.callUUID];
    if (call == nil) {
        [action fail];
        return;
    }
    call.isMuteActionNotifiedToCallKit = true;
    [call muteAudio:action.isMuted];
    [action fulfill];
}

@end
