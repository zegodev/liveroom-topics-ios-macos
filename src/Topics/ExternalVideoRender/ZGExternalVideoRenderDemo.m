//
//  ZGExternalVideoRenderDemo.m
//  LiveRoomPlayground
//
//  Created by Sky on 2019/1/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoRender

#import "ZGExternalVideoRenderDemo.h"
#import "ZGHelper.h"
#import "ZGExternalVideoRenderHelper.h"
#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#define ZGImage NSImage
#define ZGColor NSColor
#import <ZegoLiveRoomOSX/zego-api-external-video-render-oc.h>
#elif TARGET_OS_IOS
#import <UIKit/UIKit.h>
#define ZGImage UIImage
#define ZGColor UIColor
#import <ZegoLiveRoom/zego-api-external-video-render-oc.h>
#endif

@interface ZGExternalVideoRenderDemo () <ZegoRoomDelegate, ZegoLivePublisherDelegate, ZegoLivePlayerDelegate, ZegoExternalVideoRenderDelegate>

@property (assign ,nonatomic) BOOL isLoginRoom;
@property (assign, nonatomic) BOOL isPreview;
@property (assign ,nonatomic) BOOL isPublishing;
@property (assign ,nonatomic) BOOL isPlaying;
@property (copy, nonatomic) NSString *streamID;

@property (assign, nonatomic) CGFloat videoWidth;
@property (assign, nonatomic) CGFloat videoHeight;
@property (assign, nonatomic) CVPixelBufferPoolRef pool;
@property (strong, nonatomic) ZGImage *image;

@end

@implementation ZGExternalVideoRenderDemo

- (void)dealloc {
    [ZGApiManager releaseApi];
    [ZegoExternalVideoRender enableExternalVideoRender:NO type:VideoExternalRenderTypeDecodeRgbSeries];
    [ZegoExternalVideoRender.sharedInstance setExternalVideoRenderDelegate:nil];
}

- (instancetype)init {
    if (self = [super init]) {
        [ZGApiManager releaseApi];
        [ZegoExternalVideoRender enableExternalVideoRender:YES type:VideoExternalRenderTypeDecodeRgbSeries];
        [ZegoExternalVideoRender.sharedInstance setExternalVideoRenderDelegate:self];
        
        _image = [ZGImage imageNamed:@"watermark-zego.png"];
    }
    return self;
}

- (void)startLive {
    [self setupLiveRoom];
    [self loginLiveRoom];
}

- (void)stop {
    [self stopPlay];
    [self stopPreview];
    [self stopPublish];
    [ZGApiManager.api logoutRoom];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate onLiveStateUpdate];
    });
}


#pragma mark - Private

- (void)setupLiveRoom {
    ZegoAVConfig *config = [ZegoAVConfig presetConfigOf:ZegoAVConfigPreset_High];
    
    [ZGApiManager.api setAVConfig:config];
    [ZGApiManager.api setRoomDelegate:self];
    [ZGApiManager.api setPlayerDelegate:self];
    [ZGApiManager.api setPublisherDelegate:self];
}

- (void)loginLiveRoom {
    NSLog(NSLocalizedString(@"开始登录房间", nil));
    
    NSString *roomID = [self genRoomID];
    
    Weakify(self);
    [ZGApiManager.api loginRoom:roomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        Strongify(self);
        
        if (errorCode == 0) {
            NSLog(NSLocalizedString(@"登录房间成功. roomID: %@", nil), roomID);
            self.isLoginRoom = YES;
            [self startPreview];
            [self startPublish];
        }
        else {
            NSLog(NSLocalizedString(@"登录房间失败. error: %d", nil), errorCode);
            self.isLoginRoom = NO;
            [self stop];
        }
    }];
}

// SDK启动外部渲染VideoExternalRenderTypeDecodeRgbSeries模式，SDK就不会主动将视频数据渲染到指定的视图上，这里自己渲染
- (void)startPreview {
    if (self.isPreview) {
        return;
    }
    
//    [ZGApiManager.api setPreviewView:[self.delegate getMainPlaybackView]];
    [ZGApiManager.api startPreview];
    self.isPreview = YES;
    NSLog(NSLocalizedString(@"startPreview", nil));
}

