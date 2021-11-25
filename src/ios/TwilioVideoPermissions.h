#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface TwilioVideoPermissions : NSObject

+ (BOOL)hasRequiredPermissions;
+ (void)requestRequiredPermissions:(void (^)(BOOL))response;

@end
