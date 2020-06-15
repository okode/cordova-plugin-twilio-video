#import "TwilioVideoUtils.h"

@implementation TwilioVideoUtils

+ (NSDictionary*)convertErrorToDictionary:(NSError*)error {
    return @{ @"code": [NSString stringWithFormat:@"%ld",[error code]], @"description": [error localizedDescription] };
}

+ (BOOL)isSimulator {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    return NO;
}

+ (void)logMessage:(NSString *)msg {
    NSLog(@"%@", msg);
}

@end
