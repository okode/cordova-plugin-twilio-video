import android.content.Context;
import android.util.Log;

import com.twilio.chat.CallbackListener;
import com.twilio.chat.Channel;
import com.twilio.chat.ChatClient;
import com.twilio.chat.ErrorInfo;
import com.twilio.chat.StatusListener;

/**
 * Created by Ajay Makwana on 10/01/22.
 */
public class TwilioChatUnreadMessages extends CallbackListener<ChatClient> {
    private Context mContext;
    private ChatClient mChatClient;
    private String mToken, mChannelId;
    private Channel mChannel;
    private static int count = 0;

    public TwilioChatUnreadMessages(Context context, String token, String channelId) {
        this.mContext = context;
        this.mToken = token;
        this.mChannelId = channelId;
    }

    /// implementation "com.twilio:chat-android:6.0.0"

    public static int getUnreadMessages(){
        return count;
    }

    public getUnreadMessagesCount(Channel currentChannel) {
        currentChannel.getUnconsumedMessagesCount(new CallbackListener<Long>() {
            @Override
<<<<<<< HEAD
            public void onSuccess(Long unreadMessage) {
                count = unreadMessage == null ? 0 : unreadMessage.intValue();
<<<<<<< HEAD
                Log.d("Messages", "Messages Counts: Unread Messages Count : " + count);
                mListener.onMessageCount(count);
=======
            public void onSuccess(Long aLong) {
                Log.d("TAG", "Messages Counts: Unread Messages Count : " + aLong.intValue());
                count = aLong.intValue();
>>>>>>> parent of 76bcafd (- Handle Error response while joining channel.)
=======
                Log.d(TAG, "Messages Counts: Unread Messages Count : " + count);
>>>>>>> parent of 26b8255 (unread count)
            }
        });
    }

    public void build() {
        ChatClient.Properties props =
                new ChatClient.Properties.Builder()
                        .setRegion("us1")
                        .createProperties();
        ChatClient.create(mContext.getApplicationContext(),
                mToken,
                props,
                this);
    }

    @Override
    public void onSuccess(ChatClient chatClient) {
        mChatClient = chatClient;
        getOrCreateChannelFromChannelId(mChannelId);
    }

    private void getOrCreateChannelFromChannelId(final String mChannelId) {
        if (mChatClient != null) {
            mChatClient.getChannels().getChannel(mChannelId, new CallbackListener<Channel>() {
                @Override
                public void onSuccess(Channel channel) {
                    mChannel = channel;
                    mChannel.join(new StatusListener() {
                        @Override
                        public void onSuccess() {
                            Log.d(TAG, "onSuccess: Channel Joined");
                            getUnreadMessagesCount(mChannel);
                        }
<<<<<<< HEAD

                        @Override
                        public void onError(ErrorInfo errorInfo) {
                            if (errorInfo.getCode() == 50404) {
                                Log.e(TAG, "onError: " + errorInfo.getMessage());
                                getUnreadMessagesCount(mChannel);
                            }
                        }
=======
>>>>>>> parent of 76bcafd (- Handle Error response while joining channel.)
                    });
                }

                @Override
                public void onError(ErrorInfo errorInfo) {
                    mChatClient.getChannels().createChannel(mChannelId, Channel.ChannelType.PRIVATE, new CallbackListener<Channel>() {
                        @Override
                        public void onSuccess(Channel channel) {
                            mChannel = channel;
                            mChannel.join(new StatusListener() {
                                @Override
                                public void onSuccess() {
                                    Log.d(TAG, "onSuccess: Channel Created");
                                    getUnreadMessagesCount(mChannel);
                                }
<<<<<<< HEAD

                                @Override
                                public void onError(ErrorInfo errorInfo) {
                                    if (errorInfo.getCode() == 50404) {
                                        Log.e(TAG, "onError: " + errorInfo.getMessage());
                                        getUnreadMessagesCount(mChannel);
                                    }
                                }
=======
>>>>>>> parent of 76bcafd (- Handle Error response while joining channel.)
                            });
                        }
                    });
                }
            });
        }
    }

    @Override
    public void onError(ErrorInfo errorInfo) {
        Log.e(TAG, "onError: " + errorInfo.getMessage());
    }
}
