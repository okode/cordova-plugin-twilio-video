package org.apache.cordova.twiliovideo;

import android.util.Log;

import com.twilio.video.NetworkQualityLevel;
import com.twilio.video.Participant;
import com.twilio.video.Room;
import com.twilio.video.TrackPublication;
import com.twilio.video.TwilioException;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class TwilioVideoJsonConverter {

    private TwilioVideoJsonConverter() {
    }

    public static JSONObject convertExceptionToJSON(TwilioException e) {
        if (e == null) { return null; }
        JSONObject data = new JSONObject();
        try {
            data.put("code", e.getCode());
            data.put("description", e.getLocalizedMessage());
        } catch (JSONException e1) {
            Log.e(TwilioVideo.TAG, "Error converting Twilio exception to JSON", e);
        }
        return data;
    }

    public static JSONObject convertRoomToJSON(Room room) {
        if (room == null) {
            return null;
        }
        JSONObject roomJsonObj = new JSONObject();
        try {
            roomJsonObj.putOpt("sid", room.getSid());
            // Local participant
            roomJsonObj.putOpt(
                "localParticipant",
                convertRoomPartipantToJSON(room.getLocalParticipant())
            );
            // Remote participants
            JSONArray remoteParticipantsJsonArray = new JSONArray();
            if (room.getRemoteParticipants() != null) {
              for (Participant remoteParticipant : room.getRemoteParticipants()) {
                remoteParticipantsJsonArray.put(
                  convertRoomPartipantToJSON(remoteParticipant)
                );
              }
            }
            roomJsonObj.putOpt("remoteParticipants", remoteParticipantsJsonArray);
            // Room state
            Room.State roomState = room.getState();
            roomJsonObj.putOpt("state", roomState != null ? roomState.name() : null);
        } catch (JSONException e) {
            Log.e(TwilioVideo.TAG, "Error converting Twilio room to JSON", e);
        }
        return roomJsonObj;
    }

    private static JSONObject convertRoomPartipantToJSON(Participant participant) {
        if (participant == null) {
            return null;
        }
        JSONObject participantJsonObj = new JSONObject();
        NetworkQualityLevel networkQualityLevel = participant.getNetworkQualityLevel();
        Participant.State state = participant.getState();
        try {
          participantJsonObj.putOpt("sid", participant.getSid());
          participantJsonObj.putOpt(
                "networkQualityLevel",
                networkQualityLevel != null ? networkQualityLevel.name() : null
            );
            participantJsonObj.putOpt("state", state != null ? state.name() : null);
          // Audio tracks
          JSONArray audioTracksJsonArray = new JSONArray();
          if (participant.getAudioTracks() != null) {
            for (TrackPublication track : participant.getAudioTracks()) {
              audioTracksJsonArray.put(convertTrackToJSON(track));
            }
          }
          participantJsonObj.putOpt("audioTracks", audioTracksJsonArray);
          // Video tracks
          JSONArray videoTracksJsonArray = new JSONArray();
          if (participant.getVideoTracks() != null) {
            for (TrackPublication track : participant.getVideoTracks()) {
              videoTracksJsonArray.put(convertTrackToJSON(track));
            }
          }
          participantJsonObj.putOpt("videoTracks", videoTracksJsonArray);
        } catch (JSONException e) {
            Log.e(TwilioVideo.TAG, "Error converting Twilio participant to JSON", e);
        }
        return participantJsonObj;
    }

    private static JSONObject convertTrackToJSON(TrackPublication track) {
      if (track == null) {
        return null;
      }
      JSONObject trackJsonObj = new JSONObject();
      try {
        trackJsonObj.putOpt("sid", track.getTrackSid());
        trackJsonObj.putOpt("name", track.getTrackName());
        trackJsonObj.putOpt("isEnabled", track.isTrackEnabled());
      } catch (JSONException e) {
        Log.e(TwilioVideo.TAG, "Error converting Twilio track to JSON", e);
      }
      return trackJsonObj;
    }

}
