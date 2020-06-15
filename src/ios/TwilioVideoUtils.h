#import <Foundation/Foundation.h>

@interface TwilioVideoUtils : NSObject
+ (NSDictionary*)convertErrorToDictionary:(NSError*)error;
+ (BOOL)isSimulator;
+ (void)logMessage:(NSString *)msg;
@end
