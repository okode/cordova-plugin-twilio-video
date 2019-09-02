#import <Foundation/Foundation.h>

@protocol TwilioVideoEventProducerDelegate <NSObject>
- (void) onCallEvent:(NSString*)event with:(NSDictionary*)data;
@end

@protocol TwilioVideoActionProducerDelegate <NSObject>
- (void) onDisconnect;
@end

@interface TwilioVideoManager : NSObject
@property (nonatomic, weak) id <TwilioVideoEventProducerDelegate> eventDelegate;
@property (nonatomic, weak) id <TwilioVideoActionProducerDelegate> actionDelegate;
+ (id)getInstance;
- (void)publishEvent:(NSString*)event;
- (void)publishEvent:(NSString*)event with:(NSDictionary*)data;
- (BOOL)publishDisconnection;
@end
