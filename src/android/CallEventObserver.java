package org.apache.cordova.twiliovideo;

import org.json.JSONObject;

/**
 * Created by rpanadero on 13/9/18.
 */

public interface CallEventObserver {
    void onEvent(String event, JSONObject data);
}
