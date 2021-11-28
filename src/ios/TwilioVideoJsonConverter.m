#import "TwilioVideoJsonConverter.h"

@implementation TwilioVideoJsonConverter

- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class TwilioVideoJsonConverter"
                                 userInfo:nil];
    return nil;
}

+ (NSDictionary*)convertErrorToDictionary:(NSError*)error {
    if (error == NULL) { return NULL; }
    return @{ @"code": [NSNumber numberWithInteger:[error code]], @"message": [error localizedDescription] };
}

+ (NSDictionary*)convertRoomToDictionary:(TVIRoom*)room {
    if (room == NULL) { return NULL; }
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:room.sid forKey:@"sid"];
    NSDictionary *participantDict = [self convertRoomParticipantToDictionary:room.localParticipant];
    [dict setObject:participantDict != NULL ? participantDict : [NSNull null] forKey:@"localParticipant"];
    NSMutableArray *remotePartipantsArray = [NSMutableArray new];
    if (room.remoteParticipants != NULL) {
        for (TVIRemoteParticipant* remoteParticipant in room.remoteParticipants) {
            [remotePartipantsArray addObject:[self convertRoomParticipantToDictionary:remoteParticipant]];
        }
    }
    [dict setObject:remotePartipantsArray forKey:@"remoteParticipants"];
    [dict setObject:[NSNumber numberWithInteger:room.state] forKey:@"state"];
    return dict;
}

+ (NSDictionary*)convertRoomParticipantToDictionary:(TVIParticipant*)participant {
    if (participant == NULL) { return NULL; }
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:participant.sid forKey:@"sid"];
    [dict setObject:[NSNumber numberWithInteger:participant.networkQualityLevel] forKey:@"networkQualityLevel"];
    [dict setObject:[NSNumber numberWithInteger:participant.state] forKey:@"state"];
    // Audio tracks
    NSMutableArray *audioTracksArray = [NSMutableArray new];
    if (participant.audioTracks != NULL) {
        for (TVIAudioTrackPublication* audioTrack in participant.audioTracks) {
            [audioTracksArray addObject:[self convertAudioTrackToDictionary:audioTrack]];
        }
    }
    [dict setObject:audioTracksArray forKey:@"audioTracks"];
    // Video tracks
    NSMutableArray *videoTracksArray = [NSMutableArray new];
    if (participant.videoTracks != NULL) {
        for (TVIVideoTrackPublication* videoTrack in participant.videoTracks) {
            [videoTracksArray addObject:[self convertVideoTrackToDictionary:videoTrack]];
        }
    }
    [dict setObject:videoTracksArray forKey:@"videoTracks"];
    return dict;
}

+ (NSDictionary*)convertAudioTrackToDictionary:(TVIAudioTrackPublication*)audioTrackPublication {
    NSDictionary *dict = [self convertTrackToDictionary:audioTrackPublication];
    if (dict == NULL) { return NULL; }

    NSMutableDictionary *mutableDict = [dict mutableCopy];
    TVIAudioTrack *audioTrack = [audioTrackPublication audioTrack];
    if (audioTrack == NULL) { return mutableDict; }

    [mutableDict setObject:[NSNumber numberWithBool:audioTrack.enabled] forKey:@"isAudioEnabled"];
    return mutableDict;
}

+ (NSDictionary*)convertVideoTrackToDictionary:(TVIVideoTrackPublication*)videoTrackPublication {
    NSDictionary *dict = [self convertTrackToDictionary:videoTrackPublication];
    if (dict == NULL) { return NULL; }

    NSMutableDictionary *mutableDict = [dict mutableCopy];
    TVIVideoTrack *videoTrack = [videoTrackPublication videoTrack];
    if (videoTrack == NULL) { return mutableDict; }

    [mutableDict setObject:[NSNumber numberWithBool:videoTrack.enabled] forKey:@"isVideoEnabled"];
    return mutableDict;
}

+ (NSDictionary*)convertTrackToDictionary:(TVITrackPublication*)track {
    if (track == NULL) { return NULL; }
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:track.trackSid forKey:@"sid"];
    [dict setObject:track.trackName forKey:@"name"];
    [dict setObject:[NSNumber numberWithBool:track.trackEnabled] forKey:@"isEnabled"];
    return dict;
}

@end
