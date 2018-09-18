#import <Cordova/CDV.h>
#import "TwilioVideoViewController.h"
#import "TwilioVideoConfig.h"
#import "TwilioVideoEventProducer.h"

@interface TwilioVideoPlugin : CDVPlugin<TwilioVideoEventProducerDelegate>
@property (nonatomic, strong) NSString *listenerCallbackID;
@end

