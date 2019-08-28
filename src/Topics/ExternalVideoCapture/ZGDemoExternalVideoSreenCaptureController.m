//
//  ZGDemoExternalVideoSreenCaptureController.m
//  LiveRoomPlayground-macOS
//
//  Created by jeffreypeng on 2019/8/16.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGDemoExternalVideoSreenCaptureController.h"
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
