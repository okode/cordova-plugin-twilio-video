#import <Foundation/Foundation.h>
#import "CallEvent.h"

@protocol TwilioVideoEventProducerDelegate <NSObject>
- (void) onCallEvent:(CallEvent*)event;
@end

@protocol TwilioVideoActionProducerDelegate <NSObject>
- (void) onDisconnect;
@end

@interface TwilioVideoManager : NSObject

@property (nonatomic, weak) id <TwilioVideoEventProducerDelegate> eventDelegate;
@property (nonatomic, weak) id <TwilioVideoActionProducerDelegate> actionDelegate;

+ (id)getInstance;
- (void)publishEvent:(CallEvent*)event;
- (BOOL)publishDisconnection;

@end
