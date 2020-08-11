//
//  ZGDemoExternalVideoCameraCaptureController.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/15.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGDemoExternalVideoCameraCaptureController.h"

@interface ZGDemoExternalVideoCameraCaptureController () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    dispatch_queue_t _outputCallbackQueue;
}

@property (nonatomic) OSType pixelFormatType;
@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (strong, nonatomic) AVCaptureVideoDataOutput *output;
@property (strong, nonatomic) AVCaptureSession *session;
@property (nonatomic, assign) AVCaptureVideoOrientation currentOrientation;
@property (assign, nonatomic) BOOL isRunning;

@end

@implementation ZGDemoExternalVideoCameraCaptureController

- (instancetype)init {
    return [self initWithPixelFormatType:kCVPixelFormatType_32BGRA];
}

- (instancetype)initWithPixelFormatType:(OSType)pixelFormatType {
    if (self = [super init]) {
        self.pixelFormatType = pixelFormatType;
        self.currentOrientation = AVCaptureVideoOrientationPortrait;
        _outputCallbackQueue = dispatch_queue_create("com.doudong.ZGDemoExternalVideoCameraCaptureController.outputCallbackQueue", DISPATCH_QUEUE_SERIAL);
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
    
    [self.session beginConfiguration];
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
    } else {
        NSLog(@"Start failed. Failed to add `AVCaptureSessionPreset1280x720`.");
        return NO;
    }
    
    AVCaptureDeviceInput *input = self.input;
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
    if (input.device.position == AVCaptureDevicePositionFront) {
        captureConnection.videoMirrored = NO;
    }
    if (captureConnection.isVideoOrientationSupported) {
        captureConnection.videoOrientation = self.currentOrientation;
    }
    
    [self.session commitConfiguration];
    
    if (!self.session.isRunning) {
        [self.session startRunning];
    }
    
    self.isRunning = YES;
    return YES;
}


- (void)changeCaptureOrientation:(BOOL)change
{
    [self.session beginConfiguration];
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
    } else {
        NSLog(@"Start failed. Failed to add `AVCaptureSessionPreset1280x720`.");
    }
    
    AVCaptureDeviceInput *input = self.input;
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    
    AVCaptureVideoDataOutput *output = self.output;
    if ([self.session canAddOutput:output]) {
        [self.session addOutput:output];
    }
    
    AVCaptureConnection *captureConnection = [output connectionWithMediaType:AVMediaTypeVideo];
    if (input.device.position == AVCaptureDevicePositionFront) {
        captureConnection.videoMirrored = NO;
    }
    if (captureConnection.isVideoOrientationSupported) {
        if (change) {
            self.currentOrientation = AVCaptureVideoOrientationLandscapeLeft;
            captureConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        } else {
            self.currentOrientation = AVCaptureVideoOrientationPortrait;
            captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
    }
    
    [self.session commitConfiguration];
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

- (AVCaptureDeviceInput *)input {
    if (!_input) {
        NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        
#if TARGET_OS_OSX
        // 注意：这里 demo 选择最后一个摄像头，业务可以根据需要自定义选择合适摄像头设备
        AVCaptureDevice *camera = cameras.lastObject;
        if (!camera) {
            NSLog(@"获取摄像头失败");
            return nil;
        }
#elif TARGET_OS_IOS
        // 注意：这里 demo 选择前置摄像头，业务可以根据需要自定义选择合适摄像头设备
        NSArray *captureDeviceArray = [cameras filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"position == %d", AVCaptureDevicePositionFront]];
        if (captureDeviceArray.count == 0) {
            NSLog(@"获取前置摄像头失败");
            return nil;
        }
        AVCaptureDevice *camera = captureDeviceArray.firstObject;
#endif
        
        NSError *error = nil;
        AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
        if (error) {
            NSLog(@"AVCaptureDevice转AVCaptureDeviceInput失败");
            return nil;
        }
        _input = captureDeviceInput;
    }
    return _input;
}

// 是否支持快速纹理更新

- (BOOL)supportsFastTextureUpload {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
#if TARGET_OS_OSX
    return (CVOpenGLTextureCacheCreate != NULL);
#elif TARGET_OS_IOS
    return (CVOpenGLESTextureCacheCreate != NULL);
#else
    return NO;
#endif
#pragma clang diagnostic pop
#endif
}

- (AVCaptureVideoDataOutput *)output {
    if (!_output) {
        AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        
        /*
         if ([self supportsFastTextureUpload]) {
         // 是否支持全频色彩编码 YUV 一种色彩编码方式, 即YCbCr, 现在视频一般采用该颜色空间, 可以分离亮度跟色彩, 在不影响清晰度的情况下来压缩视频
         BOOL supportsFullYUVRange = NO;
         
         // 获取输出对象 支持的像素格式
         NSArray *supportedPixelFormats = videoDataOutput.availableVideoCVPixelFormatTypes;
         for (NSNumber *currentPixelFormat in supportedPixelFormats) {
         if ([currentPixelFormat intValue] == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
         supportsFullYUVRange = YES;
         }
         }
         
         // 根据是否支持 来设置输出对象的视频像素压缩格式,
         if (supportsFullYUVRange) {
         [videoDataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)}];
         } else {
         [videoDataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)}];
         }
         } else {
         videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
         }
         */
        
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
