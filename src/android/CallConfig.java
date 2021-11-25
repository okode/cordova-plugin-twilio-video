package org.apache.cordova.twiliovideo;

import org.json.JSONObject;

import java.io.Serializable;

/**
 * Created by rpanadero on 14/9/18.
 */

public class CallConfig implements Serializable {

    private static final String PRIMARY_COLOR_PROP = "primaryColor";
    private static final String SECONDARY_COLOR_PROP = "secondaryColor";
    private static final String HANG_UP_IN_APP = "hangUpInApp";
    private static final String DISABLE_BACK_BUTTON = "disableBackButton";

    private String primaryColorHex;
    private String secondaryColorHex;
    private boolean hangUpInApp;
    private boolean disableBackButton;

    public void parse(JSONObject config) {
        if (config == null) {
            return;
        }
        this.primaryColorHex = config.optString(PRIMARY_COLOR_PROP, null);
        this.secondaryColorHex = config.optString(SECONDARY_COLOR_PROP, null);
        this.hangUpInApp = config.optBoolean(HANG_UP_IN_APP, false);
        this.disableBackButton = config.optBoolean(DISABLE_BACK_BUTTON, false);
    }

    public String getPrimaryColorHex() {
        return this.primaryColorHex;
    }

    public String getSecondaryColorHex() {
        return this.secondaryColorHex;
    }

    public boolean isHangUpInApp() {
        return hangUpInApp;
    }

    public boolean isDisableBackButton() {
        return disableBackButton;
    }

}
