var exec = require('cordova/exec');

exports.openRoom = function(token, room, success, error) {
    exec(success, error, 'TwilioVideoPlugin', 'openRoom', [token, room]);
};
