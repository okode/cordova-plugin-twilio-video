#import "TwilioVideoHolder.h"

@implementation TwilioVideoHolder

+ (id)getInstance {
    static TwilioVideoHolder *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end
