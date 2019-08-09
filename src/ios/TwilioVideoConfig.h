#import <Foundation/Foundation.h>

@interface TwilioVideoConfig : NSObject
@property NSString *primaryColorHex;
@property NSString *secondaryColorHex;
@property NSString *i18nConnectionError;
@property NSString *i18nDisconnectedWithError;
@property NSString *i18nAccept;
@property BOOL handleErrorInApp;
@property BOOL hangUpInApp;

-(void) parse:(NSDictionary*)config;
+ (UIColor *)colorFromHexString:(NSString *)hexString;
@end
