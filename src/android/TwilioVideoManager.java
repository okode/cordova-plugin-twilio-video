package org.apache.cordova.twiliovideo;

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
        if (hasEventListener()) {
            eventListener.onEvent(event);
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
