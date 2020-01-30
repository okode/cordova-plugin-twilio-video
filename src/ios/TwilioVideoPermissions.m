#import "TwilioVideoPermissions.h"

@implementation TwilioVideoPermissions

+ (BOOL)hasRequiredPermissions {
    AVAuthorizationStatus videoPermissionStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    AVAudioSessionRecordPermission audioPermissionStatus = [AVAudioSession sharedInstance].recordPermission;
    return videoPermissionStatus == AVAuthorizationStatusAuthorized && audioPermissionStatus == AVAudioSessionRecordPermissionGranted;
}

@end
