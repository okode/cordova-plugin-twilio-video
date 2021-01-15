#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface TwilioVideoPermissions : NSObject
+ (BOOL)hasRequiredPermissions;
+ (void)hasVideoPermissions:(void (^)(BOOL))response;
+ (void)requestRequiredPermissions:(void (^)(BOOL))response;
@end
