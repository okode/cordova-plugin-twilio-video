#import "TwilioVideoUtils.h"

@implementation TwilioVideoUtils

+ (NSDictionary*)convertErrorToDictionary:(NSError*)error {
    return @{ @"code": [NSNumber numberWithInteger:[error code]], @"description": [error localizedDescription] };
}

@end
