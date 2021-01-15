#import "TwilioVideoPermissions.h"

@implementation TwilioVideoPermissions

+ (BOOL)hasRequiredPermissions {
    AVAuthorizationStatus videoPermissionStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    AVAudioSessionRecordPermission audioPermissionStatus = [AVAudioSession sharedInstance].recordPermission;
    return videoPermissionStatus == AVAuthorizationStatusAuthorized && audioPermissionStatus == AVAudioSessionRecordPermissionGranted;
}

+ (void)hasVideoPermissions:(void (^)(BOOL))response {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL grantedCamera)
    {
        AVAuthorizationStatus videoPermissionStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        if (response) {
            response(videoPermissionStatus ==  AVAuthorizationStatusAuthorized);
        }
    }];
}

+ (void)requestRequiredPermissions:(void (^)(BOOL))response {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL grantedCamera)
    {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL grantedAudio) {
            if (response) { response(grantedAudio); }
        }];
    }];
}

@end
