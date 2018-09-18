package org.apache.cordova.twiliovideo;

import org.apache.cordova.BuildHelper;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaResourceApi;
import org.apache.cordova.LOG;
import org.apache.cordova.PermissionHelper;
import org.apache.cordova.PluginResult;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import org.apache.cordova.twiliovideo.TwilioVideoActivity;
import org.json.JSONObject;


public class TwilioVideo extends CordovaPlugin {


    public CallbackContext callbackContext;
    private CordovaInterface cordova;
    private String roomId;
    private String token;
    private CallConfig config = new CallConfig();

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        this.cordova = cordova;
        // your init code here
    }

    
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
		this.callbackContext = callbackContext;
		if (action.equals("openRoom")) {
		    this.registerCallListener(callbackContext);
		   	this.openRoom(args);
		}
        return true;
	}

	public void openRoom(final JSONArray args) {
        try {
    	 	this.token = args.getString(0);
            this.roomId = args.getString(1);
            final CordovaPlugin that = this;
            final String token = this.token;
            final String roomId = this.roomId;
            if (args.length() > 2) {
                this.config.parse(args.getJSONObject(2));
            }

            LOG.d("TOKEN", token);
            LOG.d("ROOMID", roomId);
     		cordova.getThreadPool().execute(new Runnable() {
                public void run() {

                    Intent intentTwilioVideo = new Intent(that.cordova.getActivity().getBaseContext(), TwilioVideoActivity.class);
        			intentTwilioVideo.putExtra("token", token);
                    intentTwilioVideo.putExtra("roomId", roomId);
                    intentTwilioVideo.putExtra("config", config);
                    // avoid calling other phonegap apps
                    intentTwilioVideo.setPackage(that.cordova.getActivity().getApplicationContext().getPackageName());
                    //that.cordova.startActivityForResult(that, intentTwilioVideo);
                    //that.cordova.getActivity().startActivity(intentTwilioVideo);
                    that.cordova.startActivityForResult(that, intentTwilioVideo, 0);
                }
                    
            });
        } catch (JSONException e) {
            //Log.e(TAG, "Invalid JSON string: " + json, e);
            //return null;
        }
    }

    private void registerCallListener(final CallbackContext callbackContext) {
        if (callbackContext == null) {
            return;
        }
        CallEventsProducer.getInstance().setObserver(new CallObserver() {
            @Override
            public void onEvent(String event) {
                Log.i("TwilioEvents", "Event received: " + event);
                PluginResult result = new PluginResult(PluginResult.Status.OK, event);
                result.setKeepCallback(true);
                callbackContext.sendPluginResult(result);
            }
        });
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