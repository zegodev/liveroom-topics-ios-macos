//
//  ZGExternalVideoRenderPublishStreamVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/9/3.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_ExternalVideoRender

#import "ZGExternalVideoRenderPublishStreamVC.h"
#import <ZegoLiveRoom/ZegoLiveRoomApi.h>
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZGUserIDHelper.h"
#import "ZGExternalVideoRenderHelper.h"
#import "ZGVideoRenderDataToPixelBufferConverter.h"
#import "ZGPixelBufferPoolController.h"


@interface ZGExternalVideoRenderPublishStreamVC () <ZegoRoomDelegate, ZegoLivePublisherDelegate, ZegoVideoRenderDelegate>

@property (nonatomic, weak) IBOutlet UIView *previewView;
@property (nonatomic) ZegoLiveRoomApi *zegoApi;
@property (nonatomic) ZGVideoRenderDataToPixelBufferConverter *renderDataToPixelBufferConverter;
@property (nonatomic) ZGPixelBufferPoolController *pixelBufferPoolController;
@property (nonatomic) dispatch_queue_t render_queue;

@end

@implementation ZGExternalVideoRenderPublishStreamVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"NewExternalVideoRender" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGExternalVideoRenderPublishStreamVC class])];
}

- (void)dealloc {
    NSLog(@"%@ dealloc.", [self class]);
    
    // 关闭外部渲染
    [ZegoExternalVideoRender setVideoRenderType:VideoRenderTypeNone];
    [[ZegoExternalVideoRender sharedInstance] setZegoVideoRenderDelegate:nil];
    
    // 停止预览、推流，退出房间
    [_zegoApi stopPreview];
    [_zegoApi stopPublishing];
    [_zegoApi logoutRoom];
    [_pixelBufferPoolController destroyAllPixelBufferPool];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"视频外部渲染-推流";
    _render_queue = dispatch_queue_create("RenderQueue", DISPATCH_QUEUE_SERIAL);
    
    [self setupZegoComponents];
    [self setupRenderDataToPixelBufferConverter];
    [self startLive];
}

- (void)setupZegoComponents {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    
    // 设置环境
    [ZegoLiveRoomApi setUseTestEnv:(appConfig.environment == ZGAppEnvironmentTest)];
    // 设置硬编硬解
    [ZegoLiveRoomApi requireHardwareEncoder:appConfig.openHardwareEncode];
    [ZegoLiveRoomApi requireHardwareDecoder:appConfig.openHardwareDecode];
    
    // 在初始化 SDK 前，设置外部渲染type，对预览视图进行外部渲染
    // 设置视频外部渲染 type
    [ZegoExternalVideoRender setVideoRenderType:self.previewRenderType];
    // 设置视频外部渲染 delegate
    [[ZegoExternalVideoRender sharedInstance] setZegoVideoRenderDelegate:self];
    
    // setup zegoApi
    self.zegoApi = [[ZegoLiveRoomApi alloc] initWithAppID:appConfig.appID appSignature:[ZGAppSignHelper convertAppSignFromString:appConfig.appSign]];
    [self.zegoApi setRoomDelegate:self];
    [self.zegoApi setPublisherDelegate:self];
    
    // 开启预览的外部渲染开关，需要在初始化 SDK 之后才有效
    [ZegoExternalVideoRender enableVideoPreview:YES channelIndex:ZEGOAPI_CHN_MAIN];
}

- (void)setupRenderDataToPixelBufferConverter {
    _renderDataToPixelBufferConverter = [[ZGVideoRenderDataToPixelBufferConverter alloc] init];
}

- (ZGPixelBufferPoolController *)pixelBufferPoolController {
    if (!_pixelBufferPoolController) {
        _pixelBufferPoolController = [[ZGPixelBufferPoolController alloc] init];
    }
    return _pixelBufferPoolController;
}

- (void)startLive {
    // 开始预览
    if (self.previewRenderType == VideoRenderTypeNone) {
        [_zegoApi setPreviewView:self.previewView];
    }else {
        [_zegoApi setPreviewView:nil];
    }
    [_zegoApi startPreview];
    
    // 设置userid，username
    NSString *userID = ZGUserIDHelper.userID;
    [ZegoLiveRoomApi setUserID:userID userName:userID];
    
    NSString *roomID = self.roomID;
    NSString *streamID = self.streamID;
    Weakify(self);
    // 登录房间
    [_zegoApi loginRoom:roomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        Strongify(self);
        if (errorCode != 0) {
            ZGLogWarn(@"登录房间失败，errorCode:%d", errorCode);
            return;
        }
        ZGLogInfo(@"登录房间成功");
        
        // 开始推流
        ZGLogInfo(@"请求推流");
        [self.zegoApi startPublishing:streamID title:nil flag:ZEGO_SINGLE_ANCHOR];
    }];
}

#pragma mark - ZegoRoomDelegate

- (void)onKickOut:(int)reason roomID:(NSString *)roomID {
    ZGLogWarn(@"%s, reason:%d", __func__, reason);
}

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"%s, errorCode:%d", __func__, errorCode);
}

- (void)onReconnect:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"%s, errorCode:%d", __func__, errorCode);
}

#pragma mark - ZegoLivePublisherDelegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    if (stateCode == 0) {
        ZGLogInfo(@"推流成功");
    } else {
        ZGLogWarn(@"推流失败。stateCode:%d", stateCode);
    }
}

