package org.apache.cordova.twiliovideo;

import org.json.JSONObject;

import java.io.Serializable;

/**
 * Created by rpanadero on 14/9/18.
 */

public class CallConfig implements Serializable {

    private static final String PRIMARY_COLOR_PROP = "primaryColor";
    private static final String SECONDARY_COLOR_PROP = "secondaryColor";

    private String primaryColorHex;
    private String secondaryColorHex;

    public void parse(JSONObject config) {
        if (config == null) { return; }
        this.primaryColorHex = config.optString(PRIMARY_COLOR_PROP, null);
        this.secondaryColorHex = config.optString(SECONDARY_COLOR_PROP, null);
    }

    public String getPrimaryColorHex() {
        return this.primaryColorHex;
    }

    public String getSecondaryColorHex() {
        return this.secondaryColorHex;
    }
}
