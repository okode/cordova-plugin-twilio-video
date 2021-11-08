#import "TwilioVideoManager.h"

@implementation TwilioVideoManager

+ (id)getInstance {
    static TwilioVideoManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)publishEvent:(CallEvent*)event {
    if (self.eventDelegate != NULL) {
        [self.eventDelegate onCallEvent:event];
    }
}

- (BOOL)publishDisconnection {
    if (self.actionDelegate != NULL) {
        [self.actionDelegate onDisconnect];
        return true;
    }
    return false;
}

@end