- (void)onPublishQualityUpdate:(NSString *)streamID quality:(ZegoApiPublishQuality)quality {
    NSLog(@"推流质量。fps:%f,vencFps:%f,videoBitrate:%f, quanlity:%d, width:%d, height:%d", quality.fps, quality.vencFps, quality.kbps, quality.quality, quality.width, quality.height);
}

#pragma mark - ZegoVideoRenderDelegate

/**
 SDK 待渲染视频数据
 
 @param data 待渲染数据, 当 VideoRenderType 设置为 VideoRenderTypeExternalInternalRgb 或者 VideoRenderTypeExternalInternalYuv 时，SDK 会使用修改后的 data 进行渲染
 @param dataLen 待渲染数据每个平面的数据大小，共 4 个面
 @param width 图像宽
 @param height 图像高
 @param strides 每个平面一行字节数，共 4 个面（RGBA 只需考虑 strides[0]）
 @param pixelFormat format type, 用于指定 data 的数据类型
 @streamID 流名
 */
- (void)onVideoRenderCallback:(unsigned char **)data dataLen:(int*)dataLen width:(int)width height:(int)height strides:(int[])strides pixelFormat:(VideoPixelFormat)pixelFormat streamID:(NSString *)streamID {
    BOOL isPreviewData = NO;
    // 由于是对预览视图进行外部渲染，此时的 streamID 等于 kZegoVideoDataMainPublishingStream 或 kZegoVideoDataAuxPublishingStream
    if ([streamID isEqualToString:kZegoVideoDataMainPublishingStream] ||
        [streamID isEqualToString:kZegoVideoDataAuxPublishingStream]) {
        isPreviewData = YES;
    }
    
    if (isPreviewData) {
        // 通过 CVPixelBufferPool 来创建 CVPixelBuffer
        OSType appleFormat = [ZGVideoRenderDataToPixelBufferConverter getApplePixelFormatFromZego:pixelFormat];
        if (appleFormat == 0) {
            return;
        }
        ZGPixelBufferPool *poolObj = [self.pixelBufferPoolController getPixelBufferPool:streamID];
        if (!poolObj || ([poolObj width] != width || [poolObj height] != height || [poolObj format] != appleFormat)) {
            if (poolObj) {
                [self.pixelBufferPoolController destroyPixelBufferPool:streamID];
            }
            poolObj = [self.pixelBufferPoolController createPixelBufferPool:width height:height format:appleFormat streamID:streamID];
            if (!poolObj) {
                return;
            }
        }
        
        CVPixelBufferRef pixelBuffer;
        CVReturn ret = CVPixelBufferPoolCreatePixelBuffer(nil, [poolObj bufferPool], &pixelBuffer);
        if (ret != kCVReturnSuccess) {
            NSLog(@"[onVideoRenderCallback] pixelbuffer pool creates pixelbuffer failed, error: %d", ret);
            return;
        }
        
        
        // 自定义外部渲染逻辑，改变数据，这里变成灰度图像。业务可以根据 pixelFormat 自行处理
        // begin
        if (pixelFormat == PixelFormatI420) {
            unsigned char *pU = data[1];
            unsigned char *pV = data[2];
            
            memset(pU, 0x80, sizeof(char) * dataLen[1]);
            memset(pV, 0x80, sizeof(char) * dataLen[2]);
        } else if (pixelFormat == PixelFormatBGRA32) {
            unsigned char *pRgba32 = data[0];
            for (int i = 0; i < dataLen[0]; i += 4) {
                unsigned char R = pRgba32[i];
                unsigned char G = pRgba32[i + 1];
                unsigned char B = pRgba32[i + 2];
                
                unsigned char Gray = R * 0.3 + G * 0.59 + B * 0.11;
                pRgba32[i] = Gray;
                pRgba32[i + 1] = Gray;
                pRgba32[i + 2] = Gray;
            }
        }
        
        // 自定义外部渲染逻辑
        // end
        
        // 在对于预览的渲染时，由于 SDK 不会内部渲染，修改 data 不会生效，所以也需要自定义显示渲染视图
        if (![ZGExternalVideoRenderHelper isInternalVideoRenderType:self.previewRenderType]) {
            const unsigned char **originData = (const unsigned char **)data;
            [ZGVideoRenderDataToPixelBufferConverter copyToPixelBuffer:pixelBuffer withData:originData dataLen:dataLen width:width height:height strides:strides pixelFormat:pixelFormat];
            
            // 模拟一个消费者消费 pixelBuffer
            CVPixelBufferRetain(pixelBuffer);
            dispatch_async(_render_queue, ^{
                [ZGExternalVideoRenderHelper showRenderData:pixelBuffer inView:self.previewView viewMode:ZegoVideoViewModeScaleAspectFit];
                CVPixelBufferRelease(pixelBuffer);
            });
            
            CVPixelBufferRelease(pixelBuffer);
        } else {
            CVPixelBufferRelease(pixelBuffer);
        }
    }
}

- (void)onSetFlipMode:(int)mode streamID:(NSString *)streamID {
    // TODO: 如果有镜像，这里需要处理。mode 参考 `ZegoVideoFlipMode`
}

- (void)onSetRotation:(int)rotation streamID:(NSString *)streamID {
    // TODO: 如果有旋转，这里需要处理。rotation 为逆时针旋转角度
}

@end
#endif
