//
//  ZGDemoExternalVideoImageCaptureController.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/15.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGDemoExternalVideoImageCaptureController.h"
#import "CMTimeHelper.h"

@interface ZGDemoExternalVideoImageCaptureController ()
#if TARGET_OS_OSX
@property (nonatomic) NSImage *motionImage;
#endif
#if TARGET_OS_IOS
@property (nonatomic) UIImage *motionImage;
#endif

@property (nonatomic, assign) CGImageRef bgraImage;
@property (assign, nonatomic) NSUInteger fps;
@property (strong, nonatomic) NSTimer *fpsTimer;

@end

@implementation ZGDemoExternalVideoImageCaptureController

#if TARGET_OS_OSX
- (instancetype)initWithMotionImage:(NSImage *)motionImage {
    if (self = [super init]) {
        self.motionImage = motionImage;
        self.bgraImage = [self CreateBGRAImageFromRGBAImage:[self.motionImage CGImageForProposedRect:nil context:nil hints:nil]];
    }
    return self;
}
#endif

#if TARGET_OS_IOS
- (instancetype)initWithMotionImage:(UIImage *)motionImage {
    if (self = [super init]) {
        self.motionImage = motionImage;
        self.bgraImage = [self CreateBGRAImageFromRGBAImage:self.motionImage.CGImage];
    }
    return self;
}
#endif

- (void)dealloc {
    CGImageRelease(self.bgraImage);
}

- (BOOL)start {
    if (!self.fpsTimer) {
        self.fps = self.fps ?:15;
        NSTimeInterval delta = 1.f/self.fps;
        self.fpsTimer = [NSTimer timerWithTimeInterval:delta target:self selector:@selector(captureImage) userInfo:nil repeats:YES];
        [NSRunLoop.mainRunLoop addTimer:self.fpsTimer forMode:NSRunLoopCommonModes];
    }
    
    [self.fpsTimer fire];
    [self captureImage];//在开始时立即调用一次
    
    return YES;
}

- (void)stop {
    if (self.fpsTimer) {
        [self.fpsTimer invalidate];
        self.fpsTimer = nil;
    }
}


- (void)captureImage {
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        CGSize contextSize = CGSizeMake(720, 1280);
        CGSize imgSize = self.motionImage.size;
        CGFloat originX = arc4random()%(uint32_t)(contextSize.width-imgSize.width);
        CGFloat originY = arc4random()%(uint32_t)(contextSize.height-imgSize.height);
        CGPoint origin = CGPointMake(originX, originY);
        
        CVPixelBufferRef pixelBuffer = [self pixelBufferFromCGImage:self.bgraImage contextSize:contextSize imageOrigin:origin];
        
        CMTime time = [CMTimeHelper getCurrentTimestamp];
        
        id<ZGDemoExternalVideoCaptureControllerDelegate> delegate = self.delegate;
        if (delegate &&
            [delegate respondsToSelector:@selector(externalVideoCaptureController:didCapturedData:presentationTimeStamp:)]) {
            [delegate externalVideoCaptureController:self didCapturedData:pixelBuffer presentationTimeStamp:time];
        }
        
        CVPixelBufferRelease(pixelBuffer);
    });
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image contextSize:(CGSize)contextSize imageOrigin:(CGPoint)imageOrigin {
    CVReturn status;
    CVPixelBufferRef pixelBuffer;
    
    NSDictionary *pixelBufferAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]};
    
    status = CVPixelBufferCreate(kCFAllocatorDefault,
                                 contextSize.width,
                                 contextSize.height,
                                 kCVPixelFormatType_32BGRA,
                                 (__bridge CFDictionaryRef)pixelBufferAttributes,
                                 &pixelBuffer);
    
    if (status != kCVReturnSuccess) {
        return NULL;
    }
    
    time_t currentTime = time(0);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    void *data = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    // Random Background Color
    char color[4] = {0};
    color[0] = (currentTime * 1) % 0xFF;
    color[1] = (currentTime * 2) % 0xFF;
    color[2] = (currentTime * 3) % 0xFF;
    color[3] = 0xFF;
    memset_pattern4(data, color, CVPixelBufferGetDataSize(pixelBuffer));
    
    CGFloat imageWith = CGImageGetWidth(image);
    CGFloat imageHeight = CGImageGetHeight(image);
    
    static CGPoint origin = {0, 0};
    static time_t lastTime = 0;
    
    if (lastTime != currentTime) {
        origin.x = rand() % (int)(contextSize.width - imageWith);
        origin.y = rand() % (int)(contextSize.height - imageHeight);
        
        lastTime = currentTime;
    }
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(data, contextSize.width, contextSize.height, 8,
                                                 CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                 rgbColorSpace,
                                                 kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(context,
                       CGRectMake(origin.x, origin.y, CGImageGetWidth(image), CGImageGetHeight(image)),
                       image);
    
    CGContextRelease(context);
    CGColorSpaceRelease(rgbColorSpace);
    
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

- (CGImageRef)CreateBGRAImageFromRGBAImage:(CGImageRef)rgbaImageRef {
    if (!rgbaImageRef) {
        return NULL;
    }
    
    const size_t bitsPerPixel = CGImageGetBitsPerPixel(rgbaImageRef);
    const size_t bitsPerComponent = CGImageGetBitsPerComponent(rgbaImageRef);
    
    const size_t channelCount = bitsPerPixel / bitsPerComponent;
    if (bitsPerPixel != 32 || channelCount != 4) {
        assert(false);
        return NULL;
    }
    
    const size_t width = CGImageGetWidth(rgbaImageRef);
    const size_t height = CGImageGetHeight(rgbaImageRef);
    const size_t bytesPerRow = CGImageGetBytesPerRow(rgbaImageRef);
    
    // rgba to bgra: swap blue and red channel
    CFDataRef bgraData = CGDataProviderCopyData(CGImageGetDataProvider(rgbaImageRef));
    UInt8 *pixelData = (UInt8 *)CFDataGetBytePtr(bgraData);
    for (size_t row = 0; row < height; row++) {
        for (size_t col = 0; col < bytesPerRow - 4; col += 4) {
            size_t idx = row * bytesPerRow + col;
            UInt8 tmpByte = pixelData[idx]; // red
            pixelData[idx] = pixelData[idx+2];
            pixelData[idx+2] = tmpByte;
        }
    }
    
    CGColorSpaceRef colorspace = CGImageGetColorSpace(rgbaImageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(rgbaImageRef);
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(bgraData);
    CGImageRef bgraImageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow,
                                            colorspace, bitmapInfo, provider,
                                            NULL, true, kCGRenderingIntentDefault);
    
    CFRelease(bgraData);
    CGDataProviderRelease(provider);
    
    return bgraImageRef;
}

@end
