#import "TwilioVideoPlugin.h"
#import <AVFoundation/AVFoundation.h>

@implementation TwilioVideoPlugin

#pragma mark - Plugin Initialization

- (id)init {
    self = [super init];
    
    self.pendingPluginEvents = [NSMutableArray new];
        
    return self;
}

- (void)pluginInitialize
{
    [[TwilioVideoEventManager getInstance] setEventDelegate:self];
}

- (void)addListener:(CDVInvokedUrlCommand*)command {
    self.pluginEventListenerCallbackId = command.callbackId;
    if ([self.pendingPluginEvents count] > 0) {
        for (TwilioVideoPluginEvent *event in self.pendingPluginEvents) {
            [self sendEvent:self.pluginEventListenerCallbackId with:event.name data: event.data];
        }
        [self.pendingPluginEvents removeAllObjects];
    }
}

- (void)openRoom:(CDVInvokedUrlCommand*)command {
    self.listenerCallbackID = command.callbackId;
    NSArray *args = command.arguments;
    NSString* token = args[0];
    NSString* room = args[1];
    TwilioVideoConfig *config = [[TwilioVideoConfig alloc] init];
    if ([args count] > 2) {
        [config parse: command.arguments[2]];
    }
    
    TwilioVideoCall *call = [[TwilioVideoCall alloc] initWithUUID:[NSUUID new] room:room token:token isCallKitCall:false];
    call.config = config;
    
    [TwilioVideoCallManager getInstance].answerCall = call;

    dispatch_async(dispatch_get_main_queue(), ^{
        TwilioVideoViewController *vc = [self getTwilioVideoController: call];
        [self.viewController presentViewController:vc animated:NO completion:^{
            [TwilioVideoPermissions requestRequiredPermissions:^(BOOL grantedPermissions) {
                 if (grantedPermissions) {
                     [call connectToRoom:^(BOOL connected, NSError * _Nullable error) {
                         if (connected) {
                             NSLog(@"Connected twilio video");
                         } else {
                             NSLog(@"Error connecting twilio video. Error: %@", error ? error.description : @"");
                         }
                     }];
                 } else {
                     [[TwilioVideoEventManager getInstance] publishCallEvent: CALL_PERMISSIONS_REQUIRED];
                     [vc dismiss];
                 }
            }];
        }];
    });
}

- (void)closeRoom:(CDVInvokedUrlCommand*)command {
    if ([[TwilioVideoEventManager getInstance] publishDisconnection]) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
    } else {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Twilio video is not running"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
}

- (void)displayIncomingCall:(CDVInvokedUrlCommand*)command {
    self.listenerCallbackID = command.callbackId;
    NSArray *args = command.arguments;
    NSString* callUuid = args[0];
    
    TwilioVideoCall *call = [[TwilioVideoCallManager getInstance] callWithUUID:[[NSUUID alloc] initWithUUIDString:callUuid]];
    
    if (call == nil) {
        NSLog(@"Unknown twilio video call");
        return;
    }
        
    dispatch_async(dispatch_get_main_queue(), ^{
        TwilioVideoViewController *vc = [self getTwilioVideoController: call];
        [self.viewController presentViewController:vc animated:NO completion:^{
            NSLog(@"Displayed incoming call");
        }];
    });
}

- (void)hasRequiredPermissions:(CDVInvokedUrlCommand*)command {
    BOOL hasRequiredPermissions = [TwilioVideoPermissions hasRequiredPermissions];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:hasRequiredPermissions] callbackId:command.callbackId];
}

- (void)requestPermissions:(CDVInvokedUrlCommand*)command {
    [TwilioVideoPermissions requestRequiredPermissions:^(BOOL grantedPermissions) {
                     [self.commandDelegate sendPluginResult:
         [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:grantedPermissions]
                                    callbackId:command.callbackId];
    }];
}

#pragma mark - Private

- (TwilioVideoViewController*)getTwilioVideoController:(TwilioVideoCall*)call {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"TwilioVideo" bundle:nil];
    TwilioVideoViewController *vc = [sb instantiateViewControllerWithIdentifier:@"TwilioVideoViewController"];
    vc.call = call;

    vc.view.backgroundColor = [UIColor clearColor];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;

    return vc;
}

- (void)sendEvent:(NSString*)callbackId with:(NSString *)event data:(NSDictionary*)data {
    if (!callbackId) {
        NSLog(@"Event listener callback unavailable %@. Event %@", callbackId, event);
        return;
    }

    if (data != NULL) {
        NSLog(@"Event received %@ with data %@", event, data);
    } else {
        NSLog(@"Event received %@", event);
    }
    
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    [message setValue:event forKey:@"event"];
    [message setValue:data != NULL ? data : [NSNull null] forKey:@"data"];
    
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
    [result setKeepCallbackAsBool:YES];
    
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

#pragma mark - TwilioVideoEventProducerDelegate

- (void)onCallEvent:(NSString *)event with:(NSDictionary*)data {
    [self sendEvent:self.listenerCallbackID with:event data:data];
}

- (void)onPluginEvent:(NSString *)eventName with:(NSDictionary*)data {
    if (self.pluginEventListenerCallbackId) {
        [self sendEvent:self.pluginEventListenerCallbackId with:eventName data:data];
    } else {
        TwilioVideoPluginEvent *event = [[TwilioVideoPluginEvent alloc] init];
        event.name = eventName;
        event.data = data;
        [self.pendingPluginEvents addObject:event];
    }
}

@end
