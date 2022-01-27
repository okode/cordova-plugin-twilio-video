//
//  TwilioMessageUtils.h
//  twiliochat
//
//  Created by theonetech on 06/01/22.
//  Copyright © 2022 Twilio. All rights reserved.
//

#import <Foundation/Foundation.h>
@import TwilioChatClient;

typedef void (^TMChatClientCompletion)(BOOL success, TwilioChatClient *client);
typedef void (^TMChatGetChannelCompletion)(BOOL success, TCHChannel *channel);
typedef void (^TMChatMessageCountCompletion)(BOOL success, NSUInteger count);

@interface TwilioMessageUtils : NSObject <TwilioChatClientDelegate, TCHChannelDelegate>

@property (strong, nonatomic) TwilioChatClient *client;
@property (strong, nonatomic) TCHChannel *channel;

- (void)getUnreadMessagesCountWithToken:(NSString *)token ChannelName:(NSString *)channelName completion:(TMChatMessageCountCompletion)completion;

@end
