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

- (void) reportIncomingCall:(UIViewController*)vc uuid:(NSUUID*)uuid roomName:(NSString*)roomName token:(NSString*)token caller:(NSString*)caller extras:(NSDictionary*)extras completion:(void (^)(NSError *_Nullable error))completion {
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
            self.rootViewController = vc;
            TwilioVideoCall *call = [[TwilioVideoCall alloc] initWithUUID:uuid room:roomName token:token isCallKitCall:true];
            call.extras = extras;
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
    
    [self.anserCall endCall];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    TwilioVideoCall *call = [self.callManager callWithUUID:action.callUUID];
    
    if (call == nil) {
        [action fail];
        return;
    }
    
    if (self.anserCall != nil) {
        [self.anserCall endCall:^{
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
    
    self.anserCall = call;
    
    /*
     Perform room connect
     */
    [call connectToRoom:^(BOOL connected) {
        if (connected) {
            if ([TwilioVideoPermissions hasRequiredPermissions]) {
                [action fulfillWithDateConnected:[[NSDate alloc] init]];
                [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.incomingcall.success" with:
                @{
                    @"callUUID": [call.callUuid UUIDString],
                    @"extras": call.extras
                }];
            } else {
                [call endCall];
                [action fail];
                [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.incomingcall.error" with:
                @{
                    @"code": @"NO_REQUIRED_PERMISSIONS"
                }];
            }
        } else {
            [action fail];
            [[TwilioVideoEventManager getInstance] publishPluginEvent:@"twiliovideo.incomingcall.error" with:
            @{
                @"code": @"CONNECTION_ERROR"
            }];
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
