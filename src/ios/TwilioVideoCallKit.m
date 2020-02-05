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

- (void)reportIncomingCallWith:(NSUUID*)uuid roomName:(NSString*)roomName token:(NSString*)token caller:(NSString*)caller extras:(NSDictionary*)extras completion:(void (^)(NSError *_Nullable error))completion {
    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:caller != nil ? caller : @""];
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    [callUpdate setRemoteHandle:callHandle];
    [callUpdate setSupportsDTMF:false];
    [callUpdate setSupportsGrouping:false];
    [callUpdate setSupportsUngrouping:false];
    [callUpdate setHasVideo:true];
    
    [self.callKitProvider reportNewIncomingCallWithUUID:uuid update:callUpdate completion:^(NSError * _Nullable error) {
        if (error == nil) {
            NSLog(@"Incoming call successfully reported.");
            TwilioVideoCall *call = [[TwilioVideoCall alloc] initWithUUID:uuid room:roomName token:token isCallKitCall:true];
            call.extras = extras;
            [[TwilioVideoCallManager getInstance] addCall:call];
        } else {
            NSLog(@"Failed to report incoming call successfully: %@", error.localizedDescription);
        }
        completion(error);
    }];
}

- (BOOL)handleContinueActivity:(NSUserActivity*)userActivity {
    TwilioVideoCall *answerCall = [TwilioVideoCallManager getInstance].answerCall;
    if (!answerCall) {
        NSLog(@"No inprogress twilio video calls");
        return false;
    }
    if (userActivity &&  [userActivity.activityType isEqualToString:@"INStartVideoCallIntent"]) {
        [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.incomingcall.videorequested" with:
        @{
            @"callUUID": [answerCall.callUuid UUIDString],
            @"extras": answerCall.extras
        }];
        return true;
    }
    return false;
}

- (CXProviderConfiguration*)getDefaultCallKitProviderConfig {
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    CXProviderConfiguration *config = [[CXProviderConfiguration alloc] initWithLocalizedName: appName ? appName : @"TwilioCallKit"];
    config.maximumCallGroups = 1;
    config.maximumCallsPerCallGroup = 1;
    config.supportsVideo = true;
    UIImage *appIcon = [UIImage imageNamed:@"AppIcon"];
    config.iconTemplateImageData = UIImagePNGRepresentation(appIcon);
    config.supportedHandleTypes = [[NSSet alloc] initWithObjects:[NSNumber numberWithInt: CXHandleTypeGeneric], nil];
    return config;
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
    
    [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.incomingcall.loading" with:
    @{
        @"callUUID": [call.callUuid UUIDString],
        @"extras": call.extras
    }];

    if (![TwilioVideoPermissions hasRequiredPermissions]) {
        [action fail];
        [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.incomingcall.error" with:
        @{
            @"errorCode": @"NO_REQUIRED_PERMISSIONS",
            @"callUUID": [call.callUuid UUIDString],
            @"extras": call.extras
        }];
        return;
    }

    /*
     Perform room connect
     */
    [call connectToRoom:^(BOOL connected) {
        if (connected) {
            [action fulfill];
            [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.incomingcall.success" with:
            @{
                @"callUUID": [call.callUuid UUIDString],
                @"extras": call.extras
            }];
        } else {
            [action fail];
            [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.incomingcall.error" with:
            @{
                @"errorCode": @"CONNECTION_ERROR",
                @"callUUID": [call.callUuid UUIDString],
                @"extras": call.extras
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
    [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.incomingcall.callkitend" with:
    @{
        @"callUUID": [call.callUuid UUIDString],
        @"extras": call.extras
    }];
    [[TwilioVideoCallManager getInstance] removeCallByUUID:call.callUuid];
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
    TwilioVideoCall *call = [[TwilioVideoCallManager getInstance] callWithUUID:action.callUUID];
    if (call == nil) {
        [action fail];
        return;
    }
    [call muteAudio:action.isMuted];
    [action fulfill];
}

@end
