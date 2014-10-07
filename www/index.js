function newer (constructor) {
  return function() {
    var instance = Object.create(constructor.prototype);
    var result = constructor.apply(instance, arguments);
    return typeof result === 'object' ? result : instance;
  };
}

module.exports = function(SIP) {
var PhoneRTCMediaHandler = function (session, options) {
  var events = [
  ];
  options = options || {};

  this.logger = session.ua.getLogger('sip.invitecontext.mediahandler', session.id);
  this.session = session;
  this.ready = true;
  this.audioMuted = false;
  this.videoMuted = false;

  // old init() from here on
  var idx, length, server,
    servers = [],
    stunServers = options.stunServers || null,
    turnServers = options.turnServers || null,
    config = this.session.ua.configuration;
  this.RTCConstraints = options.RTCConstraints || {};

  if (!stunServers) {
    stunServers = config.stunServers;
  }

  if(!turnServers) {
    turnServers = config.turnServers;
  }

  /* Change 'url' to 'urls' whenever this issue is solved:
   * https://code.google.com/p/webrtc/issues/detail?id=2096
   */
  servers.push({'url': stunServers});

  length = turnServers.length;
  for (idx = 0; idx < length; idx++) {
    server = turnServers[idx];
    servers.push({
      'url': server.urls,
      'username': server.username,
      'credential': server.password
    });
  }

  this.initEvents(events);

  this.phonertc = {};
};

PhoneRTCMediaHandler.prototype = Object.create(SIP.MediaHandler.prototype, {
  render: {writable: true, value: function render () {
    // the PhoneRTC plugin currently takes care of rendering
    // but this needs to be defined since SIP.js calls it
  }},

// Functions the session can use
  isReady: {writable: true, value: function isReady () {
    return this.ready;
  }},

  close: {writable: true, value: function close () {
    this.logger.log('calling phonertc.disconnect()');
    cordova.plugins.phonertc.disconnect();
  }},

  /**
   * @param {Function} onSuccess
   * @param {Function} onFailure
   * @param {SIP.WebRTC.MediaStream | (getUserMedia constraints)} [mediaHint]
   *        the MediaStream (or the constraints describing it) to be used for the session
   */
  getDescription: {writable: true, value: function getDescription (onSuccess, onFailure, mediaHint) {
                    onFailure = onFailure;
                    mediaHint = mediaHint;
    if (!this.phonertc.role) {
      var callOptions = {
        turn: {
          host: 'turn:turn.example.com:3478',
          username: 'user',
          password: 'pass'
        },
        sendMessageCallback: this.phonertcSendMessageCallback.bind(this),
        answerCallback: function () {
          console.log('Callee answered!');
        },
        disconnectCallback: function () {
          console.log('Call disconnected!');
        }
      };
      if (mediaHint && mediaHint.constraints && mediaHint.constraints.video) {
        callOptions.video = {};
  
        if (mediaHint.render) {
          var localVideo = mediaHint.render.local && mediaHint.render.local.video;
          if (localVideo) {
            callOptions.video.localVideo = localVideo;
          }
  
          var remoteVideo = mediaHint.render.remote && mediaHint.render.remote.video;
          if (remoteVideo) {
            callOptions.video.remoteVideo = remoteVideo;
          }
        }
      }
      this.logger.log("XXX phonertcGetDescriptionCall");
      cordova.plugins.phonertc.getDescription(callOptions);
    }

    if (this.phonertc.localSdpComplete) {
      onSuccess(this.phonertc.localSdpComplete);
    } else {
      this.phonertc.onLocalSdpComplete = onSuccess;
    }
  }},

  phonertcSendMessageCallback: {writable: true, value: function phonertcSendMessageCallback (data) {
    this.logger.log("XXX phonertcSendMessageCallback: " + JSON.stringify(data, null, 2));
    if (['offer', 'answer'].indexOf(data.type) > -1) {
      this.phonertc.localSdp = data.sdp;
    }
    else if (data.type === 'candidate') {
      var candidate = "a=" + data.candidate + "\r\n";
      // Video comes before audio
      if (this.phonertc.localSdp.indexOf('m=video') < this.phonertc.localSdp.indexOf('m=audio')) {
        if (data.id === 'video') {
          this.phonertc.localSdp = this.phonertc.localSdp.replace(/m=audio.*/,candidate + "$&");
        } else {
          this.phonertc.localSdp += candidate;
        }
      } else {
        if(data.id === 'audio') {
          this.phonertc.localSdp = this.phonertc.localSdp.replace(/m=video.*/,candidate + "$&");
        } else {
          this.phonertc.localSdp += candidate;
        }
      }
    }
    else if (data.type === 'IceGatheringChange') {
      if (data.state === "COMPLETE") {
        if (this.phonertc.localSdpComplete) {
          return;
        }
        var sdp = this.phonertc.localSdp;
/*
        if (this.phonertc.role !== 'caller') {
          sdp = sdp.replace('a=setup:actpass', 'a=setup:passive');
        }
*/
        sdp = sdp.replace(/a=crypto.*\r\n/g, '');
        this.phonertc.localSdpComplete = sdp;
        if (this.phonertc.onLocalSdpComplete) {
          this.phonertc.onLocalSdpComplete(this.phonertc.localSdpComplete);
        }
        // make sure this only gets called once
        this.phonertc.onLocalSdpComplete = null;
      }
    }
  }},

  phonertcCall: {writable: true, value: function phonertcCall (remoteOffer, mediaHint) {
    var role = remoteOffer ? 'callee' : 'caller';
    this.logger.log("XXX phonertcCall: " + role);
    this.phonertc.role = role;

    var callOptions = {
      isInitiator: role === 'caller', // Caller or callee?
      turn: {
        host: 'turn:turn.example.com:3478',
        username: 'user',
        password: 'pass'
      },
      sendMessageCallback: this.phonertcSendMessageCallback.bind(this),
      answerCallback: function () {
        console.log('Callee answered!');
      },
      disconnectCallback: function () {
        console.log('Call disconnected!');
      }
    };

    if (remoteOffer) {
      callOptions.remoteOffer = remoteOffer;
    }

    if (mediaHint && mediaHint.constraints && mediaHint.constraints.video) {
      callOptions.video = {};

      if (mediaHint.render) {
        var localVideo = mediaHint.render.local && mediaHint.render.local.video;
        if (localVideo) {
          callOptions.video.localVideo = localVideo;
        }

        var remoteVideo = mediaHint.render.remote && mediaHint.render.remote.video;
        if (remoteVideo) {
          callOptions.video.remoteVideo = remoteVideo;
        }
      }
    }
    cordova.plugins.phonertc.call(callOptions);
  }},

  /**
  * Message reception.
  * @param {String} type
  * @param {String} sdp
  * @param {Function} onSuccess
  * @param {Function} onFailure
  */
  setDescription: {writable: true, value: function setDescription (sdp, onSuccess, onFailure) {
      var callOptions = {
      turn: {
        host: 'turn:turn.example.com:3478',
        username: 'user',
        password: 'pass'
      },
      callBack: onSuccess,
      sdp: sdp
      };
/*
      sendMessageCallback: this.phonertcSendMessageCallback.bind(this),
      answerCallback: function () {
        console.log('Callee answered!');
      },
      disconnectCallback: function () {
        console.log('Call disconnected!');
      }
    };
    callOptions.sdp = sdp;
*/
    cordova.plugins.phonertc.setDescription(callOptions);
/*
    var asyncSuccess = setTimeout.bind(window, onSuccess, 0);

    if (!this.phonertc.role) {
      
      this.phonertcCall(sdp);
      asyncSuccess();
    }
    else if (this.phonertc.role = 'caller') {
      this.logger.log("XXX setRemoteDescription: " + type + "\n" + sdp);
      cordova.plugins.phonertc.receiveMessage({type: 'answer', sdp: sdp});
      onSuccess();
    }
    else {
      this.logger.error('XXX setDescription called, but this.phonertc.role = ' + this.phonertc.role);
      onFailure();
    }
*/
  }},

// Functions the session can use, but only because it's convenient for the application
  mute: {writable: true, value: function mute (options) {
          options = options;
  }},

  unmute: {writable: true, value: function unmute (options) {
            options = options;
  }},
});

PhoneRTCMediaHandler = newer(PhoneRTCMediaHandler);
return PhoneRTCMediaHandler;
};
