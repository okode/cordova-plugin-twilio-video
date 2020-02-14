var exec = require('cordova/exec');

var TwilioVideo = function() {};

TwilioVideo.openRoom = function(token, room, eventCallback, config) {
    config = config != null ? config : null;
    exec(function(e) {
        console.log("Twilio video event fired: " + e);
        if (eventCallback) {
            eventCallback(e.event, e.data);
        }
    }, null, 'TwilioVideoPlugin', 'openRoom', [token, room, config]);
};

TwilioVideo.closeRoom = function(callUUID) {
    return new Promise(function(resolve, reject) {
        exec(function() {
            resolve();
        }, function(error) {
            reject(error);
        }, "TwilioVideoPlugin", "closeRoom", [callUUID]);
    });
};

TwilioVideo.displayIncomingCall = function(callUUID, eventCallback, errorCallback) {
    exec(function(e) {
        console.log("Twilio video event fired: " + e);
        if (eventCallback) {
            eventCallback(e.event, e.data);
        }
    }, function(error) {
        console.log("Error displaying incoming call", error);
        if (eventCallback) {
            errorCallback(error);
        }
    }, 'TwilioVideoPlugin', 'displayIncomingCall', [callUUID]);    
};

TwilioVideo.addListener = function(eventCallback) {
    exec(function(e) {
      console.log("Firing document event: " + e.event + " with data " + JSON.stringify(e.data));
      if (eventCallback) {
        eventCallback(e.event, e.data);
      }
    }, null, "TwilioVideoPlugin", "addListener", []);
};

TwilioVideo.hasRequiredPermissions = function() {
    return new Promise(function(resolve, reject) {
        exec(function(result) {
            resolve(result);
        }, function(error) {
            reject(error);
        }, "TwilioVideoPlugin", "hasRequiredPermissions", []);
    });
};

TwilioVideo.requestPermissions = function() {
    return new Promise(function(resolve, reject) {
        exec(function(result) {
            resolve(result);
        }, function(error) {
            reject(error);
        }, "TwilioVideoPlugin", "requestPermissions", []);
    });
};

module.exports = TwilioVideo;
