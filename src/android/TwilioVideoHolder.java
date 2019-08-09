package org.apache.cordova.twiliovideo;

import org.apache.cordova.CordovaPlugin;

public class TwilioVideoHolder extends CordovaPlugin {

    private TwilioVideoActions videoInstance;

    private static TwilioVideoHolder instance;

    public static TwilioVideoHolder getInstance() {
        if (instance == null) {
            instance = new TwilioVideoHolder();
        }
        return instance;
    }

    public void setVideoInstance(TwilioVideoActions disposable) {
        this.videoInstance = disposable;
    }

    public TwilioVideoActions getVideoInstance() {
        return this.videoInstance;
    }

}