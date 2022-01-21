package org.apache.cordova.twiliovideo;

import com.twilio.chat.Channel;

public interface MessageCountListener {
    void onMessageCount(int count, Channel channel);
}
