package org.apache.cordova.twiliovideo;

import org.json.JSONObject;

public class TwilioVideoManager {

    private org.apache.cordova.twiliovideo.CallEventObserver eventListener;
    private org.apache.cordova.twiliovideo.CallActionObserver actionListener;
    private static TwilioVideoManager instance;

    public static TwilioVideoManager getInstance() {
        if (instance == null) {
            instance = new TwilioVideoManager();
        }
        return instance;
    }

    public void setEventObserver(org.apache.cordova.twiliovideo.CallEventObserver listener) {
        this.eventListener = listener;
    }

    public void setActionListenerObserver(org.apache.cordova.twiliovideo.CallActionObserver listener) {
        this.actionListener = listener;
    }

    public void publishEvent(org.apache.cordova.twiliovideo.CallEvent event) {
        publishEvent(event, null);
    }

    public void publishEvent(String event) {
        publishEvent(event, null);
    }

    public void publishEvent(org.apache.cordova.twiliovideo.CallEvent event, JSONObject data) {
        if (hasEventListener()) {
            eventListener.onEvent(event.name(), data);
        }
    }

    public void publishEvent(String event, JSONObject data) {
        if (hasEventListener()) {
            eventListener.onEvent(event, data);
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
