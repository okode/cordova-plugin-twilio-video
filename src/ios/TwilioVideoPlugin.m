/********* TwilioVideo.m Cordova Plugin Implementation *******/

#import "TwilioVideoPlugin.h"

@implementation TwilioVideoPlugin

- (void)openRoom:(CDVInvokedUrlCommand*)command {
    NSString* token = command.arguments[0];
    NSString* room = command.arguments[1];
    self.listenerCallbackID = command.callbackId;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"TwilioVideo" bundle:nil];
        TwilioVideoViewController *vc = [sb instantiateViewControllerWithIdentifier:@"TwilioVideoViewController"];
        [vc setPluginInstance: self];
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

- (BOOL)notifyListener:(NSString *)event{
    if (!self.listenerCallbackID) {
        NSLog(@"Listener callback unavailable.  event %@", event);
        return NO;
    }
    
    NSLog(@"Event received %@", event);
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:event];
    [result setKeepCallbackAsBool:YES];
    
    [self.commandDelegate sendPluginResult:result callbackId:self.listenerCallbackID];
    return YES;
}

@end
