#import <Foundation/Foundation.h>
@import TwilioVideo;

// CALL EVENTS
extern NSString * const EVENT_BAD_CONNECTION_REQUEST;
extern NSString * const EVENT_OPENED;
extern NSString * const EVENT_CONNECTED;
extern NSString * const EVENT_CONNECT_FAILURE;
extern NSString * const EVENT_DISCONNECTED;
extern NSString * const EVENT_DISCONNECTED_WITH_ERROR;
extern NSString * const EVENT_RECONNECTING;
extern NSString * const EVENT_RECONNECTED;
extern NSString * const EVENT_PARTICIPANT_CONNECTED;
extern NSString * const EVENT_PARTICIPANT_DISCONNECTED;
extern NSString * const EVENT_REMOTE_VIDEO_TRACK_ADDED;
extern NSString * const EVENT_REMOTE_VIDEO_TRACK_REMOVED;
extern NSString * const EVENT_PERMISSIONS_REQUIRED;
extern NSString * const EVENT_HANG_UP;
extern NSString * const EVENT_CLOSED;

@interface CallEvent : NSObject

@property NSString *eventId;
@property TVIRoom *room;
@property NSError *error;

+ (id)of:(NSString*)eventId;
+ (id)of:(NSString*)eventId withError:(NSError*)error;
- (id)withRoomCtx:(TVIRoom*)room;
- (NSDictionary*)toJSON;

@end
