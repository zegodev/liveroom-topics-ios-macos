//
//  ZGExternalVideoCaptureCameraSource.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/1/23.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGExternalVideoCaptureCameraSource.h"
#import <AVFoundation/AVFoundation.h>

@interface ZGExternalVideoCaptureCameraSource () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (strong, nonatomic) AVCaptureVideoDataOutput *output;
@property (strong, nonatomic) AVCaptureSession *session;

@end


@implementation ZGExternalVideoCaptureCameraSource

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
    
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    }
    
    if (!self.input) {
        NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        
#if TARGET_OS_OSX
        AVCaptureDevice *camera = cameras.firstObject;
        if (!camera) {
            NSLog(@"获取摄像头失败");
            return NO;
        }
#elif TARGET_OS_IOS
        NSArray *captureDeviceArray = [cameras filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"position == %d", AVCaptureDevicePositionFront]];
        if (captureDeviceArray.count == 0) {
            NSLog(@"获取前置摄像头失败");
            return NO;
        }
        AVCaptureDevice *camera = captureDeviceArray.firstObject;
#endif
        
        NSError *error = nil;
        AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
        if (error) {
            NSLog(@"AVCaptureDevice转AVCaptureDeviceInput失败");
            return NO;
        }
        self.input = captureDeviceInput;
        
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

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CMTime timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    [self.receiver capturedData:buffer presentationTimeStamp:timeStamp];
}

@end
