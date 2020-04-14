//
//  ZGDemoExternalVideoCaptureFactory.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/15.
//  Copyright © 2019 Zego. All rights reserved.
//
#if defined(_Module_ExternalVideoCapture) || defined(_Module_MediaPlayer)
// mediaplayer 专题也用到了外部滤镜

#import "ZGDemoExternalVideoCaptureFactory.h"

@interface ZGDemoExternalVideoCaptureFactory () <ZegoVideoCaptureDevice>
{
    dispatch_queue_t _clientQueue;
}

@property (nonatomic) id<ZegoVideoCaptureClientDelegate> client;
@property (nonatomic) BOOL isPreview;
@property (nonatomic) BOOL isCapture;

@end

@implementation ZGDemoExternalVideoCaptureFactory

- (instancetype)init {
    if (self = [super init]) {
        _clientQueue = dispatch_queue_create("com.doudong.ZGDemoExternalVideoCaptureFactory.ClientQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)postCapturedData:(CVImageBufferRef)image withPresentationTimeStamp:(CMTime)time {
    if (!image) return;
    CVBufferRetain(image);
    dispatch_async(_clientQueue, ^{
        if (self.isCapture) {
            [self.client onIncomingCapturedData:image withPresentationTimeStamp:time];
        }
        CVBufferRelease(image);
    });
}

#pragma mark - private methods

- (void)stopCapture {
    if (self.onStopCapture) {
        self.onStopCapture();
    }
    self.isCapture = NO;
    self.isPreview = NO;
}

- (void)destoryResource {
    [self stopCapture];
    
    // 同步_clientQueue，在 client destroy 前停止 client 向SDK继续塞数据
    dispatch_sync(_clientQueue, ^{
        
    });
    [self.client destroy];
    self.client = nil;
}

#pragma mark - ZegoVideoCaptureFactory

- (nonnull id<ZegoVideoCaptureDevice>)zego_create:(nonnull NSString*)deviceId {
    NSLog(@"%s.%@", __func__, self);
    return self;
}

- (void)zego_destroy:(nonnull id<ZegoVideoCaptureDevice>)device {
    NSLog(@"%s. %@", __func__, self);
    [self destoryResource];
}

#pragma mark - ZegoVideoCaptureDevice

- (void)zego_allocateAndStart:(nonnull id<ZegoVideoCaptureClientDelegate>)client {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    dispatch_async(_clientQueue, ^{
        self.client = client;
        [self.client setFillMode:ZegoVideoFillModeCrop];
    });
}

- (void)zego_stopAndDeAllocate {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    [self destoryResource];
}

- (int)zego_startPreview {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    
    BOOL r = NO;
    if (self.onStartPreview) {
        r = self.onStartPreview();
    }
    if (r) {
        self.isPreview = YES;
    }
    return r?0:-1;
}

- (int)zego_stopPreview {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    
    if (self.onStopPreview) {
        self.onStopPreview();
    }
    self.isPreview = NO;
    return 0;
}

- (int)zego_startCapture {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    
    BOOL r = NO;
    if (self.onStartCapture) {
        r = self.onStartCapture();
    }
    if (r) {
        self.isCapture = YES;
    }
    return r?0:-1;
}

- (int)zego_stopCapture {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    
    [self stopCapture];
    return 0;
}

@end

#endif
