//
//  ZGExternalVideoCaptureManager.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/1/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGExternalVideoCaptureManager.h"
#import "ZGExternalVideoCaptureCameraSource.h"
#import "ZGExternamVideoCaptureImageSource.h"
#import "ZGExternalVideoCaptureScreenSource.h"
#import "ZGExternalVideoCapturePreviewHelper.h"

dispatch_queue_t _videoCaptureQueue;

@interface ZGExternalVideoCaptureManager () <ZegoVideoCaptureDevice,ZGExternalVideoCaptureDataReceiver>

@property (assign, nonatomic) ZGExternalVideoCaptureSourceType sourceType;
@property (strong, nonatomic, nullable) ZGExternalVideoCaptureBaseSource *source;

@property (strong, nonatomic) id<ZegoVideoCaptureClientDelegate> client;

@property (assign, nonatomic) BOOL isPreview;
@property (assign, nonatomic) BOOL isPublish;
@property (assign, nonatomic, readonly) BOOL isCapture;

@property (nonatomic, weak) ZGView *previewView;
@property (assign, nonatomic) ZegoVideoViewMode viewMode;

@end

@implementation ZGExternalVideoCaptureManager

- (instancetype)init {
    if (self = [super init]) {
        if (!_videoCaptureQueue) {
            _videoCaptureQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
        }
    }
    return self;
}

- (void)setSourceType:(ZGExternalVideoCaptureSourceType)sourceType {
    if (_sourceType == sourceType) {
        return;
    }
    [self stopCapture];
    
    _sourceType = sourceType;
    
    self.source = [self sourceForType:self.sourceType];
    self.source.receiver = self;
    if (self.isCapture) {
        [self startCapture];
    }
}

- (void)startCapture {
    [self.source start];
}

- (void)stopCapture {
    [self.source stop];
    [ZGExternalVideoCapturePreviewHelper removeCaptureDataInView:self.previewView];
}

- (void)setPreviewView:(ZGView *)view viewMode:(ZegoVideoViewMode)viewMode {
    if (self.previewView && self.previewView != view) {
        [ZGExternalVideoCapturePreviewHelper removeCaptureDataInView:self.previewView];
    }
    
    self.previewView = view;
    self.viewMode = viewMode;
}

#pragma mark - ZegoVideoCaptureFactory

- (nonnull id<ZegoVideoCaptureDevice>)zego_create:(nonnull NSString*)deviceId {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    return self;
}

- (void)zego_destroy:(nonnull id<ZegoVideoCaptureDevice>)device {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    [self zego_stopAndDeAllocate];
}

#pragma mark - ZegoVideoCaptureDevice

- (void)zego_allocateAndStart:(nonnull id<ZegoVideoCaptureClientDelegate>)client {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    
    self.client = client;
    [self.client setFillMode:ZegoVideoFillModeCrop];
}

- (void)zego_stopAndDeAllocate {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    
    [self stopCapture];
    
    [self.client destroy];
    self.client = nil;
}

- (int)zego_startPreview {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    
    self.isPreview = YES;
    [self startCapture];
    return 0;
}

- (int)zego_stopPreview {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    
    self.isPreview = NO;
    if (self.isCapture) {
        [self stopCapture];
    }
    return 0;
}

- (int)zego_startCapture {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    
    self.isPublish = YES;
    [self startCapture];
    return 0;
}

- (int)zego_stopCapture {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    
    self.isPublish = NO;
    if (self.isCapture) {
        [self stopCapture];
    }
    return 0;
}

#pragma mark - ZGExternalVideoCaptureDataReceiver

- (void)capturedData:(CVImageBufferRef)image presentationTimeStamp:(CMTime)time {
    NSLog(NSLocalizedString(@"%s", nil), __func__);
    
    CVBufferRetain(image);
    
    dispatch_async(_videoCaptureQueue, ^{
        if (self.isPreview && self.previewView) {
            [ZGExternalVideoCapturePreviewHelper showCaptureData:image inView:self.previewView viewMode:self.viewMode];
        }
        
        [self.client onIncomingCapturedData:image withPresentationTimeStamp:time];
        CVBufferRelease(image);
    });
}

#pragma mark - Access

- (BOOL)isCapture {
    return self.isPublish || self.isPreview;
}

- (id<ZGExternalVideoCaptureSourceDelegate>)sourceForType:(ZGExternalVideoCaptureSourceType)sourceType {
    switch (sourceType) {
        case kZGExternalVideoCaptureSourceTypeImage: return [ZGExternamVideoCaptureImageSource new];
        case kZGExternalVideoCaptureSourceTypeCamera: return [ZGExternalVideoCaptureCameraSource new];
        case kZGExternalVideoCaptureSourceTypeScreen: return [ZGExternalVideoCaptureScreenSource new];
        default:{
            NSLog(@"undefined source type");
            return [ZGExternalVideoCaptureBaseSource new];
        }
    }
}

@end
