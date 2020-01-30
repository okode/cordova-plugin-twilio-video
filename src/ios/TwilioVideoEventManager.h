#import <Foundation/Foundation.h>

@protocol TwilioVideoEventProducerDelegate <NSObject>
- (void)onCallEvent:(NSString*)event with:(NSDictionary*)data;
- (void)onPluginEvent:(NSString*)event with:(NSDictionary*)data;
@end

@protocol TwilioVideoActionProducerDelegate <NSObject>
- (void)onDisconnect;
@end

@interface TwilioVideoEventManager : NSObject
@property (nonatomic, weak) id <TwilioVideoEventProducerDelegate> eventDelegate;
@property (nonatomic, weak) id <TwilioVideoActionProducerDelegate> actionDelegate;
+ (id)getInstance;
- (void)publishCallEvent:(NSString*)event;
- (void)publishCallEvent:(NSString*)event with:(NSDictionary*)data;
- (void)publishPluginEvent:(NSString*)event with:(NSDictionary*)data;
- (BOOL)publishDisconnection;
@end
