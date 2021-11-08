@import TwilioVideo;
@import UIKit;
#import "TwilioVideoManager.h"
#import "TwilioVideoConfig.h"
#import "TwilioVideoPermissions.h"

@interface TwilioVideoViewController: UIViewController <TVIRemoteParticipantDelegate, TVIRoomDelegate, TVIVideoViewDelegate, TVICameraSourceDelegate, TwilioVideoActionProducerDelegate>

// Configure access token manually for testing in `ViewDidLoad`, if desired! Create one manually in the console.
@property (nonatomic, strong) NSString *roomName;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) TwilioVideoConfig *config;

#pragma mark Video SDK components

@property (nonatomic, strong) TVICameraSource *camera;
@property (nonatomic, strong) TVILocalVideoTrack *localVideoTrack;
@property (nonatomic, strong) TVILocalAudioTrack *localAudioTrack;
@property (nonatomic, strong) TVIRemoteParticipant *remoteParticipant;
@property (nonatomic, weak) TVIVideoView *remoteView;

#pragma mark UI Element Outlets and handles

// `TVIVideoView` created from a storyboard
@property (weak, nonatomic) IBOutlet TVIVideoView *previewView;

@property (nonatomic, weak) IBOutlet UIButton *disconnectButton;
@property (nonatomic, weak) IBOutlet UIButton *micButton;
@property (nonatomic, weak) IBOutlet UIButton *cameraSwitchButton;
@property (nonatomic, weak) IBOutlet UIButton *videoButton;

- (void)connectToRoom:(NSString*)room token: (NSString *)token;
+ (TVIRoom*)getVideocallRoomInstance;

@end
