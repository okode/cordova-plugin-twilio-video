var exec = require('cordova/exec');

var TwilioVideo = function() {};

TwilioVideo.openRoom = function(token, room, config, eventCallback) {
    config = config != null ? config : null;
    exec(function(e) {
        console.log("Twilio video event fired: " + e);
        if (eventCallback) {
            eventCallback(e);
        }
    }, null, 'TwilioVideoPlugin', 'openRoom', [token, room, config]);
};


TwilioVideo.closeRoom = function() {
    return new Promise(function(resolve, reject) {
        exec(function() {
            resolve();
        }, function(error) {
            reject(error);
        }, "TwilioVideoPlugin", "closeRoom", []);
    });
};

TwilioVideo.getRoom = function() {
    return new Promise(function(resolve, reject) {
        exec(function(result) {
            resolve(result);
        }, function(error) {
            reject(error);
        }, "TwilioVideoPlugin", "getRoom", []);
    });
};

TwilioVideo.hasRequiredVideoCallPermissions = function() {
    return new Promise(function(resolve, reject) {
        exec(function(result) {
            resolve(result);
        }, function(error) {
            reject(error);
        }, "TwilioVideoPlugin", "hasRequiredVideoCallPermissions", []);
    });
};

TwilioVideo.hasRequiredAudioCallPermissions = function() {
    return new Promise(function(resolve, reject) {
        exec(function(result) {
            resolve(result);
        }, function(error) {
            reject(error);
        }, "TwilioVideoPlugin", "hasRequiredAudioCallPermissions", []);
    });
};

TwilioVideo.requestRequiredVideoCallPermissions = function() {
    return new Promise(function(resolve, reject) {
        exec(function(result) {
            resolve(result);
        }, function(error) {
            reject(error);
        }, "TwilioVideoPlugin", "requestRequiredVideoCallPermissions", []);
    });
};

TwilioVideo.requestRequiredAudioCallPermissions = function() {
    return new Promise(function(resolve, reject) {
        exec(function(result) {
            resolve(result);
        }, function(error) {
            reject(error);
        }, "TwilioVideoPlugin", "requestRequiredAudioCallPermissions", []);
    });
};

module.exports = TwilioVideo;
