#import "TwilioVideoConfig.h"

#define PRIMARY_COLOR_PROP                  @"primaryColor"
#define SECONDARY_COLOR_PROP                @"secondaryColor"
#define HANG_UP_IN_APP                      @"hangUpInApp"

@implementation TwilioVideoConfig

-(void) parse:(NSDictionary*)config {
    if (config == NULL || config == (id)[NSNull null]) { return; }
    self.primaryColorHex = [config objectForKey:PRIMARY_COLOR_PROP];
    self.secondaryColorHex = [config objectForKey:SECONDARY_COLOR_PROP];
    NSNumber *hangUpInApp = [config objectForKey:HANG_UP_IN_APP];
    self.hangUpInApp = hangUpInApp ? [hangUpInApp boolValue] : false;
}

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end
