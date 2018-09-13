/********* TwilioVideo.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "TwilioVideoViewController.h"

@interface TwilioVideoPlugin : CDVPlugin
@property (nonatomic, copy) NSString *listenerCallbackID;
- (BOOL)notifyListener:(NSString *)event;
@end
