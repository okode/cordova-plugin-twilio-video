@import CallKit;
#import "TwilioVideoCall.h"

@interface TwilioVideoCallManager: NSObject

@property (nonatomic, strong) NSMutableDictionary<NSString*,TwilioVideoCall*> * _Nullable calls;
@property (nonatomic, strong) TwilioVideoCall * _Nullable answerCall;

+ (instancetype _Nonnull )getInstance;
- (TwilioVideoCall*_Nullable)callWithUUID:(NSUUID*_Nonnull)uuid;
- (void)addCall:(TwilioVideoCall*_Nonnull)call;
- (void)removeCallByUUID:(NSUUID*_Nonnull)uuid;

@end
