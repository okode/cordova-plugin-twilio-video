var exec = require('cordova/exec');

exports.openRoom = function(token, room, eventCallback, success, error) {
    exec(function(e) {
        console.log("Twilio video event fired");
        if (eventCallback) {
            eventCallback(e);
        }
    }, error, 'TwilioVideoPlugin', 'openRoom', [token, room]);
};
