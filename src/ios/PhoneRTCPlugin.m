// Modified by OnSIP 10/2/2014

#import "PhoneRTCPlugin.h"
#import <AVFoundation/AVFoundation.h>

@implementation PhoneRTCPlugin
@synthesize localVideoView;
@synthesize localVideoTrack;
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

// {x:y:width:height:}
- (RTCEAGLVideoView*) createVideoView:(NSDictionary*)videoLayoutParams {
    
    CGRect frame = CGRectMake([[videoLayoutParams objectForKey:@"x"] intValue], [[videoLayoutParams objectForKey:@"y"] intValue], [[videoLayoutParams objectForKey:@"width"] intValue], [[videoLayoutParams objectForKey:@"height"] intValue]);
    
    RTCEAGLVideoView *view = [[RTCEAGLVideoView alloc] initWithFrame:frame];
    view.userInteractionEnabled = NO;
    
    [self.webView.scrollView addSubview:view];
    [self.webView.scrollView bringSubviewToFront:view];
    
    return view;
}

- (void)setupVideoDisplay:(NSDictionary*)arguments {
    if ([arguments objectForKey:@"video"]) {
        NSDictionary *localVideo = [[arguments objectForKey:@"video"] objectForKey:@"localVideo"];
        NSDictionary *remoteVideo = [[arguments objectForKey:@"video"] objectForKey:@"remoteVideo"];
        
        if (remoteVideoView) {
            [remoteVideoView removeFromSuperview];
        }
        remoteVideoView = [self createVideoView:remoteVideo];
        [remoteVideoTrack addRenderer:remoteVideoView];
        
        if (localVideoView) {
            [localVideoView removeFromSuperview];
        }
        localVideoView = [self createVideoView:localVideo];
        [localVideoTrack addRenderer:localVideoView];
        
        [self.webView setNeedsDisplay];
    }
}

- (void)refreshVideoContainer:(NSDictionary*)arguments {
    if ([arguments objectForKey:@"video"]) {
        NSDictionary *localVideo = [[arguments objectForKey:@"video"] objectForKey:@"localVideo"];
        NSDictionary *remoteVideo = [[arguments objectForKey:@"video"] objectForKey:@"remoteVideo"];
        
        if (remoteVideoView) {
            CGRect frame = CGRectMake([[remoteVideo objectForKey:@"x"] intValue], [[remoteVideo objectForKey:@"y"] intValue], [[remoteVideo objectForKey:@"width"] intValue], [[remoteVideo objectForKey:@"height"] intValue]);
            remoteVideoView.frame = frame;
        }
        
        if (localVideo) {
            CGRect frame = CGRectMake([[localVideo objectForKey:@"x"] intValue], [[localVideo objectForKey:@"y"] intValue], [[localVideo objectForKey:@"width"] intValue], [[localVideo objectForKey:@"height"] intValue]);
            localVideoView.frame = frame;
        }
        
        [self.webView setNeedsDisplay];
    }
}

// update video views if HTML element has changed in size, pos
- (void)setVideoViews: (CDVInvokedUrlCommand*)command {
    NSError *error;
    NSDictionary *arguments = [NSJSONSerialization
                               JSONObjectWithData:[[command.arguments objectAtIndex:0] dataUsingEncoding:NSUTF8StringEncoding]
                               options:0
                               error:&error];
    
    [self refreshVideoContainer:arguments];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getDescription: (CDVInvokedUrlCommand*)command
{
    self.sendMessageCallbackId = command.callbackId;

    NSError *error;
    NSDictionary *arguments = [NSJSONSerialization
                               JSONObjectWithData:[[command.arguments objectAtIndex:0] dataUsingEncoding:NSUTF8StringEncoding]
                               options:0
                               error:&error];

    [self setupVideoDisplay:arguments];

    if (!self.webRTC) {
        // caller. create self.webrtc
        [self createPhoneRTCDelegate:arguments andIsInitiator:YES];
    }
    
    // callee
    self.webRTC.doVideo = [arguments objectForKey:@"video"] == nil ? NO : YES;
    self.webRTC.constraints = [[RTCMediaConstraints alloc]
                               initWithMandatoryConstraints:
                               @[
                                 [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
                                 [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:
                                  self.webRTC.doVideo ? @"true" : @"false"]
                                 ]
                               optionalConstraints:
                               @[
                                 [[RTCPair alloc] initWithKey:@"internalSctpDataChannels" value:@"true"],
                                 [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
                                 ]
                               ];
    
    [self.webRTC getDescription];
    

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
    localVideoTrack = track;
    [track addRenderer:localVideoView];
    localVideoView.hidden = NO;
    [self.webView.scrollView bringSubviewToFront:localVideoView];
    [self.webView setNeedsDisplay];
}

- (void)addRemoteVideoTrack:(RTCVideoTrack *)track {
    NSLog(@"addRemoteStream 1");
    remoteVideoTrack = track;
    if (remoteVideoView) {
        [track addRenderer:remoteVideoView];
        remoteVideoView.hidden = NO;
        [self.webView.scrollView bringSubviewToFront:remoteVideoView];
        [self.webView.scrollView bringSubviewToFront:localVideoView];
        [self.webView setNeedsDisplay];
    }
}

- (void)resetUi {
    NSLog(@"Reset Ui");
    localVideoView.hidden = YES;
    [localVideoView performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:NO];
    remoteVideoView.hidden = YES;
    [remoteVideoView performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:NO];
    localVideoView = nil;
    localVideoTrack = nil;
    remoteVideoView = nil;
    remoteVideoTrack = nil;
    self.webRTC = nil;
    [self.webView setNeedsDisplay];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
