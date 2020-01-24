//
//  TwilioVideoViewController.h
//
//  Copyright © 2016-2017 Twilio, Inc. All rights reserved.
//

@import CallKit;
#import "TwilioVideoCallManager.h"
#import "TwilioVideoViewController.h"

@interface TwilioVideoCallKit: NSObject <CXProviderDelegate>

// CallKit components
@property (nonatomic, strong) CXProvider *callKitProvider;

@property (nonatomic, strong) TwilioVideoCallManager *callManager;
@property (nonatomic, strong) TwilioVideoCall *anserCall;

@property (nonatomic, strong) UIViewController *rootViewController;

+ (instancetype)getInstance;
- (void) reportIncomingCall:(UIViewController*)vc uuid:(NSUUID*)uuid roomName:(NSString*)roomName token:(NSString*)token completion:(void (^)(NSError *_Nullable error))completion;

@end


