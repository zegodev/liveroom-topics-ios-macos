//
//  ZGDemoExternalVideoSreenCaptureController.m
//  LiveRoomPlayground-macOS
//
//  Created by jeffreypeng on 2019/8/16.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoCapture

#import "ZGDemoExternalVideoSreenCaptureController.h"

typedef NS_ENUM(NSUInteger, ZGScreenCaptureState) {
    ZGScreenCaptureStateUnknown = 0,
    ZGScreenCaptureStateBeReady = 1,
    ZGScreenCaptureStateRunning = 2,
    ZGScreenCaptureStateStop    = 3,
};;

#if TARGET_OS_IPHONE
#import <ReplayKit/ReplayKit.h>

@interface ZGDemoExternalVideoSreenCaptureController () <RPScreenRecorderDelegate>

@property (nonatomic) OSType pixelFormatType;
@property (assign, nonatomic) BOOL isRunning;

@property (nonatomic, assign) ZGScreenCaptureState captureState;

@end

@implementation ZGDemoExternalVideoSreenCaptureController

- (instancetype)init {
    return [self initWithPixelFormatType:kCVPixelFormatType_32BGRA];
}

- (instancetype)initWithPixelFormatType:(OSType)pixelFormatType {
    if (self = [super init]) {
        self.pixelFormatType = pixelFormatType;
        self.captureState = ZGScreenCaptureStateStop;
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

- (BOOL)start {
    NSLog(@"[simon]%s", __func__);
    if (@available(iOS 11.0, *)) {
        [[RPScreenRecorder sharedRecorder] setDelegate:self];
        if (![RPScreenRecorder sharedRecorder].isAvailable) {
            NSLog(@"[start]检测发现录制不可用");
            return NO;
        }
        if ([[RPScreenRecorder sharedRecorder] isRecording]) {
            NSLog(@"[start]已处于录制状态");
            return NO;
        }
        if (self.captureState == ZGScreenCaptureStateBeReady ||
            self.captureState == ZGScreenCaptureStateRunning ||
            self.captureState == ZGScreenCaptureStateUnknown) {
            NSLog(@"[start]正准备采集或正在采集");
            return NO;
        }
        self.captureState = ZGScreenCaptureStateBeReady;
        [[RPScreenRecorder sharedRecorder] startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
            if (error) {
                ZGLogError(@"捕获屏幕数据 error: %@", error.description);
                return;
            }
            if (CMSampleBufferDataIsReady(sampleBuffer) && bufferType == RPSampleBufferTypeVideo) {
                CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                CMTime timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);

                id<ZGDemoExternalVideoCaptureControllerDelegate> delegate = self.delegate;
                if (delegate && [delegate respondsToSelector:@selector(externalVideoCaptureController:didCapturedData:presentationTimeStamp:)]) {
                    [delegate externalVideoCaptureController:self didCapturedData:buffer presentationTimeStamp:timeStamp];
                }
            }

        } completionHandler:^(NSError * _Nullable error) {
            if (!error) {
                ZGLogInfo(@"屏幕数据捕获开启成功");
                self.captureState = ZGScreenCaptureStateRunning;
            } else {
                ZGLogError(@"屏幕数据捕获开启失败 error: %@", error);
                self.captureState = ZGScreenCaptureStateStop;
            }
        }];
        return YES;
    } else {
        ZGLogWarn(@"当前系统版本低于11.0，不能捕获屏幕数据");
        return NO;
    }
    return YES;
}

- (void)stop {
    if (@available(iOS 11.0, *)) {
        if (![RPScreenRecorder sharedRecorder].isAvailable) {
            NSLog(@"[stop]检测发现录制不可用");
            return;
        }
        if (![[RPScreenRecorder sharedRecorder] isRecording]) {
            NSLog(@"[stop]已处于非录制状态");
            return;
        }
        if (self.captureState == ZGScreenCaptureStateStop ||
            self.captureState == ZGScreenCaptureStateUnknown) {
            NSLog(@"[start]已停止采集");
            return;
        }
        [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {
            if (!error) {
                ZGLogInfo(@"停止屏幕数据捕获成功");
                self.captureState = ZGScreenCaptureStateStop;
            } else {
                ZGLogError(@"停止屏幕数据捕获失败 error: %@", error);
                self.captureState = ZGScreenCaptureStateUnknown;
            }
        }];
    } else {
        ZGLogWarn(@"当前系统版本低于11.0，不能捕获屏幕数据");
    }
}

