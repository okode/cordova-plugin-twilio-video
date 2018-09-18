#import <Foundation/Foundation.h>

NSString *const PRIMARY_COLOR_PROP = @"primaryColor";
NSString *const SECONDARY_COLOR_PROP = @"secondaryColor";

@interface TwilioVideoConfig : NSObject
@property NSString *primaryColorHex;
@property NSString *secondaryColorHex;
-(void) parse:(NSDictionary*)config;
+ (UIColor *)colorFromHexString:(NSString *)hexString;
@end
