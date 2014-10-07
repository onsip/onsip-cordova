// Modified by OnSIP on 10/2/2014

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import "RTCEAGLVideoView.h"
#import "PhoneRTCDelegate.h"

@interface PhoneRTCPlugin : CDVPlugin<PhoneRTCProtocol>
@property(nonatomic, strong) PhoneRTCDelegate *webRTC;
@property(nonatomic, strong) NSString *sendMessageCallbackId;
@property(nonatomic, strong) RTCEAGLVideoView* localVideoView;
@property(nonatomic, strong) RTCEAGLVideoView* remoteVideoView;
@property(nonatomic, strong) RTCVideoTrack* remoteVideoTrack;
@property(nonatomic, strong) RTCPeerConnectionFactory* factory;
- (void)getDescription: (CDVInvokedUrlCommand*)command;
- (void)setDescription: (CDVInvokedUrlCommand*)command;
- (void)receiveMessage:(CDVInvokedUrlCommand*)command;
@end

@interface MessagesObserver
- (void)sendMessage:(NSString *)message;
@end
