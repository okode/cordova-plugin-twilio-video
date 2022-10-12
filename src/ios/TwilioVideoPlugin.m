#import "TwilioVideoPlugin.h"
#import <AVFoundation/AVFoundation.h>

@implementation TwilioVideoPlugin

#pragma mark - Plugin Initialization
- (void)pluginInitialize
{
    [[TwilioVideoManager getInstance] setEventDelegate:self];
}

- (void)openRoom:(CDVInvokedUrlCommand*)command {
    self.listenerCallbackID = command.callbackId;
    NSArray *args = command.arguments;
    NSString* token = args[0];
    NSString* room = args[1];
    TwilioVideoConfig *config = [[TwilioVideoConfig alloc] init];
    [config parse:command.arguments[2]];

    if (token == NULL || room == NULL) {
        [[TwilioVideoManager getInstance] publishEvent:[CallEvent of:EVENT_BAD_CONNECTION_REQUEST]];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"TwilioVideo" bundle:nil];
        TwilioVideoViewController *vc = [sb instantiateViewControllerWithIdentifier:@"TwilioVideoViewController"];

        vc.config = config;

        vc.view.backgroundColor = [UIColor clearColor];
        vc.modalPresentationStyle = UIModalPresentationOverFullScreen;

        [self.viewController presentViewController:vc animated:NO completion:^{
            [vc connectToRoom:room token:token];
        }];
    });
}

- (void)closeRoom:(CDVInvokedUrlCommand*)command {
    if ([[TwilioVideoManager getInstance] publishDisconnection]) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
    } else {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Twilio video is not running"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
}

- (void)getRoom:(CDVInvokedUrlCommand*)command {
    TVIRoom *currentRoom = [TwilioVideoViewController getVideocallRoomInstance];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[TwilioVideoJsonConverter convertRoomToDictionary:currentRoom]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)hasRequiredVideoCallPermissions:(CDVInvokedUrlCommand*)command {
    BOOL hasRequiredVideoCallPermissions = [TwilioVideoPermissions hasRequiredVideoCallPermissions];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:hasRequiredVideoCallPermissions] callbackId:command.callbackId];
}

- (void)hasRequiredAudioCallPermissions:(CDVInvokedUrlCommand*)command {
    BOOL hasRequiredAudioCallPermissions = [TwilioVideoPermissions hasRequiredAudioCallPermissions];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:hasRequiredAudioCallPermissions] callbackId:command.callbackId];
}

- (void)requestRequiredVideoCallPermissions:(CDVInvokedUrlCommand*)command {
    [TwilioVideoPermissions requestRequiredVideoCallPermissions:^(BOOL grantedPermissions) {
                     [self.commandDelegate sendPluginResult:
         [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:grantedPermissions]
                                    callbackId:command.callbackId];
    }];
}

- (void)requestRequiredAudioCallPermissions:(CDVInvokedUrlCommand*)command {
    [TwilioVideoPermissions requestRequiredAudioCallPermissions:^(BOOL grantedPermissions) {
                     [self.commandDelegate sendPluginResult:
         [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:grantedPermissions]
                                    callbackId:command.callbackId];
    }];
}

#pragma mark - TwilioVideoEventProducerDelegate

- (void)onCallEvent:(CallEvent *)event {
    if (!self.listenerCallbackID) {
        NSLog(@"Listener callback unavailable.  event %@", event);
        return;
    }

    NSLog(@"Event received %@", event);

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[ event toJSON]];
    [result setKeepCallbackAsBool:YES];

    [self.commandDelegate sendPluginResult:result callbackId:self.listenerCallbackID];
}

@end
