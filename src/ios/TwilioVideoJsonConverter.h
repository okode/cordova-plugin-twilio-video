#import <Foundation/Foundation.h>
@import TwilioVideo;

@interface TwilioVideoJsonConverter : NSObject

+ (NSDictionary*)convertErrorToDictionary:(NSError*)error;
+ (NSDictionary*)convertRoomToDictionary:(TVIRoom*)room;

@end
