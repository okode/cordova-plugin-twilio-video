package org.apache.cordova.twiliovideo;

import android.content.Context;

import com.twilio.audioswitch.AudioDevice;

import java.util.ArrayList;
import java.util.List;

public class TwilioVideoUtils {

    private TwilioVideoUtils() {
    }

    public static List<String> getAudioDeviceNames(
        Context context,
        List<AudioDevice> audioDevices
    ) {
        final ArrayList<String> audioDeviceNames = new ArrayList<>();

        if (audioDevices == null || audioDevices.isEmpty()) {
            return audioDeviceNames;
        }

        for (AudioDevice a : audioDevices) {
            String resourceStringKey = null;
            if (a instanceof AudioDevice.BluetoothHeadset) {
                resourceStringKey = "twilio_audio_bluetooth_device_name";
            } else if (a instanceof AudioDevice.WiredHeadset) {
                resourceStringKey = "twilio_audio_wired_headset_device_name";
            } else if (a instanceof AudioDevice.Speakerphone) {
                resourceStringKey = "twilio_audio_speakerphone_device_name";
            } else if (a instanceof AudioDevice.Earpiece) {
                resourceStringKey = "twilio_audio_earpiece_device_name";
            }

            // Zero means the resource doesn't exist
            int resId = resourceStringKey != null ?
                FakeR.getResourceId(context, "string", resourceStringKey) : 0;
            if (resId != 0) {
                String customDeviceName = context.getString(resId);
                audioDeviceNames.add(customDeviceName);
            } else {
                audioDeviceNames.add(a.getName());
            }
        }

        return audioDeviceNames;
    }

}