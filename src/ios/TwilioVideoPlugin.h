#import <Cordova/CDV.h>
#import "TwilioVideoViewController.h"
#import "TwilioVideoConfig.h"
#import "TwilioVideoCallKit.h"

@interface TwilioVideoPlugin : CDVPlugin<TwilioVideoEventProducerDelegate>

@property (nonatomic, strong) NSString *listenerCallbackID;
@property (nonatomic, strong) NSString *pluginEventListenerCallbackId;
@property (nonatomic, strong) NSString *pendingPluginEventName;
@property (nonatomic, strong) NSDictionary *pendingPluginEventData;

- (void)addListener:(CDVInvokedUrlCommand*)command;
- (void)openRoom:(CDVInvokedUrlCommand*)command;
- (void)closeRoom:(CDVInvokedUrlCommand*)command;
- (void)displayIncomingCall:(CDVInvokedUrlCommand*)command;

@end

