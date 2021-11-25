package org.apache.cordova.twiliovideo;

import android.util.Log;

import com.twilio.video.Room;
import com.twilio.video.TwilioException;

import org.json.JSONException;
import org.json.JSONObject;

public class CallEvent {
    private CallEventId eventId;
    private Room room;
    private TwilioException error;

    protected CallEvent(CallEventId eventId, TwilioException error) {
        if (eventId == null) {
            throw new IllegalArgumentException("eventId param cannot be NULL");
        }
        this.eventId = eventId;
        this.error = error;
    }

    public static CallEvent of(CallEventId eventId) {
        return new CallEvent(eventId, null);
    }

    public static CallEvent ofError(CallEventId eventId, TwilioException error) {
        return new CallEvent(eventId, error);
    }

    public CallEvent withRoomCtx(Room room) {
        this.room = room;
        return this;
    }

    public JSONObject toJSON() {
        JSONObject jsonObj = new JSONObject();
        try {
            jsonObj.putOpt("eventId", this.eventId.name());
            jsonObj.putOpt("room", TwilioVideoJsonConverter.convertRoomToJSON(this.room));
            jsonObj.putOpt("error",
                TwilioVideoJsonConverter.convertExceptionToJSON(this.error));
        } catch (JSONException e) {
            Log.e(TwilioVideo.TAG, "Error generating CallEvent JSON", e);
        }
        return jsonObj;
    }

    @Override
    public String toString() {
        return new StringBuilder("CallEvent{")
            .append("eventId=").append(eventId)
            .append(", room=").append(room != null ? room.getSid() : "none")
            .append(", error=").append("error")
            .append('}').toString();
    }

}