- (void)stopPreview {
    if (!self.isPreview) {
        return;
    }
    
    [ZGApiManager.api stopPreview];
    self.isPreview = NO;
    NSLog(NSLocalizedString(@"stopPreview", nil));
    
    [ZGExternalVideoRenderHelper removeRenderDataInView:[self.delegate getMainPlaybackView]];
}

- (void)startPublish {
    if (!self.isLoginRoom || self.isPublishing) {
        return;
    }
    
    self.streamID = [self genStreamID];
    [ZGApiManager.api startPublishing:self.streamID title:nil flag:ZEGO_SINGLE_ANCHOR];
    
    NSLog(NSLocalizedString(@"startPublish:%@", nil), self.streamID);
}

- (void)stopPublish {
    if (!self.isPublishing) {
        return;
    }
    
    NSLog(NSLocalizedString(@"stopPublish", nil));
    
    self.isPublishing = NO;
    self.streamID = nil;
    [ZGApiManager.api stopPublishing];
}

- (void)startPlay {
    if (!self.isLoginRoom || self.isPlaying) {
        return;
    }
    
    NSAssert(self.streamID, @"streamID invalid");
    NSLog(NSLocalizedString(@"startPlay", nil));
    
    [ZGApiManager.api startPlayingStream:self.streamID inView:nil];
    [ZGApiManager.api setViewMode:ZegoVideoViewModeScaleToFill ofStream:self.streamID];
}

- (void)stopPlay {
    if (!self.isPlaying) {
        return;
    }
    
    NSAssert(self.streamID, @"streamID invalid");
    NSLog(NSLocalizedString(@"stopPlay", nil));
    [ZGApiManager.api stopPlayingStream:self.streamID];
    self.isPlaying = NO;
    
    [ZGExternalVideoRenderHelper removeRenderDataInView:[self.delegate getSubPlaybackView]];
}


#pragma mark - ZegoExternalVideoRenderDelegate

- (CVPixelBufferRef)onCreateInputBufferWithWidth:(int)width height:(int)height cvPixelFormatType:(OSType)cvPixelFormatType {
    NSLog(NSLocalizedString(@"onCreateInputBufferWithWidth:%d,height:%d", nil), width, height);
    
    if (self.videoWidth != width || self.videoHeight != height) {
        if (self.videoWidth && self.videoHeight) {
            CVPixelBufferPoolFlushFlags flag = 0;
            CVPixelBufferPoolFlush(self.pool, flag);
            CFRelease(self.pool);
            self.pool = nil;
        }
        
        self.videoWidth = width;
        self.videoHeight = height;
        [self createPixelBufferPool];
    }
    
    CVPixelBufferRef pixelBuffer;
    CVReturn ret = CVPixelBufferPoolCreatePixelBuffer(nil, self.pool, &pixelBuffer);
    if (ret != kCVReturnSuccess) {
        return nil;
    }
    
    return pixelBuffer;
}

- (void)onPixelBufferCopyed:(CVPixelBufferRef)pixelBuffer streamID:(NSString *)streamID {
    NSLog(NSLocalizedString(@"onPixelBufferCopyed:%@", nil), streamID);
    
    if ([streamID isEqualToString:kZegoVideoDataMainPublishingStream]) {//推流预览
        [self renderPreview:pixelBuffer];
    }
    else {//拉流
        [self renderPlay:pixelBuffer];
    }
    
    // 使用完毕在合适时机释放
    CVPixelBufferRelease(pixelBuffer);
}

