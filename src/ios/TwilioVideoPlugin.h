#import <Cordova/CDV.h>
#import "TwilioVideoViewController.h"
#import "TwilioVideoConfig.h"
#import "TwilioVideoCallManager.h"

@interface TwilioVideoPluginEvent: NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *data;
@end

@implementation TwilioVideoPluginEvent
@end

@interface TwilioVideoPlugin : CDVPlugin<TwilioVideoEventProducerDelegate>

@property (nonatomic, strong) NSString *listenerCallbackID;
@property (nonatomic, strong) NSString *pluginEventListenerCallbackId;
@property (nonatomic, strong) NSMutableArray<TwilioVideoPluginEvent*> *pendingPluginEvents;

- (void)addListener:(CDVInvokedUrlCommand*)command;
- (void)openRoom:(CDVInvokedUrlCommand*)command;
- (void)closeRoom:(CDVInvokedUrlCommand*)command;
- (void)displayIncomingCall:(CDVInvokedUrlCommand*)command;

@end

