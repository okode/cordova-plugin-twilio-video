//
//  TwilioMessageUtils.m
//  twiliochat
//
//  Created by theonetech on 06/01/22.
//  Copyright © 2022 Twilio. All rights reserved.
//

#import "TwilioMessageUtils.h"

@implementation TwilioMessageUtils
{
    TMChatMessageCountCompletion unreadMessagesCountCompletionBlock;
}

#pragma mark- Client

- (void)initClientWithToken:(NSString *)token completion:(TMChatClientCompletion)completion {
    NSLog(@"%s token: %@", __func__, token);
    
    [TwilioChatClient chatClientWithToken:token
                               properties:nil
                                 delegate:self
                               completion:^(TCHResult * _Nonnull result, TwilioChatClient * _Nullable chatClient) {
        NSLog(@"%s result: %d, user: %@", __func__, result.isSuccessful, chatClient.user.friendlyName);
        if (result.isSuccessful) {
            self.client = chatClient;
        }
        completion(result.isSuccessful, chatClient);
    }];
}

#pragma mark- Channel

- (void)getChannelByName:(NSString *)channelName completion:(TMChatGetChannelCompletion)completion {
    NSLog(@"%s channelName: %@", __func__, channelName);
    
    [self.client.channelsList channelWithSidOrUniqueName:channelName completion:^(TCHResult * _Nonnull result, TCHChannel * _Nullable channel) {
        NSLog(@"%s result: %d, channel.uniqueName: %@", __func__, result.isSuccessful, channel.uniqueName);
        if (result.isSuccessful) {
            self.channel = channel;
        }
        completion(result.isSuccessful, channel);
    }];
}

- (void)createChannelByChannel:(NSString *)channelName completion:(TMChatGetChannelCompletion)completion {
    NSLog(@"%s channelName: %@", __func__, channelName);
    
    NSDictionary *options = @{
        TCHChannelOptionUniqueName: channelName,
        TCHChannelOptionType:@(TCHChannelTypePublic),
    };
    
    [self.client.channelsList createChannelWithOptions:options completion:^(TCHResult * _Nonnull result, TCHChannel * _Nullable channel) {
        if (result.isSuccessful) {
            self.channel = channel;
        }
        completion(result.isSuccessful, channel);
    }];
}

- (void)joinChannelByChannel:(TCHChannel *)channel completion:(TMChatGetChannelCompletion)completion {
    NSLog(@"%s uniqueName: %@", __func__, channel.uniqueName);
    
    [channel joinWithCompletion:^(TCHResult * _Nonnull result) {
        NSLog(@"%s result: %@, channel.uniqueName: %@", __func__, result, channel.uniqueName);
        if (result.resultCode == 50404) {
            completion(true, channel);
            return;
        }
        completion(result.isSuccessful, channel);
    }];
}

#pragma mark- Messages

- (void)getUnreadMessagesCountFromChannel:(TMChatMessageCountCompletion)completion {
    NSLog(@"%s", __func__);
    [self.channel getMessagesCountWithCompletion:^(TCHResult *result, NSUInteger messagesCount) {
        NSLog(@"%s result: %d, all messages: %lu", __func__, result.isSuccessful, messagesCount);
        [self.channel getUnconsumedMessagesCountWithCompletion:^(TCHResult *result, NSNumber *count) {
            NSLog(@"%s result: %d, 2 unread messages: %lu/%lu", __func__, result.isSuccessful, count.longValue, messagesCount);
            completion(result.isSuccessful, count.longValue);
        }];
    }];
}

- (void)getUnreadMessagesCountWithToken:(NSString *)token ChannelName:(NSString *)channelName completion:(TMChatMessageCountCompletion)completion {
    NSLog(@"%s", __func__);
    
    unreadMessagesCountCompletionBlock = completion;
    [self initClientWithToken:token completion:^(BOOL success, TwilioChatClient *client) {
        if (!client) {
            completion(false, 0);
            return;
        }
        
        [self getChannelByName:channelName completion:^(BOOL success, TCHChannel *channel) {
            if (channel) {
                [self joinChannelByChannel:channel completion:^(BOOL success, TCHChannel *channel) {
                    if (success) {
                        [self getUnreadMessagesCountFromChannel:^(BOOL successMessage, NSUInteger count) {
                            completion(successMessage, count);
                        }];
                        return;
                    }

                    completion(false, 0);
                }];
                return;
            }
            
            [self createChannelByChannel:channelName completion:^(BOOL success, TCHChannel *channel) {
                [self joinChannelByChannel:channel completion:^(BOOL success, TCHChannel *channel) {
                    if (success) {
                        [self getUnreadMessagesCountFromChannel:^(BOOL successMessage, NSUInteger count) {
                            completion(successMessage, count);
                        }];
                        return;
                    }
                    
                    completion(success, 0);
                }];
                return;
            }];
        }];
    }];
}

-(void)chatClient:(TwilioChatClient *)client connectionStateUpdated:(TCHClientConnectionState)state {
    NSLog(@"%s state: %ld", __func__, state);

}
-(void)chatClient:(TwilioChatClient *)client channel:(TCHChannel *)channel messageAdded:(TCHMessage *)message {
    NSLog(@"%s message: %@", __func__, message.body);
//    [self getUnreadMessagesCountFromChannel:^(BOOL success, NSUInteger count) {
//        NSLog(@"%s success: %d, unread messages: %lu", __func__, success, count);
//    }];
    
    //Show badge on chat button
    if (unreadMessagesCountCompletionBlock) {
        unreadMessagesCountCompletionBlock(true, 1);
    }
}
@end

