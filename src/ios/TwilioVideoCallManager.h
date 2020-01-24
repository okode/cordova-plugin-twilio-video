@import CallKit;
#import "TwilioVideoCall.h"

@interface TwilioVideoCallManager: NSObject

@property (nonatomic, strong) CXCallController *callKitCallController;
@property (nonatomic, strong) NSMutableDictionary<NSString*, TwilioVideoCall*> *calls;

- (TwilioVideoCall*)callWithUUID:(NSUUID*)uuid;
- (void)addCall:(TwilioVideoCall*)call;
- (void)removeCallByUUID:(NSUUID*)uuid;

@end
