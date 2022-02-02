#import "TwilioVideoViewController.h"

// CALL EVENTS
NSString *const OPENED = @"OPENED";
NSString *const CONNECTED = @"CONNECTED";
NSString *const CONNECT_FAILURE = @"CONNECT_FAILURE";
NSString *const DISCONNECTED = @"DISCONNECTED";
NSString *const DISCONNECTED_WITH_ERROR = @"DISCONNECTED_WITH_ERROR";
NSString *const RECONNECTING = @"RECONNECTING";
NSString *const RECONNECTED = @"RECONNECTED";
NSString *const PARTICIPANT_CONNECTED = @"PARTICIPANT_CONNECTED";
NSString *const PARTICIPANT_DISCONNECTED = @"PARTICIPANT_DISCONNECTED";
NSString *const AUDIO_TRACK_ADDED = @"AUDIO_TRACK_ADDED";
NSString *const AUDIO_TRACK_REMOVED = @"AUDIO_TRACK_REMOVED";
NSString *const VIDEO_TRACK_ADDED = @"VIDEO_TRACK_ADDED";
NSString *const VIDEO_TRACK_REMOVED = @"VIDEO_TRACK_REMOVED";
NSString *const PERMISSIONS_REQUIRED = @"PERMISSIONS_REQUIRED";
NSString *const HANG_UP = @"HANG_UP";
NSString *const CLOSED = @"CLOSED";
NSString *const ATTACHMENT = @"ATTACHMENT";

@implementation TwilioVideoViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[TwilioVideoManager getInstance] setActionDelegate:self];

    [[TwilioVideoManager getInstance] publishEvent: OPENED];
    [self.navigationController setNavigationBarHidden:YES animated:NO];

    [self logMessage:[NSString stringWithFormat:@"TwilioVideo v%@", [TwilioVideoSDK sdkVersion]]];

    // Configure access token for testing. Create one manually in the console
    // at https://www.twilio.com/console/video/runtime/testing-tools
    self.accessToken = @"TWILIO_ACCESS_TOKEN";

    // Preview our local camera track in the local video preview view.
    [self startPreview];

    // Disconnect and mic button will be displayed when client is connected to a room.
    self.micButton.hidden = YES;
    [self.micButton setImage:[UIImage imageNamed:@"mic"] forState: UIControlStateNormal];
    [self.micButton setImage:[UIImage imageNamed:@"no_mic"] forState: UIControlStateSelected];
    [self.videoButton setImage:[UIImage imageNamed:@"video"] forState: UIControlStateNormal];
    [self.videoButton setImage:[UIImage imageNamed:@"no_video"] forState: UIControlStateSelected];
    [self.attachmentButton setImage:[UIImage imageNamed:@"attach"] forState: UIControlStateSelected];
    [self.chatButton setImage:[UIImage imageNamed:@"chat"] forState: UIControlStateSelected];

    // Customize button colors
    NSString *primaryColor = [self.config primaryColorHex];
    if (primaryColor != NULL) {
        self.disconnectButton.backgroundColor = [TwilioVideoConfig colorFromHexString:primaryColor];
    }

    NSString *secondaryColor = [self.config secondaryColorHex];
    if (secondaryColor != NULL) {
        self.micButton.backgroundColor = [TwilioVideoConfig colorFromHexString:secondaryColor];
        self.videoButton.backgroundColor = [TwilioVideoConfig colorFromHexString:secondaryColor];
        self.cameraSwitchButton.backgroundColor = [TwilioVideoConfig colorFromHexString:secondaryColor];
        self.attachmentButton.backgroundColor = [TwilioVideoConfig colorFromHexString:secondaryColor];
        self.chatButton.backgroundColor = [TwilioVideoConfig colorFromHexString:secondaryColor];

    }
    
    [self setupAlertCtrl];
}

- (void) setupAlertCtrl
{
    self.alertCtrl = [UIAlertController alertControllerWithTitle:@""
                                                         message:nil
                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    //Create an action
    UIAlertAction *camera = [UIAlertAction actionWithTitle:@"Tire uma nova foto"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action)
                                                    {
                                                        [self handleCamera];
                                                    }];
    UIAlertAction *imageGallery = [UIAlertAction actionWithTitle:@"Selecione uma foto da Galeria"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action)
                                                    {
                                                        [self handleImageGallery];
                                                    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancelar"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action)
                                   {
                                       [self dismissViewControllerAnimated:YES completion:nil];
                                   }];


    //Add action to alertCtrl
    [self.alertCtrl addAction:camera];
    [self.alertCtrl addAction:imageGallery];
    [self.alertCtrl addAction:cancel];


}

