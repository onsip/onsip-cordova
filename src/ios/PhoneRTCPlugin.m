// Modified by OnSIP 10/2/2014

#import "PhoneRTCPlugin.h"
#import <AVFoundation/AVFoundation.h>

@implementation PhoneRTCPlugin
@synthesize localVideoView;
@synthesize remoteVideoView;
@synthesize remoteVideoTrack;

- (void)createPhoneRTCDelegate:(NSDictionary*)arguments andIsInitiator:(BOOL)isInitiatior
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendMessage:) name:@"SendMessage" object:nil];
    NSString *turnServerHost = [[arguments objectForKey:@"turn"] objectForKey:@"host"];
    NSString *turnUsername = [[arguments objectForKey:@"turn"] objectForKey:@"username"];
    NSString *turnPassword = [[arguments objectForKey:@"turn"] objectForKey:@"password"];
    RTCICEServer *stunServer = [[RTCICEServer alloc]
                                initWithURI:[NSURL URLWithString:@"stun:stun.l.google.com:19302"]
                                username: @""
                                password: @""];
    RTCICEServer *turnServer = [[RTCICEServer alloc]
                                initWithURI:[NSURL URLWithString:turnServerHost]
                                username: turnUsername
                                password: turnPassword];
    self.webRTC = [[PhoneRTCDelegate alloc] initWithDelegate:self andIsInitiator:isInitiatior andICEServers:@[stunServer, turnServer]];
}

- (void)setDescription: (CDVInvokedUrlCommand*)command
{
    self.sendMessageCallbackId = command.callbackId;

    NSError *error;
    NSDictionary *arguments = [NSJSONSerialization
                               JSONObjectWithData:[[command.arguments objectAtIndex:0] dataUsingEncoding:NSUTF8StringEncoding]
                               options:0
                               error:&error];
    NSString *sdp = [arguments objectForKey:@"sdp"];

    if (self.webRTC) {
        // Get description has already been called. This is the caller
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
                                                 (unsigned long)NULL), ^(void) {
            [self.webRTC receiveAnswer:sdp];
        });
    } else {
        // This is the callee
        [self createPhoneRTCDelegate:arguments andIsInitiator:NO];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
                                                 (unsigned long)NULL), ^(void) {
            [self.webRTC receiveOffer:sdp];
        });

    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.sendMessageCallbackId];
}

- (void)getDescription: (CDVInvokedUrlCommand*)command
{
    self.sendMessageCallbackId = command.callbackId;

    NSError *error;
    NSDictionary *arguments = [NSJSONSerialization
                               JSONObjectWithData:[[command.arguments objectAtIndex:0] dataUsingEncoding:NSUTF8StringEncoding]
                               options:0
                               error:&error];

    if ([arguments objectForKey:@"video"]) {
        NSDictionary *localVideo = [[arguments objectForKey:@"video"] objectForKey:@"localVideo"];
        NSDictionary *remoteVideo = [[arguments objectForKey:@"video"] objectForKey:@"remoteVideo"];
        localVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake([[localVideo objectForKey:@"x"] intValue], [[localVideo objectForKey:@"y"] intValue], [[localVideo objectForKey:@"width"] intValue], [[localVideo objectForKey:@"height"] intValue])];
        localVideoView.hidden = YES;
        localVideoView.userInteractionEnabled = NO;
        [self.webView.scrollView addSubview:localVideoView];

        remoteVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake([[remoteVideo objectForKey:@"x"] intValue], [[remoteVideo objectForKey:@"y"] intValue], [[remoteVideo objectForKey:@"width"] intValue], [[remoteVideo objectForKey:@"height"] intValue])];
        remoteVideoView.hidden = YES;
        remoteVideoView.userInteractionEnabled = NO;
        [self.webView.scrollView addSubview:remoteVideoView];
        if (remoteVideoTrack) {
            remoteVideoView.videoTrack = remoteVideoTrack;
            remoteVideoView.hidden = NO;
            [self.webView.scrollView bringSubviewToFront:remoteVideoView];
            [self.webView.scrollView bringSubviewToFront:localVideoView];
            [self.webView setNeedsDisplay];
        }
    }

    if (self.webRTC) {
        // callee
        [self.webRTC getDescription];
    } else {
        // caller. create self.webrtc
        [self createPhoneRTCDelegate:arguments andIsInitiator:YES];
        [self.webRTC getDescription];
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.sendMessageCallbackId];
}

- (void)receiveMessage:(CDVInvokedUrlCommand*)command
{
    NSString *message = [command.arguments objectAtIndex:0];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
                                             (unsigned long)NULL), ^(void) {
        [self.webRTC receiveMessage:message];
    });
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)disconnect:(CDVInvokedUrlCommand*)command
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
                                             (unsigned long)NULL), ^(void) {
        [self.webRTC disconnect];
    });
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)sendMessage:(NSNotification *)notification {
	NSData *message = [notification object];
    NSDictionary *jsonObject=[NSJSONSerialization
                              JSONObjectWithData:message
                              options:NSJSONReadingMutableLeaves
                              error:nil];

    NSLog(@"SENDING MESSAGE: %@", [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding]);
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                  messageAsDictionary:jsonObject];
    [pluginResult setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.sendMessageCallbackId];
}

- (void)addLocalVideoTrack:(RTCVideoTrack *)track {
    NSLog(@"addLocalStream 1");
    localVideoView.videoTrack = track;
    localVideoView.hidden = NO;
    [self.webView.scrollView bringSubviewToFront:localVideoView];
    [self.webView setNeedsDisplay];
}

- (void)addRemoteVideoTrack:(RTCVideoTrack *)track {
    NSLog(@"addRemoteStream 1");
    if (remoteVideoView) {
        remoteVideoView.videoTrack = track;
        remoteVideoView.hidden = NO;
        [self.webView.scrollView bringSubviewToFront:remoteVideoView];
        [self.webView.scrollView bringSubviewToFront:localVideoView];
        [self.webView setNeedsDisplay];
    } else {
        remoteVideoTrack = track;
    }
}

- (void)resetUi {
    NSLog(@"Reset Ui");
    self.localVideoView.videoTrack = nil;
    self.remoteVideoView.videoTrack = nil;
    localVideoView.hidden = YES;
    [localVideoView performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:NO];
    remoteVideoView.hidden = YES;
    [remoteVideoView performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:NO];
    localVideoView = nil;
    remoteVideoView = nil;
    remoteVideoTrack = nil;
    self.webRTC = nil;
    [self.webView setNeedsDisplay];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
