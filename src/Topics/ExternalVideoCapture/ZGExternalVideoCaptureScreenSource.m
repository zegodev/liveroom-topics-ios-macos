//
//  ZGExternalVideoCaptureScreenSource.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/1/24.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGExternalVideoCaptureScreenSource.h"
#import <AVFoundation/AVFoundation.h>

@interface ZGExternalVideoCaptureScreenSource () <AVCaptureVideoDataOutputSampleBufferDelegate>

#if TARGET_OS_OSX
@property (strong, nonatomic) AVCaptureScreenInput *input;
@property (strong, nonatomic) AVCaptureVideoDataOutput *output;
@property (strong, nonatomic) AVCaptureSession *session;
@property (nonatomic, assign) CGDirectDisplayID display;
#endif

@end

@implementation ZGExternalVideoCaptureScreenSource

- (void)dealloc {
    [self stop];
}

- (BOOL)start {
#if TARGET_OS_IOS
    NSLog(@"iOS需要在控制面板长按录制然后选择本App，就可以使用App进行录屏的推流(iOS11及以上支持)");
#elif TARGET_OS_OSX
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
    
    if (!self.input) {
        CGDirectDisplayID displayID = CGMainDisplayID();
        AVCaptureScreenInput *captureScreenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:displayID];
        captureScreenInput.capturesCursor = YES;
        captureScreenInput.capturesMouseClicks = YES;
        [captureScreenInput setMinFrameDuration:CMTimeMake(1, 20)];
        
        self.input = captureScreenInput;
        
        if ([self.session canAddInput:self.input]) {
            [self.session addInput:self.input];
        }
        else {
            return NO;
        }
    }
    
    if (!self.output) {
        AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        dispatch_queue_t outputQueue = dispatch_queue_create("ACVideoCaptureOutputQueue", DISPATCH_QUEUE_SERIAL);
        [videoDataOutput setSampleBufferDelegate:self queue:outputQueue];
        videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
        self.output = videoDataOutput;
        
        if ([self.session canAddOutput:self.output]) {
            [self.session addOutput:self.output];
        }
        else {
            return NO;
        }
        
        AVCaptureConnection *captureConnection = [videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        if (captureConnection.isVideoOrientationSupported) {
            captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
    }
    
    [self.session commitConfiguration];
    
    if (!self.session.isRunning) {
        [self.session startRunning];
    }
    
    self.isRunning = YES;
#endif
    
    return YES;
}

- (void)stop {
#if TARGET_OS_IOS
    NSLog(@"iOS需要在控制面板长按录制然后选择本App，就可以使用App进行录屏的推流(iOS11及以上支持)");
#elif TARGET_OS_OSX
    if (!self.isRunning) {
        return;
    }
    
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
    
    self.isRunning = NO;
#endif
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CMTime timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    [self.receiver capturedData:buffer presentationTimeStamp:timeStamp];
}


@end