- (void)handleCamera
{
#if TARGET_IPHONE_SIMULATOR
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:@"Camera is not available on simulator"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action)
                                                {
                                                    [self dismissViewControllerAnimated:YES completion:nil];
                                                }];

    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
#elif TARGET_OS_IPHONE
    //Some code for iPhone
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:self.imagePicker animated:YES completion:nil];

#endif
}

- (void)handleImageGallery
{
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.delegate = self;
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSData *dataImage = UIImageJPEGRepresentation([info objectForKey:@"UIImagePickerControllerOriginalImage"],1);
    NSString * base64String = [dataImage base64EncodedStringWithOptions:0];
    [[TwilioVideoManager getInstance] publishEvent: [NSString stringWithFormat:@"%@--%@", ATTACHMENT, base64String]];
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];

}

#pragma mark - Public

- (void)connectToRoom:(NSString*)room token:(NSString *)token {
    if ([room containsString:@":"]) {
        NSArray *arr = [room componentsSeparatedByString:@":"];
        
        if (arr.count > 0) {
            self.roomName = arr[0];
            
            if (arr.count > 1) {
                self.userId = arr[1];
            }
        }
    } else {
        self.roomName = room;
    }
    
    self.accessToken = token;
    [self showRoomUI:YES];

    [TwilioVideoPermissions requestRequiredPermissions:^(BOOL grantedPermissions) {
         if (grantedPermissions) {
             [self doConnect];
         } else {
             [[TwilioVideoManager getInstance] publishEvent: PERMISSIONS_REQUIRED];
             [self handleConnectionError: [self.config i18nConnectionError]];
         }
    }];
    
    [self getTokenFromUserId:self.userId ChannelName:self.roomName];
}

-(void)getTokenFromUserId:(NSString *)userId ChannelName:(NSString *)channelName {
    NSLog(@"%s userId: %@", __func__, userId);

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://medicoparseserver.stg.iron.fit/api/doctor/private_chat/get_access_token"]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:30.0];
    NSDictionary *headers = @{
        @"Content-Type": @"application/x-www-form-urlencoded",
    };
    [request setAllHTTPHeaderFields:headers];

    NSString *uuid = UIDevice.currentDevice.identifierForVendor.UUIDString;
  
    
    NSMutableData *postData = [[NSMutableData alloc] initWithData:[[NSString stringWithFormat:@"identity=%@", userId] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[NSString stringWithFormat:@"&device=%@", uuid] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    
    [[NSURLSession.sharedSession dataTaskWithRequest:request
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"%s error: %@", __func__, error);
            return;
        }
        
        if (data) {
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"%s result: %@", __func__, result);

            NSString *token = [result valueForKeyPath:@"data.token"];
            [self getUnreadMessagesCountWithToken:token ChannelName:channelName];
        }
        
    }] resume];
}

-(void)getUnreadMessagesCountWithToken:(NSString *)token ChannelName:(NSString *)channelName {
    NSLog(@"%s token: %@, channelName: %@", __func__, token, channelName);

    if (!self.twilioMessageUtils) {
        self.twilioMessageUtils = [TwilioMessageUtils new];
    }
    
    [self.twilioMessageUtils getUnreadMessagesCountWithToken:token ChannelName:channelName completion:^(BOOL success, NSUInteger count) {
        NSLog(@"%s success: %d, unread messages: %lu", __func__, success, count);
        [self addBadgeOnChatButton:count withDisplayCount:NO];
    }];
}

