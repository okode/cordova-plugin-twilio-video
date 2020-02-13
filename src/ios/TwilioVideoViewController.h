//
//  TwilioVideoViewController.h
//

@import TwilioVideo;
@import UIKit;
@import CallKit;
#import "TwilioVideoEventManager.h"
#import "TwilioVideoCall.h"
#import "TwilioVideoPermissions.h"

@interface TwilioVideoViewController: UIViewController <TwilioVideoCallDelegate, TVIRemoteParticipantDelegate, TVICameraCapturerDelegate>

#pragma mark UI Element Outlets and handles

@property (nonatomic, strong) TwilioVideoCall *call;

@property (nonatomic, weak) TVIVideoView *remoteView;
@property (weak, nonatomic) IBOutlet TVIVideoView *previewView;

// UI Element Outlets and handles
@property (nonatomic, weak) IBOutlet UIButton *disconnectButton;
@property (nonatomic, weak) IBOutlet UIButton *micButton;
@property (nonatomic, weak) IBOutlet UILabel *roomLabel;
@property (nonatomic, weak) IBOutlet UILabel *roomLine;
@property (nonatomic, weak) IBOutlet UIButton *cameraSwitchButton;
@property (nonatomic, weak) IBOutlet UIButton *videoButton;

- (void)dismiss;

@end
