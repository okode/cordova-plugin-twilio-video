#import "TwilioVideoCallManager.h"

@implementation TwilioVideoCallManager

-(id)init {
    self = [super init];
    self.calls = [[NSMutableDictionary alloc] init];
    return self;
}

- (TwilioVideoCall*)callWithUUID:(NSUUID*)uuid {
    TwilioVideoCall *call = [self.calls objectForKey:uuid.UUIDString];
    return call;
}

- (void)addCall:(TwilioVideoCall*)call {
    [self.calls setValue:call forKey:call.callUuid.UUIDString];
    // [self.calls setValue:call forKey:call.callUuid];
}

- (void)removeCallByUUID:(NSUUID*)uuid {
    [self.calls removeObjectForKey:uuid.UUIDString];
}

@end
