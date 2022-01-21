package org.apache.cordova.twiliovideo;

import android.content.Context;
import android.util.Log;

import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.Volley;
import com.twilio.chat.CallbackListener;
import com.twilio.chat.Channel;
import com.twilio.chat.ChatClient;
import com.twilio.chat.ErrorInfo;
import com.twilio.chat.StatusListener;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

/**
 * Created by Ajay Makwana on 10/01/22.
 */
public class TwilioChatUnreadMessages extends CallbackListener<ChatClient> {
    private static Context mContext;
    private static int count = 0;
    private ChatClient mChatClient;
    private String mChannelId;
    private Channel mChannel;
    public MessageCountListener mListener;

    public TwilioChatUnreadMessages(Context context, String channelId, MessageCountListener listener) {
        this.mContext = context;
        this.mChannelId = channelId;
        this.mListener = listener;
    }

    public void getUnreadMessagesCount(final Channel currentChannel) {
                mListener.onMessageCount(count,currentChannel);
    }

    public void build(String accessToken) {
        ChatClient.Properties props =
                new ChatClient.Properties.Builder()
                        .setRegion("us1")
                        .createProperties();
        ChatClient.create(mContext.getApplicationContext(),
                accessToken,
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
            mChatClient.getChannels().getChannel(mChannelId
                    , new CallbackListener<Channel>() {
                        @Override
                        public void onSuccess(Channel channel) {
                            mChannel = channel;
                            mChannel.join(new StatusListener() {
                                @Override
                                public void onSuccess() {
                                    Log.d("TAG", "onSuccess: Channel Joined");
                                    mChannel.getMessages().setAllMessagesConsumedWithResult(new CallbackListener<Long>() {
                                        @Override
                                        public void onSuccess(Long aLong) {
                                            Log.e("TAG", "onSuccess: all messages consumed");
                                            getUnreadMessagesCount(mChannel);
                                        }

                                        @Override
                                        public void onError(ErrorInfo errorInfo) {
                                            Log.e("TAG", "onError: "+errorInfo.getMessage() );
                                            getUnreadMessagesCount(mChannel);
                                        }
                                    });
                                }

                                @Override
                                public void onError(ErrorInfo errorInfo) {
                                    if (errorInfo.getCode() == 50404) {
                                        Log.e("TAG", "onError: " + errorInfo.getMessage());
                                        getUnreadMessagesCount(mChannel);
                                    }
                                }
                            });
                        }

                        @Override
                        public void onError(ErrorInfo errorInfo) {
                            mChatClient.getChannels().createChannel(mChannelId, Channel.ChannelType.PRIVATE, new CallbackListener<Channel>() {
                                @Override
                                public void onSuccess(Channel channel) {
                                    mChannel = channel;
                                    Log.d("Chanelcreate",TwilioVideoActivity.userId);
                                    fetch(TwilioVideoActivity.userId);

                                }
                            });
                        }
                    });
        }
    }

    @Override
    public void onError(ErrorInfo errorInfo) {
        Log.e("TAG", "onError: " + errorInfo.getMessage());
    }


    public void fetch(String patientId) {
        JSONObject obj = new JSONObject(getTokenRequestParams(patientId));
        String requestUrl = "https://medicoparseserver.stg.iron.fit/api/doctor/private_chat/get_access_token?identity="+patientId;
        Log.d("TAG", "Requesting access token from: " + requestUrl);

        JsonObjectRequest jsonObjReq =
                new JsonObjectRequest(Request.Method.POST, requestUrl, obj, new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject response) {
                        String token = response.optJSONObject("data").optString("token");
                        build(token);
                    }
                }, new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                        Log.d("TAG", "onErrorResponse: "+error.getLocalizedMessage());
                    }
                });
        jsonObjReq.setShouldCache(false);
        Volley.newRequestQueue(mContext).add(jsonObjReq);
    }

    private Map<String, String> getTokenRequestParams(String patientId) {
        Map<String, String> params = new HashMap<>();
        params.put("identity", patientId);
        return params;
    }
}


