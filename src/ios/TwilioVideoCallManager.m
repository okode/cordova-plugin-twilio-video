#import "TwilioVideoCallManager.h"

@implementation TwilioVideoCallManager

+ (instancetype)getInstance {
    static TwilioVideoCallManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
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
}

- (void)removeCallByUUID:(NSUUID*)uuid {
    [self.calls removeObjectForKey:uuid.UUIDString];
}

@end
