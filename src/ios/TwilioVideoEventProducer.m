#import "TwilioVideoEventProducer.h"

@implementation TwilioVideoEventProducer
+ (id)getInstance {
    static TwilioVideoEventProducer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
- (void)publishEvent:(NSString*)event {
    if (self.delegate != NULL) {
        [self.delegate onCallEvent:event];
    }
}
@end
