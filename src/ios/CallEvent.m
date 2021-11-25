#import "CallEvent.h"
#import "TwilioVideoJsonConverter.h"

NSString * const EVENT_BAD_CONNECTION_REQUEST = @"BAD_CONNECTION_REQUEST";
NSString * const EVENT_OPENED = @"OPENED";
NSString * const EVENT_CONNECTED = @"CONNECTED";
NSString * const EVENT_CONNECT_FAILURE = @"CONNECT_FAILURE";
NSString * const EVENT_DISCONNECTED = @"DISCONNECTED";
NSString * const EVENT_DISCONNECTED_WITH_ERROR = @"DISCONNECTED_WITH_ERROR";
NSString * const EVENT_RECONNECTING = @"RECONNECTING";
NSString * const EVENT_RECONNECTED = @"RECONNECTED";
NSString * const EVENT_PARTICIPANT_CONNECTED = @"PARTICIPANT_CONNECTED";
NSString * const EVENT_PARTICIPANT_DISCONNECTED = @"PARTICIPANT_DISCONNECTED";
NSString * const EVENT_REMOTE_VIDEO_TRACK_ADDED = @"REMOTE_VIDEO_TRACK_ADDED";
NSString * const EVENT_REMOTE_VIDEO_TRACK_REMOVED = @"REMOTE_VIDEO_TRACK_REMOVED";
NSString * const EVENT_PERMISSIONS_REQUIRED = @"PERMISSIONS_REQUIRED";
NSString * const EVENT_HANG_UP = @"HANG_UP";
NSString * const EVENT_CLOSED = @"CLOSED";

@implementation CallEvent

- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class CallEvent"
                                 userInfo:nil];
    return nil;
}

- (id)initWithEventId:(NSString*)eventId error:(NSError*)error {
    if (eventId == NULL) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"eventId param cannot be NULL"
                                     userInfo:nil];
    }
    self.eventId = eventId;
    self.error = error;
    return self;
}

+ (id)of:(NSString*)eventId {
    return [[CallEvent alloc] initWithEventId:eventId error:NULL];
}

+ (id)of:(NSString*)eventId withError:(NSError*)error {
    return [[CallEvent alloc] initWithEventId:eventId error:error];
}

- (CallEvent *)withRoomCtx:(TVIRoom*)room {
    self.room = room;
    return self;
}

- (NSDictionary*)toJSON {
    return @{
        @"eventId": self.eventId,
        @"room": self.room != NULL ?
                [TwilioVideoJsonConverter convertRoomToDictionary:self.room]
                : [NSNull null],
        @"error": self.error != NULL ?
            [TwilioVideoJsonConverter convertErrorToDictionary:self.error]
            : [NSNull null]
    };
}

@end
