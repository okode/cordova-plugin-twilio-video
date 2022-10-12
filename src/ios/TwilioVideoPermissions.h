#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface TwilioVideoPermissions : NSObject

+ (BOOL)hasRequiredVideoCallPermissions;
+ (BOOL)hasRequiredAudioCallPermissions;
+ (void)requestRequiredVideoCallPermissions:(void (^)(BOOL))response;
+ (void)requestRequiredAudioCallPermissions:(void (^)(BOOL))response;

@end
