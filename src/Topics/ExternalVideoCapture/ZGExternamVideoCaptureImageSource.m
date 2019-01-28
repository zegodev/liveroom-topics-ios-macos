//
//  ZGExternamVideoCaptureImageSource.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/1/24.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGExternamVideoCaptureImageSource.h"
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#define ZGImage NSImage
#define ZGColor NSColor
#elif TARGET_OS_IOS
#import <UIKit/UIKit.h>
#define ZGImage UIImage
#define ZGColor UIColor
#endif

@interface ZGExternamVideoCaptureImageSource ()

@property (assign, nonatomic) NSUInteger fps;
@property (strong, nonatomic) NSDate *startDate;
@property (strong, nonatomic) ZGImage *image;
@property (strong, nonatomic) NSTimer *fpsTimer;

@end

@implementation ZGExternamVideoCaptureImageSource

- (BOOL)start {
    if (self.isRunning) {
        return YES;
    }
    
    if (!self.image) {
        self.image = [ZGImage imageNamed:@"watermark-zego.png"];
    }
    
    if (!self.fpsTimer) {
        self.fps = self.fps ?:1;
        NSTimeInterval delta = 1.f/self.fps;
        self.fpsTimer = [NSTimer timerWithTimeInterval:delta target:self selector:@selector(captureImage) userInfo:nil repeats:YES];
        [NSRunLoop.mainRunLoop addTimer:self.fpsTimer forMode:NSRunLoopCommonModes];
    }
    
    self.startDate = NSDate.date;
    [self.fpsTimer fire];
    [self captureImage];//在开始时立即调用一次
    
    self.isRunning = YES;
    return YES;
}

- (void)stop {
    if (!self.isRunning) {
        return;
    }
    
    if (self.fpsTimer) {
        [self.fpsTimer invalidate];
        self.fpsTimer = nil;
    }
    
    self.startDate = nil;
}

- (void)captureImage {
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        CGSize contextSize = CGSizeMake(270, 480);
        CGSize imgSize = self.image.size;
        CGFloat OriginX = arc4random()%(uint32_t)(contextSize.width-imgSize.width);
        CGFloat OriginY = arc4random()%(uint32_t)(contextSize.height-imgSize.height);
        CGPoint origin = CGPointMake(OriginX, OriginY);
        
        CGImageRef cgImage;
#if TARGET_OS_OSX
        cgImage = [self.image CGImageForProposedRect:nil context:nil hints:nil];
#elif TARGET_OS_IOS
        cgImage = self.image.CGImage;
#endif
        
        CVPixelBufferRef pixel = [self pixelBufferFromCGImage:cgImage contextSize:contextSize imageOrigin:origin];
        
        NSUInteger fps = self.fps;
        NSTimeInterval timeInterval = -self.startDate.timeIntervalSinceNow;
        int64_t value = timeInterval / fps;
        CMTime time = CMTimeMake(value, (int32_t)fps);
        
        [self.receiver capturedData:pixel presentationTimeStamp:time];
    });
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image contextSize:(CGSize)contextSize imageOrigin:(CGPoint)imageOrigin {
    CVReturn status;
    CVPixelBufferRef pixelBuffer;
    
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault,
                                               NULL, NULL, 0,
                                               &kCFTypeDictionaryKeyCallBacks,
                                               &kCFTypeDictionaryValueCallBacks);
    
    CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                             1,
                                                             &kCFTypeDictionaryKeyCallBacks,
                                                             &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    status = CVPixelBufferCreate(kCFAllocatorDefault,
                                 contextSize.width,
                                 contextSize.height,
                                 kCVPixelFormatType_32BGRA,
                                 attrs,
                                 &pixelBuffer);
    CFRelease(attrs);
    CFRelease(empty);
    
    if (status != kCVReturnSuccess) {
        return NULL;
    }
    
    time_t currentTime = time(0);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *data = CVPixelBufferGetBaseAddress(pixelBuffer);
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
    
    CGImageRef bgraImage = [self CreateBGRAImageFromRGBAImage:image];
    
    CGContextDrawImage(context,
                       CGRectMake(origin.x, origin.y, CGImageGetWidth(image), CGImageGetHeight(image)),
                       bgraImage);
    
    CGImageRelease(bgraImage);
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
