// Modified by OnSIP on 10/2/2014

var exec = require('cordova/exec');

var videoElements;

function getLayoutParams (videoElement) {
  var boundingRect = videoElement.getBoundingClientRect();
  return {
      // get these values by doing a lookup on the dom
      x : boundingRect.left,
      y : boundingRect.top,
      width : videoElement.offsetWidth,
      height : videoElement.offsetHeight
    };
}

exports.setDescription = function (options) {
  exec(
    options.callBack,
    null,
    'PhoneRTCPlugin',
    'setDescription',
    [JSON.stringify(options)]);
};

exports.getDescription = function (options) {
  var execOptions = options || {};
  if (options.video) {
    videoElements = {
      localVideo: options.video.localVideo,
      remoteVideo: options.video.remoteVideo
    };
    execOptions.video = {
      localVideo: getLayoutParams(videoElements.localVideo),
      remoteVideo: getLayoutParams(videoElements.remoteVideo)
    };
  }

  exec(
    function (data) {
      if (data.type === '__answered' && options.answerCallback) {
        options.answerCallback();
      } else if (data.type === '__disconnected' && options.disconnectCallback) {
        options.disconnectCallback();
      } else {
        options.sendMessageCallback(data);
      }
    },
    null,
    'PhoneRTCPlugin',
    'getDescription',
    [JSON.stringify(execOptions)]);
};

exports.setEnabledMedium = function (mediumType, enabled) {
  exec(
    function () {},
    null,
    'PhoneRTCPlugin',
    'setEnabledMedium',
    [mediumType, enabled]);
}

exports.receiveMessage = function (data) {
  exec(
    null,
    null,
    'PhoneRTCPlugin',
    'receiveMessage',
    [JSON.stringify(data)]);
};

exports.disconnect = function () {
  exec(
    null,
    null,
    'PhoneRTCPlugin',
    'disconnect',
    []);
};
