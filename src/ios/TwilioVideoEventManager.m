#import "TwilioVideoEventManager.h"

@implementation TwilioVideoEventManager

+ (id)getInstance {
    static TwilioVideoEventManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)publishCallEvent:(NSString*)event {
    if (self.eventDelegate != NULL) {
        [self.eventDelegate onCallEvent:event with:NULL];
    }
}

- (void)publishCallEvent:(NSString*)event with:(NSDictionary*)data {
    if (self.eventDelegate != NULL) {
        [self.eventDelegate onCallEvent:event with:data];
    }
}

- (void)publishPluginEvent:(NSString*)event with:(NSDictionary*)data {
    if (self.eventDelegate != NULL) {
        [self.eventDelegate onPluginEvent:event with:data];
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