-(void)addBadgeOnChatButton:(NSInteger)count withDisplayCount:(BOOL)isDisplayCount {
    NSLog(@"%s: count: %ld", __func__, count);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *lblCount = [self.chatButton.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            if ([evaluatedObject isKindOfClass:[UILabel class]]) {
                UILabel *lblAll = ((UILabel *)evaluatedObject);
                return [lblAll.accessibilityIdentifier isEqualToString:@"chat_badge"];
            }
            return NO;
        }]].firstObject;
        
        if (!lblCount) {
            CGFloat size = 20;
            CGFloat badgeX = self.chatButton.frame.size.width - size;
            lblCount = [[UILabel alloc] initWithFrame:CGRectMake(badgeX, 0, size, size)];
            lblCount.accessibilityIdentifier = @"chat_badge";
            lblCount.textColor = UIColor.whiteColor;
            lblCount.backgroundColor = UIColor.redColor;
            lblCount.textAlignment = NSTextAlignmentCenter;
            lblCount.clipsToBounds = YES;
            lblCount.layer.cornerRadius = lblCount.bounds.size.height / 2.0;
        }
       
        if (isDisplayCount) {
            lblCount.text = [NSString stringWithFormat:@"%lu", count];
        }
        [lblCount setHidden:count == 0];
        [self.chatButton addSubview:lblCount];
        self.chatButton.clipsToBounds = NO;
    });
}

- (IBAction)disconnectButtonPressed:(id)sender {
    if ([self.config hangUpInApp]) {
        [[TwilioVideoManager getInstance] publishEvent: HANG_UP];
    } else {
        [self onDisconnect];
    }
}

- (IBAction)micButtonPressed:(id)sender {
    // We will toggle the mic to mute/unmute and change the title according to the user action.

    if (self.localAudioTrack) {
        self.localAudioTrack.enabled = !self.localAudioTrack.isEnabled;
        // If audio not enabled, mic is muted and button crossed out
        [self.micButton setSelected: !self.localAudioTrack.isEnabled];
    }
}

- (IBAction)cameraSwitchButtonPressed:(id)sender {
    [self flipCamera];
}

- (IBAction)cameraAttachmentButtonPressed:(id)sender {
    [self presentViewController:self.alertCtrl animated:YES completion:nil];

}

- (IBAction)videoButtonPressed:(id)sender {
    if(self.localVideoTrack){
        self.localVideoTrack.enabled = !self.localVideoTrack.isEnabled;
        [self.videoButton setSelected: !self.localVideoTrack.isEnabled];
    }
}

- (IBAction)chatButtonPressed:(id)sender {
    [self openWebView];
    
    //Hide badge on chat button
    [self addBadgeOnChatButton:0 withDisplayCount:NO];
}

- (void) openWebView {
    self.productURL = [NSString stringWithFormat:@"https://adma.stg.iron.fit/chat/%@/%@", self.userId, self.roomName];
    
    NSURL *url = [NSURL URLWithString:self.productURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
//    _webView = [[WKWebView alloc] initWithFrame:self.view.frame];
//    [_webView loadRequest:request];
//    _webView.navigationDelegate = self;
//    _webView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height+40);
//    [self animateViewHeight:_webView withAnimationType:kCATransitionFromTop isChatClose:NO];
    
    
    _webView = [[WKWebView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height)];
    [_webView loadRequest:request];
    _webView.navigationDelegate = self;
    _webView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height+40);
    [self animateViewHeight:_webView withAnimationType:kCATransitionFromTop isChatClose:NO];
    
    
    
    [self createCloseButton];
}

- (void) createCloseButton {
    
//    UINavigationBar* navbar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 64)];
//
//    UINavigationItem* navItem = [[UINavigationItem alloc] initWithTitle:@""];
//    [navbar setBarTintColor:[UIColor whiteColor]];
//
//    UIImage* image3 = [UIImage imageNamed:@"close.png"];
//    CGRect frameimg = CGRectMake(0, 0, image3.size.width, image3.size.height);
//    UIButton *someButton = [[UIButton alloc] initWithFrame:frameimg];
//    [someButton setBackgroundImage:image3 forState:UIControlStateNormal];
//    [someButton addTarget:self action:@selector(btnCloseClicked:)
//         forControlEvents:UIControlEventTouchUpInside];
//    [someButton setShowsTouchWhenHighlighted:YES];
//
//    UIBarButtonItem *mailbutton =[[UIBarButtonItem alloc] initWithCustomView:someButton];
//    navItem.rightBarButtonItem=mailbutton;
//
//    [navbar setItems:@[navItem]];
    
    
    _navigationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70)];
    _navigationView.backgroundColor=[UIColor whiteColor];
    
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(btnCloseClicked:) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"close.png"] forState:UIControlStateNormal];
    button.frame = CGRectMake(_navigationView.frame.size.width - 50, 30.0, 40.0, 40.0);
    [_navigationView addSubview:button];
    
    [self.view addSubview: _navigationView];
    
