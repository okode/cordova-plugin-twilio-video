#import <Foundation/Foundation.h>

NSString *const PRIMARY_COLOR_PROP = @"primaryColor";
NSString *const SECONDARY_COLOR_PROP = @"secondaryColor";
NSString *const i18n_CONNECTION_ERROR_PROP = @"i18nConnectionError";
NSString *const i18n_DISCONNECTED_WITH_ERROR_PROP = @"i18nDisconnectedWithError";
NSString *const i18n_ACCEPT_PROP = @"i18nAccept";
NSString *const HANDLE_ERROR_IN_APP = @"handleErrorInApp";

@interface TwilioVideoConfig : NSObject
@property NSString *primaryColorHex;
@property NSString *secondaryColorHex;
@property NSString *i18nConnectionError;
@property NSString *i18nDisconnectedWithError;
@property NSString *i18nAccept;
@property BOOL handleErrorInApp;

-(void) parse:(NSDictionary*)config;
+ (UIColor *)colorFromHexString:(NSString *)hexString;
@end
