package org.apache.cordova.twiliovideo;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;

import com.twilio.video.Room;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import static org.apache.cordova.twiliovideo.CallEventId.BAD_CONNECTION_REQUEST;

public class TwilioVideo extends CordovaPlugin {

    public static final String TAG = "TwilioPlugin";
    public static final String[] PERMISSIONS_REQUIRED = new String[]{
        Manifest.permission.CAMERA,
        Manifest.permission.RECORD_AUDIO
    };

    private static final int PERMISSIONS_REQUIRED_REQUEST_CODE = 1;

    private CallbackContext callbackContext;
    private CordovaInterface cordova;
    private String roomId;
    private String token;
    private CallConfig config = new CallConfig();

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        this.cordova = cordova;
    }

    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {
        this.callbackContext = callbackContext;
        switch (action) {
            case "openRoom":
                this.registerCallListener(callbackContext);
                this.openRoom(args);
                break;
            case "closeRoom":
                this.closeRoom(callbackContext);
                break;
            case "getRoom":
                this.getRoom(callbackContext);
                break;
            case "hasRequiredPermissions":
                this.hasRequiredPermissions(callbackContext);
                break;
            case "requestPermissions":
                this.requestRequiredPermissions();
                break;
        }
        return true;
    }

    private void getRoom(CallbackContext callbackContext) {
        Room currentVideocallRoom = TwilioVideoActivity.getVideocallRoomInstance();
        JSONObject res = TwilioVideoJsonConverter.convertRoomToJSON(currentVideocallRoom);
        if (res != null) {
          callbackContext.success(res);
        } else {
          callbackContext.success((String) null);
        }
    }

    public void openRoom(final JSONArray args) {
        try {
            this.token = args.getString(0);
            this.roomId = args.getString(1);
            this.config.parse(args.optJSONObject(2));

            LOG.d(TAG, "TOKEN: " + token);
            LOG.d(TAG, "ROOM_ID: " + roomId);

            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    Intent intentTwilioVideo = new Intent(Intent.ACTION_VIEW);
                    intentTwilioVideo.setClass(
                        cordova.getActivity().getBaseContext(),
                        TwilioVideoActivity.class
                    );
                    intentTwilioVideo.setPackage(
                        cordova.getActivity().getApplicationContext().getPackageName()
                    );
                    intentTwilioVideo.putExtra("token", token);
                    intentTwilioVideo.putExtra("roomId", roomId);
                    intentTwilioVideo.putExtra("config", config);
                    cordova.getActivity().startActivity(intentTwilioVideo);
                }
            });
        } catch (JSONException e) {
            Log.e(TAG, "Couldn't open room. No valid input params", e);
            TwilioVideoManager.getInstance().publishEvent(CallEvent.of(BAD_CONNECTION_REQUEST));
        }
    }

    private void registerCallListener(final CallbackContext callbackContext) {
        if (callbackContext == null) {
            return;
        }
        TwilioVideoManager.getInstance().setEventObserver(new CallEventObserver() {
            @Override
            public void onEvent(CallEvent event) {
                Log.i(TAG, String.format("Event received: %s", event));
                PluginResult result = new PluginResult(PluginResult.Status.OK, event.toJSON());
                result.setKeepCallback(true);
                callbackContext.sendPluginResult(result);
            }
        });
    }

    private void closeRoom(CallbackContext callbackContext) {
        if (TwilioVideoManager.getInstance().publishDisconnection()) {
            callbackContext.success();
        } else {
            callbackContext.error("Twilio video is not running");
        }
    }

    private void hasRequiredPermissions(CallbackContext callbackContext) {
        boolean hasRequiredPermissions = true;
        for (String permission : TwilioVideo.PERMISSIONS_REQUIRED) {
            hasRequiredPermissions = cordova.hasPermission(permission);
            if (!hasRequiredPermissions) {
                break;
            }
        }

        callbackContext.sendPluginResult(
            new PluginResult(PluginResult.Status.OK, hasRequiredPermissions)
        );
    }

    private void requestRequiredPermissions() {
        cordova.requestPermissions(
            this, PERMISSIONS_REQUIRED_REQUEST_CODE, PERMISSIONS_REQUIRED);
    }

    @Override
    public void onRequestPermissionResult(
        int requestCode,
        String[] permissions,
        int[] grantResults
    ) {
        if (requestCode == PERMISSIONS_REQUIRED_REQUEST_CODE) {
            boolean requiredPermissionsGranted = true;
            for (int grantResult : grantResults) {
                requiredPermissionsGranted &= grantResult == PackageManager.PERMISSION_GRANTED;
            }

            PluginResult result = new PluginResult(PluginResult.Status.OK,
                requiredPermissionsGranted);
            callbackContext.sendPluginResult(result);
        } else {
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, false));
        }
    }

    public Bundle onSaveInstanceState() {
        Bundle state = new Bundle();
        state.putString("token", this.token);
        state.putString("roomId", this.roomId);
        state.putSerializable("config", this.config);
        return state;
    }

    public void onRestoreStateForActivityResult(Bundle state, CallbackContext callbackContext) {
        this.token = state.getString("token");
        this.roomId = state.getString("roomId");
        this.config = (CallConfig) state.getSerializable("config");
        this.callbackContext = callbackContext;
    }

}