//    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
//    [button addTarget:self action:@selector(btnCloseClicked:) forControlEvents:UIControlEventTouchUpInside];
//    [button setImage:[UIImage imageNamed:@"close.png"] forState:UIControlStateNormal];
//    button.frame = CGRectMake(_webView.frame.size.width - 50, 30.0, 40.0, 40.0);
//    [_webView addSubview:button];
}

- (void)btnCloseClicked:(UIButton*)button{
    [_navigationView setHidden:true];
    [self animateViewHeight:self.view withAnimationType:kCATransitionFromBottom isChatClose:YES];
       //Hide badge on chat button
    [self addBadgeOnChatButton:0 withDisplayCount:NO];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"finish load");
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"fail to load with error : %@", error.localizedDescription);
}

- (void)animateViewHeight:(UIView*)animateView withAnimationType:(NSString*)animType isChatClose:(BOOL)isClose {
    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionPush];
    [animation setSubtype:animType];
    [animation setDuration:0.5];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[animateView layer] addAnimation:animation forKey:kCATransition];
    
    if (isClose) {
        for (id child in [animateView subviews]) {
            if ([child isMemberOfClass:[WKWebView class]]) {
                [child removeFromSuperview];
            }
        }
        
        for (id child in [_webView subviews]) {
            if ([child isMemberOfClass:[UIButton class]]) {
                [child removeFromSuperview];
            }
        }
    } else {
        [self.view addSubview:animateView];
    }
}

#pragma mark - Private

- (BOOL)isSimulator {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    return NO;
}

- (void)startPreview {
    // TVICameraCapturer is not supported with the Simulator.
    if ([self isSimulator]) {
        [self.previewView removeFromSuperview];
        return;
    }

    AVCaptureDevice *frontCamera = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionFront];
    AVCaptureDevice *backCamera = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionBack];

    if (frontCamera != nil || backCamera != nil) {
        self.camera = [[TVICameraSource alloc] initWithDelegate:self];
        self.localVideoTrack = [TVILocalVideoTrack trackWithSource:self.camera
                                                             enabled:YES
                                                                name:@"Camera"];
        if (!self.localVideoTrack) {
            [self logMessage:@"Failed to add video track"];
        } else {
            // Add renderer to video track for local preview
            [self.localVideoTrack addRenderer:self.previewView];

            [self logMessage:@"Video track created"];

            if (frontCamera != nil && backCamera != nil) {
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(flipCamera)];
                [self.previewView addGestureRecognizer:tap];
                self.cameraSwitchButton.hidden = NO;
            }

            self.videoButton.hidden = NO;

            [self.camera startCaptureWithDevice:frontCamera != nil ? frontCamera : backCamera
                 completion:^(AVCaptureDevice *device, TVIVideoFormat *format, NSError *error) {
                     if (error != nil) {
                         [self logMessage:[NSString stringWithFormat:@"Start capture failed with error.\ncode = %lu error = %@", error.code, error.localizedDescription]];
                     } else {
                         self.previewView.mirror = (device.position == AVCaptureDevicePositionFront);
                     }
            }];
        }
    } else {
       [self logMessage:@"No front or back capture device found!"];
   }
}

- (void)flipCamera {
    AVCaptureDevice *newDevice = nil;

    if (self.camera.device.position == AVCaptureDevicePositionFront) {
        newDevice = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionBack];
    } else {
        newDevice = [TVICameraSource captureDeviceForPosition:AVCaptureDevicePositionFront];
    }

    if (newDevice != nil) {
        [self.camera selectCaptureDevice:newDevice completion:^(AVCaptureDevice *device, TVIVideoFormat *format, NSError *error) {
            if (error != nil) {
                [self logMessage:[NSString stringWithFormat:@"Error selecting capture device.\ncode = %lu error = %@", error.code, error.localizedDescription]];
            } else {
                self.previewView.mirror = (device.position == AVCaptureDevicePositionFront);
            }
        }];
    }
}

