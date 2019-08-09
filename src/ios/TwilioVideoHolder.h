#import <Foundation/Foundation.h>
#import "TwilioVideoActions.h"

@interface TwilioVideoHolder : NSObject
@property (nonatomic, weak) id <TwilioVideoActions> videoInstance;
+ (id)getInstance;
@end
