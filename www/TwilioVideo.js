var exec = require('cordova/exec');

var TwilioVideo = function() {};

TwilioVideo.openRoom = function(token, room, eventCallback) {
    exec(function(e) {
        console.log("Twilio video event fired: " + e);
        if (eventCallback) {
            eventCallback(e);
        }
    }, null, 'TwilioVideoPlugin', 'openRoom', [token, room]);
};

module.exports = TwilioVideo;