// Modified by OnSIP on 10/2/2014

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Cordova/CDVViewController.h>

#import "RTCICECandidate.h"
#import "RTCICEServer.h"
#import "RTCMediaConstraints.h"
#import "RTCMediaStream.h"
#import "RTCPair.h"
#import "RTCPeerConnection.h"
#import "RTCPeerConnectionDelegate.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCSessionDescription.h"
#import "RTCVideoRenderer.h"
#import "RTCVideoCapturer.h"
#import "RTCVideoTrack.h"
#import "RTCSessionDescriptionDelegate.h"

@protocol PHONERTCSendMessage<NSObject>
- (void)sendMessage:(NSData*)message;
- (void)sendRemoteVideoTrack:(RTCVideoTrack*)track;
- (void)resetUi;
@end

@protocol PhoneRTCProtocol<NSObject>
- (void)addLocalVideoTrack:(RTCVideoTrack *)track;
- (void)addRemoteVideoTrack:(RTCVideoTrack *)track;
- (void)resetUi;
@end

@interface PCObserver : NSObject<RTCPeerConnectionDelegate>
- (id)initWithDelegate:(id<PHONERTCSendMessage>)delegate;
@end

@protocol ICEServerDelegate<NSObject>
- (void)getDescription;
@end

@interface PhoneRTCDelegate : UIResponder<ICEServerDelegate,
                                        PHONERTCSendMessage,
                                        RTCSessionDescriptionDelegate>
@property(nonatomic, strong) PCObserver *pcObserver;
@property(nonatomic, strong) RTCPeerConnection *peerConnection;
@property(nonatomic, strong) RTCPeerConnectionFactory *peerConnectionFactory;
@property(nonatomic, strong) NSMutableArray *queuedRemoteCandidates;
@property(nonatomic, strong) RTCMediaConstraints *constraints;
@property(nonatomic, weak) id<PhoneRTCProtocol> delegate;
@property(nonatomic, strong) RTCVideoCapturer *capturer;
@property(assign) BOOL doVideo;
@property(assign) BOOL isInitiator;

- (id)initWithDelegate:(id)delegate andIsInitiator:(BOOL)isInitiator andICEServers:(NSArray*)servers;
- (void)receiveMessage:(NSString*)message;
- (void)receiveOffer:(NSString *)message;
- (void)receiveAnswer:(NSString *)message;
- (void)disconnect;
@end
