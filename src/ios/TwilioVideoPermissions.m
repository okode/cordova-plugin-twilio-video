#import "TwilioVideoPermissions.h"

@implementation TwilioVideoPermissions

+ (BOOL)hasRequiredVideoCallPermissions {
    AVAuthorizationStatus videoPermissionStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    AVAudioSessionRecordPermission audioPermissionStatus = [AVAudioSession sharedInstance].recordPermission;
    return videoPermissionStatus == AVAuthorizationStatusAuthorized && audioPermissionStatus == AVAudioSessionRecordPermissionGranted;
}

+ (BOOL)hasRequiredAudioCallPermissions {
    AVAudioSessionRecordPermission audioPermissionStatus = [AVAudioSession sharedInstance].recordPermission;
    return audioPermissionStatus == AVAudioSessionRecordPermissionGranted;
}

+ (void)requestRequiredVideoCallPermissions:(void (^)(BOOL))response {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL grantedCamera)
    {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL grantedAudio) {
            if (response) { response(grantedAudio && grantedCamera); }
        }];
    }];
}

+ (void)requestRequiredAudioCallPermissions:(void (^)(BOOL))response {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL grantedAudio) {
        if (response) { response(grantedAudio); }
    }];
}

@end
