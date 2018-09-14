var exec = require('cordova/exec');

var TwilioVideo = function() {};

TwilioVideo.openRoom = function(token, room, eventCallback, config) {
    exec(function(e) {
        console.log("Twilio video event fired: " + e);
        if (eventCallback) {
            eventCallback(e);
        }
    }, null, 'TwilioVideoPlugin', 'openRoom', [token, room, config]);
};

module.exports = TwilioVideo;