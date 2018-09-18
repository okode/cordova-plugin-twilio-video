/********* TwilioVideo.m Cordova Plugin Implementation *******/

#import "TwilioVideoPlugin.h"

@implementation TwilioVideoPlugin

#pragma mark - Plugin Initialization
- (void)pluginInitialize
{
    [[TwilioVideoEventProducer getInstance] setDelegate:self];
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

- (void) dismissTwilioVideoController {
    [self.viewController dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - TwilioVideoEventProducerDelegate

- (void)onCallEvent:(NSString *)event {
    if (!self.listenerCallbackID) {
        NSLog(@"Listener callback unavailable.  event %@", event);
        return;
    }
    
    NSLog(@"Event received %@", event);
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:event];
    [result setKeepCallbackAsBool:YES];
    
    [self.commandDelegate sendPluginResult:result callbackId:self.listenerCallbackID];
}

@end
