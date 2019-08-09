package org.apache.cordova.twiliovideo;

import org.json.JSONObject;

import java.io.Serializable;

/**
 * Created by rpanadero on 14/9/18.
 */

public class CallConfig implements Serializable {

    private static final String PRIMARY_COLOR_PROP = "primaryColor";
    private static final String SECONDARY_COLOR_PROP = "secondaryColor";
    private static final String i18n_CONNECTION_ERROR_PROP = "i18nConnectionError";
    private static final String i18n_DISCONNECTED_WITH_ERROR_PROP = "i18nDisconnectedWithError";
    private static final String i18n_ACCEPT_PROP = "i18nAccept";
    private static final String HANDLE_ERROR_IN_APP = "handleErrorInApp";
    private static final String HANG_UP_IN_APP = "hangUpInApp";

    private static final String i18n_CONNECTION_ERROR_DEF_TEXT = "It was not possible to join the room";
    private static final String i18n_DISCONNECTED_WITH_ERROR_DEF_TEXT = "Disconnected";
    private static final String i18n_ACCEPT_DEF_TEXT = "Accept";

    private String primaryColorHex;
    private String secondaryColorHex;
    private String i18nConnectionError;
    private String i18nDisconnectedWithError;
    private String i18nAccept;
    private boolean handleErrorInApp;
    private boolean hangUpInApp;

    public void parse(JSONObject config) {
        if (config == null) { return; }
        this.primaryColorHex = config.optString(PRIMARY_COLOR_PROP, null);
        this.secondaryColorHex = config.optString(SECONDARY_COLOR_PROP, null);
        this.i18nConnectionError = config.optString(i18n_CONNECTION_ERROR_PROP, null);
        if (this.i18nConnectionError == null) {
            this.i18nConnectionError = i18n_CONNECTION_ERROR_DEF_TEXT;
        }
        this.i18nDisconnectedWithError = config.optString(i18n_DISCONNECTED_WITH_ERROR_PROP, null);
        if (this.i18nDisconnectedWithError == null) {
            this.i18nDisconnectedWithError = i18n_DISCONNECTED_WITH_ERROR_DEF_TEXT;
        }
        this.i18nAccept = config.optString(i18n_ACCEPT_PROP, null);
        if (this.i18nAccept == null) {
            this.i18nAccept = i18n_ACCEPT_DEF_TEXT;
        }
        this.handleErrorInApp = config.optBoolean(HANDLE_ERROR_IN_APP, false);
        this.hangUpInApp = config.optBoolean(HANG_UP_IN_APP, false);
    }

    public String getPrimaryColorHex() {
        return this.primaryColorHex;
    }

    public String getSecondaryColorHex() {
        return this.secondaryColorHex;
    }

    public String getI18nConnectionError() {
        return i18nConnectionError;
    }

    public String getI18nDisconnectedWithError() {
        return i18nDisconnectedWithError;
    }

    public String getI18nAccept() {
        return i18nAccept;
    }

    public boolean isHandleErrorInApp() {
        return handleErrorInApp;
    }

    public boolean isHangUpInApp() {
        return hangUpInApp;
    }
}