- (void)createPixelBufferPool{
    NSDictionary *pixelBufferAttributes = @{
                                            (id)kCVPixelBufferOpenGLCompatibilityKey:@(YES),
                                            (id)kCVPixelBufferWidthKey:@(self.videoWidth),
                                            (id)kCVPixelBufferHeightKey:@(self.videoHeight),
                                            (id)kCVPixelBufferPixelFormatTypeKey:@((int)kCVPixelFormatType_32BGRA),
                                            };
    
    CFDictionaryRef ref = (__bridge CFDictionaryRef)pixelBufferAttributes;
    CVReturn ret = CVPixelBufferPoolCreate(nil, nil, ref, &_pool);
    
    if (ret != kCVReturnSuccess) {
        NSLog(NSLocalizedString(@"🍎createPixelBufferPool failed, error: %d", nil), ret);
    }
}

- (void)renderPreview:(CVPixelBufferRef)pixelBuffer {
    if (!self.isPreview) {
        return;
    }
    
    [ZGExternalVideoRenderHelper showRenderData:pixelBuffer inView:[self.delegate getMainPlaybackView] viewMode:ZegoVideoViewModeScaleAspectFill];
}

- (void)renderPlay:(CVPixelBufferRef)pixelBuffer {
    if (!self.isPlaying) {
        return;
    }
    
    CGImageRef cgImage;
#if TARGET_OS_OSX
    cgImage = [self.image CGImageForProposedRect:nil context:nil hints:nil];
#elif TARGET_OS_IOS
    cgImage = self.image.CGImage;
#endif
    
    CGFloat pixelW = CVPixelBufferGetWidth(pixelBuffer);
    CGFloat pixelH = CVPixelBufferGetHeight(pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    void *data = CVPixelBufferGetBaseAddress(pixelBuffer);

    time_t currentTime = time(0);
    
    CGFloat imageWith = CGImageGetWidth(cgImage);
    CGFloat imageHeight = CGImageGetHeight(cgImage);
    
    static CGPoint origin = {0, 0};
    static time_t lastTime = 0;
    
    if (lastTime != currentTime) {
        origin.x = rand() % (int)(pixelW - imageWith);
        origin.y = rand() % (int)(pixelH - imageHeight);
        
        lastTime = currentTime;
    }
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(data, pixelW, pixelH, 8,
                                                 CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                 rgbColorSpace,
                                                 kCGImageAlphaPremultipliedLast);
    
    CGImageRef bgraImage = [self CreateBGRAImageFromRGBAImage:cgImage];
    
    CGContextDrawImage(context,
                       CGRectMake(origin.x, origin.y, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage)),
                       bgraImage);
    
    CGImageRelease(bgraImage);
    CGContextRelease(context);
    CGColorSpaceRelease(rgbColorSpace);
    
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    [ZGExternalVideoRenderHelper showRenderData:pixelBuffer inView:[self.delegate getSubPlaybackView] viewMode:ZegoVideoViewModeScaleAspectFill];
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


#pragma mark - ZegoRoomDelegate

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    NSLog(NSLocalizedString(@"🍎连接失败, error: %d", nil), errorCode);
    self.isPublishing = NO;
    [self stop];
}


#pragma mark - ZegoLivePublisherDelegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    BOOL success = stateCode == 0;
    self.isPublishing = success;
    
    NSLog(NSLocalizedString(@"onPublishStateUpdate,success:%d", nil), success);
    
    success ? [self startPlay]:[self stop];
}


#pragma mark - ZegoLivePlayerDelegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    BOOL success = stateCode == 0;
    self.isPlaying = success;
    
    NSLog(NSLocalizedString(@"onPlayStateUpdate,success:%d", nil), success);
    
    success ? [self startPublish]:[self stop];
    
    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate onLiveStateUpdate];
        });
    }
}


#pragma mark - Access

- (BOOL)isLive {
    return self.isLoginRoom && self.isPublishing && self.isPlaying;
}

- (NSString *)genRoomID {
    unsigned long currentTime = (unsigned long)[[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"#evc-%@-%lu", ZGHelper.userID, currentTime];
}

- (NSString *)genStreamID {
    unsigned long currentTime = (unsigned long)[[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"s-%@-%lu", ZGHelper.userID, currentTime];
}


@end

#endif
