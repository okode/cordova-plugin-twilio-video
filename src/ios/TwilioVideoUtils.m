#import "TwilioVideoUtils.h"

@implementation TwilioVideoUtils

+ (NSDictionary*)convertErrorToDictionary:(NSError*)error {
    return @{ @"code": [NSString stringWithFormat:@"%ld",[error code]], @"description": [error localizedDescription] };
}

@end
