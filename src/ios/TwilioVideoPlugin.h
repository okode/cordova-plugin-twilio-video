#import <Cordova/CDV.h>
#import "TwilioVideoViewController.h"
#import "TwilioVideoConfig.h"
#import "TwilioVideoManager.h"

@interface TwilioVideoPlugin : CDVPlugin<TwilioVideoEventProducerDelegate>
@property (nonatomic, strong) NSString *listenerCallbackID;
@end