- (void)prepareLocalMedia {

    // We will share local audio and video when we connect to room.

    // Create an audio track.
    if (!self.localAudioTrack) {
        self.localAudioTrack = [TVILocalAudioTrack trackWithOptions:nil
                                                            enabled:YES
                                                               name:@"Microphone"];

        if (!self.localAudioTrack) {
            [self logMessage:@"Failed to add audio track"];
        }
    }

    // Create a video track which captures from the camera.
    if (!self.localVideoTrack) {
        [self startPreview];
    }
}

- (void)doConnect {
    if ([self.accessToken isEqualToString:@"TWILIO_ACCESS_TOKEN"]) {
        [self logMessage:@"Please provide a valid token to connect to a room"];
        return;
    }

    // Prepare local media which we will share with Room Participants.
    [self prepareLocalMedia];

    TVIConnectOptions *connectOptions = [TVIConnectOptions optionsWithToken:self.accessToken
                                                                      block:^(TVIConnectOptionsBuilder * _Nonnull builder) {
                                                                          builder.roomName = self.roomName;
                                                                          // Use the local media that we prepared earlier.
                                                                          builder.audioTracks = self.localAudioTrack ? @[ self.localAudioTrack ] : @[ ];
                                                                          builder.videoTracks = self.localVideoTrack ? @[ self.localVideoTrack ] : @[ ];
                                                                      }];

    // Connect to the Room using the options we provided.
    self.room = [TwilioVideoSDK connectWithOptions:connectOptions delegate:self];

    [self logMessage:@"Attempting to connect to room"];
}

- (void)setupRemoteView {
    // Creating `TVIVideoView` programmatically
    TVIVideoView *remoteView = [[TVIVideoView alloc] init];

    // `TVIVideoView` supports UIViewContentModeScaleToFill, UIViewContentModeScaleAspectFill and UIViewContentModeScaleAspectFit
    // UIViewContentModeScaleAspectFit is the default mode when you create `TVIVideoView` programmatically.
    remoteView.contentMode = UIViewContentModeScaleAspectFill;

    [self.view insertSubview:remoteView atIndex:0];
    self.remoteView = remoteView;

    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1
                                                                constant:0];
    [self.view addConstraint:centerX];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1
                                                                constant:0];
    [self.view addConstraint:centerY];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeWidth
                                                            multiplier:1
                                                              constant:0];
    [self.view addConstraint:width];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.remoteView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeHeight
                                                             multiplier:1
                                                               constant:0];
    [self.view addConstraint:height];
}

// Reset the client ui status
- (void)showRoomUI:(BOOL)inRoom {
    self.micButton.hidden = !inRoom;
    [UIApplication sharedApplication].idleTimerDisabled = inRoom;
}

- (void)cleanupRemoteParticipant {
    if (self.remoteParticipant) {
        if ([self.remoteParticipant.videoTracks count] > 0) {
            TVIRemoteVideoTrack *videoTrack = self.remoteParticipant.remoteVideoTracks[0].remoteTrack;
            [videoTrack removeRenderer:self.remoteView];
            [self.remoteView removeFromSuperview];
        }
        self.remoteParticipant = nil;
    }
}

- (void)logMessage:(NSString *)msg {
    NSLog(@"%@", msg);
}

- (void)handleConnectionError: (NSString*)message {
    if ([self.config handleErrorInApp]) {
        [self logMessage: @"Error handling disabled for the plugin. This error should be handled in the hybrid app"];
        [self dismiss];
        return;
    }
    [self logMessage: @"Connection error handled by the plugin"];
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:NULL
                                 message: message
                                 preferredStyle:UIAlertControllerStyleAlert];

    //Add Buttons

    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:[self.config i18nAccept]
                                style:UIAlertActionStyleDefault
                                handler: ^(UIAlertAction * action) {
                                    [self dismiss];
                                }];

    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) dismiss {
    [[TwilioVideoManager getInstance] publishEvent: CLOSED];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:NO completion:nil];
    });
}

#pragma mark - TwilioVideoActionProducerDelegate

- (void)onDisconnect {
    if (self.room != NULL) {
        [self.room disconnect];
    }
}

#pragma mark - TVIRoomDelegate

