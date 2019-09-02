package org.apache.cordova.twiliovideo;

import org.json.JSONObject;

public class TwilioVideoManager {

    private CallEventObserver eventListener;
    private CallActionObserver actionListener;
    private static TwilioVideoManager instance;

    public static TwilioVideoManager getInstance() {
        if (instance == null) {
            instance = new TwilioVideoManager();
        }
        return instance;
    }

    public void setEventObserver(CallEventObserver listener) {
        this.eventListener = listener;
    }

    public void setActionListenerObserver(CallActionObserver listener) {
        this.actionListener = listener;
    }

    public void publishEvent(CallEvent event) {
        publishEvent(event, null);
    }

    public void publishEvent(CallEvent event, JSONObject data) {
        if (hasEventListener()) {
            eventListener.onEvent(event.name(), data);
        }
    }

    public boolean publishDisconnection() {
        if (hasActionListener()) {
            actionListener.onDisconnect();
            return true;
        }
        return false;
    }

    private boolean hasEventListener() {
        return eventListener != null;
    }

    private boolean hasActionListener() {
        return actionListener != null;
    }

}
