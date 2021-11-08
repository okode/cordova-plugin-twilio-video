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
    [dict setObject:[self convertRoomParticipantToDictionary:room.localParticipant] forKey:@"localParticipant"];
    NSMutableArray *remotePartipantsArray = [NSMutableArray new];
    for (TVIRemoteParticipant* remoteParticipant in room.remoteParticipants) {
        [remotePartipantsArray addObject:[self convertRoomParticipantToDictionary:remoteParticipant]];
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
    return dict;
}

@end