- (void)didConnectToRoom:(nonnull TVIRoom *)room {
    // At the moment, this example only supports rendering one Participant at a time.
    [self logMessage:[NSString stringWithFormat:@"Connected to room %@ as %@", room.name, room.localParticipant.identity]];
    [[TwilioVideoManager getInstance] publishEvent: CONNECTED];

    if (room.remoteParticipants.count > 0) {
        self.remoteParticipant = room.remoteParticipants[0];
        self.remoteParticipant.delegate = self;
    }
}

- (void)room:(nonnull TVIRoom *)room didFailToConnectWithError:(nonnull NSError *)error {
    [self logMessage:[NSString stringWithFormat:@"Failed to connect to room, error = %@", error]];
    [[TwilioVideoManager getInstance] publishEvent: CONNECT_FAILURE with:[TwilioVideoUtils convertErrorToDictionary:error]];

    self.room = nil;

    [self showRoomUI:NO];
    [self handleConnectionError: [self.config i18nConnectionError]];
}

- (void)room:(nonnull TVIRoom *)room didDisconnectWithError:(nullable NSError *)error {
    [self logMessage:[NSString stringWithFormat:@"Disconnected from room %@, error = %@", room.name, error]];

    [self cleanupRemoteParticipant];
    self.room = nil;

    [self showRoomUI:NO];
    if (error != NULL) {
        [[TwilioVideoManager getInstance] publishEvent:DISCONNECTED_WITH_ERROR with:[TwilioVideoUtils convertErrorToDictionary:error]];
        [self handleConnectionError: [self.config i18nDisconnectedWithError]];
    } else {
        [[TwilioVideoManager getInstance] publishEvent: DISCONNECTED];
        [self dismiss];
    }
}

- (void)room:(nonnull TVIRoom *)room isReconnectingWithError:(nonnull NSError *)error {
    [[TwilioVideoManager getInstance] publishEvent: RECONNECTING with:[TwilioVideoUtils convertErrorToDictionary:error]];
}

- (void)didReconnectToRoom:(nonnull TVIRoom *)room {
    [[TwilioVideoManager getInstance] publishEvent: RECONNECTED];
}

- (void)room:(nonnull TVIRoom *)room participantDidConnect:(nonnull TVIRemoteParticipant *)participant {
    if (!self.remoteParticipant) {
        self.remoteParticipant = participant;
        self.remoteParticipant.delegate = self;
    }
    [self logMessage:[NSString stringWithFormat:@"Participant %@ connected with %lu audio and %lu video tracks",
                      participant.identity,
                      (unsigned long)[participant.audioTracks count],
                      (unsigned long)[participant.videoTracks count]]];
    [[TwilioVideoManager getInstance] publishEvent: PARTICIPANT_CONNECTED];
}

- (void)room:(nonnull TVIRoom *)room participantDidDisconnect:(nonnull TVIRemoteParticipant *)participant {
    if (self.remoteParticipant == participant) {
        [self cleanupRemoteParticipant];
    }
    [self logMessage:[NSString stringWithFormat:@"Room %@ participant %@ disconnected", room.name, participant.identity]];
    [[TwilioVideoManager getInstance] publishEvent: PARTICIPANT_DISCONNECTED];
}


