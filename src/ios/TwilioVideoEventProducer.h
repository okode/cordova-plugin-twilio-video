#import <Foundation/Foundation.h>

@protocol TwilioVideoEventProducerDelegate <NSObject>
- (void) onCallEvent:(NSString*)event;
@end

@interface TwilioVideoEventProducer : NSObject
@property (nonatomic, weak) id <TwilioVideoEventProducerDelegate> delegate;
+ (id)getInstance;
- (void)publishEvent:(NSString*)event;
@end