#pragma mark - RPScreenRecorderDelegate
- (void)screenRecorder:(RPScreenRecorder *)screenRecorder didStopRecordingWithPreviewViewController:(nullable RPPreviewViewController *)previewViewController error:(nullable NSError *)error {
    if (error) {
        ZGLogError(@"屏幕数据捕获已停止 error: %@", error);
    }
}

- (void)screenRecorderDidChangeAvailability:(RPScreenRecorder *)screenRecorder {
    if (screenRecorder.available) {
        ZGLogInfo(@"屏幕录制能力发生变化，可用");
    } else {
        ZGLogInfo(@"屏幕录制能力发生变化，不可用");
    }
}

@end

#elif TARGET_OS_MAC
#import <AVFoundation/AVFoundation.h>

@interface ZGDemoExternalVideoSreenCaptureController () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    dispatch_queue_t _outputCallbackQueue;
}

@property (nonatomic) OSType pixelFormatType;
@property (strong, nonatomic) AVCaptureScreenInput *input;
@property (strong, nonatomic) AVCaptureVideoDataOutput *output;
@property (strong, nonatomic) AVCaptureSession *session;
@property (nonatomic, assign) CGDirectDisplayID display;

@property (assign, nonatomic) BOOL isRunning;

@end

@implementation ZGDemoExternalVideoSreenCaptureController

- (instancetype)init {
    return [self initWithPixelFormatType:kCVPixelFormatType_32BGRA];
}

- (instancetype)initWithPixelFormatType:(OSType)pixelFormatType {
    if (self = [super init]) {
        self.pixelFormatType = pixelFormatType;
        _outputCallbackQueue = dispatch_queue_create("com.doudong.ZGDemoExternalVideoSreenCaptureController.outputCallbackQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
- (void)dealloc {
    [self stop];
}

- (BOOL)start {
    if (self.isRunning) {
        return YES;
    }
    
    if (!self.session) {
        AVCaptureSession *session = [[AVCaptureSession alloc] init];
        self.session = session;
    }
    
    [self.session beginConfiguration];
    
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetMedium]) {
        [self.session setSessionPreset:AVCaptureSessionPresetMedium];
    }
    
    AVCaptureScreenInput *input = self.input;
    if (!input) {
        return NO;
    }
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    
    AVCaptureVideoDataOutput *output = self.output;
    if (!output) {
        return NO;
    }
    if ([self.session canAddOutput:output]) {
        [self.session addOutput:output];
    }
    
    AVCaptureConnection *captureConnection = [output connectionWithMediaType:AVMediaTypeVideo];
    if (captureConnection.isVideoOrientationSupported) {
        captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    
    [self.session commitConfiguration];
    
    if (!self.session.isRunning) {
        [self.session startRunning];
    }
    
    self.isRunning = YES;
    
    return YES;
}

- (void)stop {
    if (!self.isRunning) {
        return;
    }
    
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
    
    self.isRunning = NO;
}

#pragma mark - private methods

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

- (AVCaptureScreenInput *)input {
    if (!_input) {
        CGDirectDisplayID displayID = CGMainDisplayID();
        AVCaptureScreenInput *captureScreenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:displayID];
        captureScreenInput.capturesCursor = YES;
        captureScreenInput.capturesMouseClicks = YES;
        [captureScreenInput setMinFrameDuration:CMTimeMake(1, 20)];
        _input = captureScreenInput;
    }
    return _input;
}

- (AVCaptureVideoDataOutput *)output {
    if (!_output) {
        AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(self.pixelFormatType)};
        [videoDataOutput setSampleBufferDelegate:self queue:_outputCallbackQueue];
        
        _output = videoDataOutput;
    }
    return _output;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CMTime timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    id<ZGDemoExternalVideoCaptureControllerDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(externalVideoCaptureController:didCapturedData:presentationTimeStamp:)]) {
        [delegate externalVideoCaptureController:self didCapturedData:buffer presentationTimeStamp:timeStamp];
    }
}

@end

#endif

#endif
