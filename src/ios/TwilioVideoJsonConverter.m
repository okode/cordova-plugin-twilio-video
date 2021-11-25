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
        for (TVITrackPublication* audioTrack in participant.audioTracks) {
            [audioTracksArray addObject:[self convertTrackToDictionary:audioTrack]];
        }
    }
    [dict setObject:audioTracksArray forKey:@"audioTracks"];
    // Video tracks
    NSMutableArray *videoTracksArray = [NSMutableArray new];
    if (participant.videoTracks != NULL) {
        for (TVITrackPublication* videoTrack in participant.videoTracks) {
            [videoTracksArray addObject:[self convertTrackToDictionary:videoTrack]];
        }
    }
    [dict setObject:videoTracksArray forKey:@"videoTracks"];
    return dict;
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