#pragma mark - TVIRemoteParticipantDelegate

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didPublishVideoTrack:(nonnull TVIRemoteVideoTrackPublication *)publication {

    // Remote Participant has offered to share the video Track.

    [self logMessage:[NSString stringWithFormat:@"Participant %@ published %@ video track .",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didUnpublishVideoTrack:(nonnull TVIRemoteVideoTrackPublication *)publication {

    // Remote Participant has stopped sharing the video Track.

    [self logMessage:[NSString stringWithFormat:@"Participant %@ unpublished %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didPublishAudioTrack:(nonnull TVIRemoteAudioTrackPublication *)publication {

    // Remote Participant has offered to share the audio Track.

    [self logMessage:[NSString stringWithFormat:@"Participant %@ published %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didUnpublishAudioTrack:(nonnull TVIRemoteAudioTrackPublication *)publication {

    // Remote Participant has stopped sharing the audio Track.

    [self logMessage:[NSString stringWithFormat:@"Participant %@ unpublished %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)didSubscribeToVideoTrack:(nonnull TVIRemoteVideoTrack *)videoTrack
                     publication:(nonnull TVIRemoteVideoTrackPublication *)publication
                  forParticipant:(nonnull TVIRemoteParticipant *)participant {
    // We are subscribed to the remote Participant's audio Track. We will start receiving the
    // remote Participant's video frames now.

    [self logMessage:[NSString stringWithFormat:@"Subscribed to %@ video track for Participant %@",
                      publication.trackName, participant.identity]];
    [[TwilioVideoManager getInstance] publishEvent: VIDEO_TRACK_ADDED];

    if (self.remoteParticipant == participant) {
        [self setupRemoteView];
        [videoTrack addRenderer:self.remoteView];
    }
}

- (void)didUnsubscribeFromVideoTrack:(nonnull TVIRemoteVideoTrack *)videoTrack
                         publication:(nonnull TVIRemoteVideoTrackPublication *)publication
                      forParticipant:(nonnull TVIRemoteParticipant *)participant {

    // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
    // remote Participant's video.

    [self logMessage:[NSString stringWithFormat:@"Unsubscribed from %@ video track for Participant %@",
                      publication.trackName, participant.identity]];
    [[TwilioVideoManager getInstance] publishEvent: VIDEO_TRACK_REMOVED];

    if (self.remoteParticipant == participant) {
        [videoTrack removeRenderer:self.remoteView];
        [self.remoteView removeFromSuperview];
    }
}

- (void)didSubscribeToAudioTrack:(nonnull TVIRemoteAudioTrack *)audioTrack
                     publication:(nonnull TVIRemoteAudioTrackPublication *)publication
                  forParticipant:(nonnull TVIRemoteParticipant *)participant {

    // We are subscribed to the remote Participant's audio Track. We will start receiving the
    // remote Participant's audio now.

    [self logMessage:[NSString stringWithFormat:@"Subscribed to %@ audio track for Participant %@",
                      publication.trackName, participant.identity]];
    [[TwilioVideoManager getInstance] publishEvent: AUDIO_TRACK_ADDED];
}

- (void)didUnsubscribeFromAudioTrack:(nonnull TVIRemoteAudioTrack *)audioTrack
                         publication:(nonnull TVIRemoteAudioTrackPublication *)publication
                      forParticipant:(nonnull TVIRemoteParticipant *)participant {

    // We are unsubscribed from the remote Participant's audio Track. We will no longer receive the
    // remote Participant's audio.

    [self logMessage:[NSString stringWithFormat:@"Unsubscribed from %@ audio track for Participant %@",
                      publication.trackName, participant.identity]];
    [[TwilioVideoManager getInstance] publishEvent: AUDIO_TRACK_REMOVED];
}

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didEnableVideoTrack:(nonnull TVIRemoteVideoTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ enabled %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didDisableVideoTrack:(nonnull TVIRemoteVideoTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ disabled %@ video track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didEnableAudioTrack:(nonnull TVIRemoteAudioTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ enabled %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)remoteParticipant:(nonnull TVIRemoteParticipant *)participant didDisableAudioTrack:(nonnull TVIRemoteAudioTrackPublication *)publication {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ disabled %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)didFailToSubscribeToAudioTrack:(nonnull TVIRemoteAudioTrackPublication *)publication
                                 error:(nonnull NSError *)error
                        forParticipant:(nonnull TVIRemoteParticipant *)participant {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ failed to subscribe to %@ audio track.",
                      participant.identity, publication.trackName]];
}

- (void)didFailToSubscribeToVideoTrack:(nonnull TVIRemoteVideoTrackPublication *)publication
                                 error:(nonnull NSError *)error
                        forParticipant:(nonnull TVIRemoteParticipant *)participant {
    [self logMessage:[NSString stringWithFormat:@"Participant %@ failed to subscribe to %@ video track.",
                      participant.identity, publication.trackName]];
}

#pragma mark - TVIVideoViewDelegate

- (void)videoView:(nonnull TVIVideoView *)view videoDimensionsDidChange:(CMVideoDimensions)dimensions {
    NSLog(@"Dimensions changed to: %d x %d", dimensions.width, dimensions.height);
    [self.view setNeedsLayout];
}

#pragma mark - TVICameraSourceDelegate

- (void)cameraSource:(nonnull TVICameraSource *)source didFailWithError:(nonnull NSError *)error {
    [self logMessage:[NSString stringWithFormat:@"Capture failed with error.\ncode = %lu error = %@", error.code, error.localizedDescription]];
}

@end
