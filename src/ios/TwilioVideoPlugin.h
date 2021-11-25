#import <Cordova/CDV.h>
#import "TwilioVideoViewController.h"
#import "TwilioVideoConfig.h"
#import "TwilioVideoManager.h"
#import "TwilioVideoJsonConverter.h"

@interface TwilioVideoPlugin : CDVPlugin<TwilioVideoEventProducerDelegate>

@property NSString *listenerCallbackID;

@end

