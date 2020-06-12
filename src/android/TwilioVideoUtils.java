package org.apache.cordova.twiliovideo;

import android.util.Log;

import com.twilio.video.TwilioException;

import org.json.JSONException;
import org.json.JSONObject;

public class TwilioVideoUtils {

    private TwilioVideoUtils() {}

    public static JSONObject convertToJSON(TwilioException e) {
        JSONObject data = null;
        try {
            data = new JSONObject();
            data.put("code", String.valueOf(e.getCode()));
            data.put("description", e.getLocalizedMessage());
        } catch (JSONException e1) {
            Log.e(TwilioVideo.TAG, "Error converting Twilio exception to JSON", e);
        }
        return data;
    }
}
