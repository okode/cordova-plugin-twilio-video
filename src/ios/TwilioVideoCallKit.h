//
//  TwilioVideoViewController.h
//

@import CallKit;
#import "TwilioVideoCallManager.h"
#import "TwilioVideoEventManager.h"
#import "TwilioVideoPermissions.h"

@interface TwilioVideoCallKitIncomingCall: NSObject
@property NSUUID* _Nullable uuid;
@property NSString* _Nullable roomName;
@property NSString* _Nullable token;
@property NSString* _Nullable caller;
@property NSDictionary* _Nullable extras;
@property TwilioVideoConfig* _Nonnull config;
@end

@implementation TwilioVideoCallKitIncomingCall
@end

@interface TwilioVideoCallKit: NSObject <CXProviderDelegate>

// CallKit components
@property (nonatomic, strong) CXProvider * _Nullable callKitProvider;

+ (instancetype _Nonnull)getInstance;
- (void)reportIncomingCallWith:(TwilioVideoCallKitIncomingCall*_Nonnull)incomingCall completion:(void (^_Nullable)(NSError *_Nullable error))completion;
- (void)reportEndCallWith:(NSUUID*_Nullable)uuid;
- (BOOL)handleContinueActivity:(NSUserActivity* _Nullable)userActivity;
@end


