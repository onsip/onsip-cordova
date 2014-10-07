OnSIP-Cordova
=============

A Cordova plugin that uses [SIP.js](http://sipjs.com/) with the [PhoneRTC plugin](https://github.com/alongubkin/phonertc) to make WebRTC calls over the internet.

Installation
-

Cordova Setup:
~~~
npm install -g cordova ios-deploy
~~~

Project Setup:
~~~
cordova create <name>
cd <name>
cordova platform add ios
cordova plugin add 
cordova run
~~~

Usage
-

Example:
~~~
<html>
  <body>
    <video id="localVideo"></video>
    <video id="remoteVideo"></video>
    <input id="target" type=text">
    <button id="makeCall">Make Call</button>
  </body>
  <script>
    document.addEventListener("deviceready", function() {
      var SIP = cordova.require("com.onsip.cordova.Sip.js");
      var PhoneRTCMediaHandler = cordova.require("com.onsip.cordova.SipjsMediaHandler")(SIP);
      
      window.ua = new SIP.UA({
        mediaHandlerFactory: PhoneRTCMediaHandler
      });
      
      document.getElementById("makeCall").addEventListener("click, function() {
        if (window.session) {
          alert("Only one call at a time.");
        }
        var options = {
          media : {
            constraints: {
              audio: true,
              video: true
            },
            render: {
              local: {
                video: document.getElementById('localVideo')
              },
              remote: {
                video: document.getElementById('remoteVideo')
              }
            }
          }
        }
        
        if (session) {
          session.accept(options);
          window.session = session;
        } else {
          window.session = window.ua.invite(document.getElementById('target').value, options);
        }
        session.on('terminated', function () {window.session = null;});
      });
    });
    app.initialize();
  </script>
</html>
~~~

Authors
-

### Eric Green

* <eric.green@onsip.com>
* /egreenmachine on [GitHub](http://github.com/egreenmachine)

### Joseph Frazier

* <joseph@onsip.com>
* /joseph-onsip on [GitHub](http://github.com/joseph-onsip)


License
-

OnSIP-Cordova is released under the [MIT license](https://github.com/onsip/onsip-cordova/license).

OnSIP-Cordova contains SIP.js under the following license:

~~~
Name: SIP.js

Copyright (c) 2014 Junction Networks, Inc. http://www.onsip.com

The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

NOTE: The original MIT License text can be found at opensource.org.

** SIP.js contains substantial portions of the JsSIP software under the following license: **

Copyright (c) 2012-2013 José Luis Millán - Versatica http://www.versatica.com

License: The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

** end JsSIP license **
~~~~

OnSIP-Cordova contains PhoneRTC under the following license:

~~~
Copyright {yyyy} {name of copyright owner}

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
~~~