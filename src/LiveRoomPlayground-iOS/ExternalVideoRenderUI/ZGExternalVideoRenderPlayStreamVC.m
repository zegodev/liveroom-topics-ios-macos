//
//  ZGExternalVideoRenderPlayStreamVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/9/3.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_ExternalVideoRender

#import "ZGExternalVideoRenderPlayStreamVC.h"
#import <ZegoLiveRoom/ZegoLiveRoomApi.h>
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZGUserIDHelper.h"
#import "ZGExternalVideoRenderHelper.h"
#import "ZGVideoRenderDataToPixelBufferConverter.h"
#import "ZGPixelBufferPoolController.h"

@interface ZGExternalVideoRenderPlayStreamVC () <ZegoLivePlayerDelegate, ZegoVideoRenderDelegate>

@property (nonatomic, weak) IBOutlet UIView *playLiveView;

@property (nonatomic) ZegoLiveRoomApi *zegoApi;
@property (nonatomic) ZGVideoRenderDataToPixelBufferConverter *renderDataToPixelBufferConverter;

@property (nonatomic) ZGPixelBufferPoolController *pixelBufferPoolController;
@property (nonatomic) dispatch_queue_t render_queue;

@end

@implementation ZGExternalVideoRenderPlayStreamVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"NewExternalVideoRender" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGExternalVideoRenderPlayStreamVC class])];
}

- (void)dealloc {
    NSLog(@"%@ dealloc.", [self class]);
    
    // 关闭外部渲染
    [ZegoExternalVideoRender setVideoRenderType:VideoRenderTypeNone];
    [[ZegoExternalVideoRender sharedInstance] setZegoVideoRenderDelegate:nil];
    
    [_zegoApi stopPlayingStream:self.streamID];
    [_zegoApi logoutRoom];
    [_pixelBufferPoolController destroyAllPixelBufferPool];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"拉流";
    _render_queue = dispatch_queue_create("RenderQueue", DISPATCH_QUEUE_SERIAL);
    
    [self setupZegoComponents];
    [self setupRenderDataToPixelBufferConverter];
    [self startPlayLive];
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
    [ZegoExternalVideoRender setVideoRenderType:self.viewRenderType];
    // 设置视频外部渲染 delegate
    [[ZegoExternalVideoRender sharedInstance] setZegoVideoRenderDelegate:self];
    
    // setup zegoApi
    self.zegoApi = [[ZegoLiveRoomApi alloc] initWithAppID:appConfig.appID appSignature:[ZGAppSignHelper convertAppSignFromString:appConfig.appSign]];
    [self.zegoApi setPlayerDelegate:self];
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

- (void)startPlayLive {
    
    // 获取 userID，userName 并设置到 SDK 中。必须在 loginRoom 之前设置，否则会出现登录不进行回调的问题
    // 这里演示简单将时间戳作为 userID，将 userID 和 userName 设置成一样。实际使用中可以根据需要，设置成业务相关的 userID
    NSString *userID = ZGUserIDHelper.userID;
    [ZegoLiveRoomApi setUserID:userID userName:userID];
    
    // 登录房间
    Weakify(self);
    [ZegoHudManager showNetworkLoading];
    BOOL reqResult = [_zegoApi loginRoom:self.roomID role:ZEGO_AUDIENCE withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        Strongify(self);
        [ZegoHudManager hideNetworkLoading];
        
        if (errorCode != 0) {
            ZGLogWarn(@"登录房间失败,errorCode:%d", errorCode);
            // 登录房间失败
            [ZegoHudManager showMessage:[NSString stringWithFormat:@"登录房间失败,errorCode:%d", errorCode]];
            return;
        }
        
        ZGLogInfo(@"登录房间成功");
        
        // 登录房间成功
        // 开始拉流
        [self startPlayStream];
    }];
    if (reqResult) {
        ZGLogInfo(@"请求登录房间");
    } else {
        ZGLogWarn(@"请求登录房间失败");
    }
}

- (void)startPlayStream {
    NSString *streamID = self.streamID;
    if (streamID) {
        // 开始拉流, 在 ZegoLivePlayerDelegate
        ZGLogInfo(@"开始拉流，streamID: %@", streamID);
        self.navigationItem.title = @"拉流请求...";
        if (self.viewRenderType == VideoRenderTypeNone) {
            [self.zegoApi startPlayingStream:streamID inView:self.playLiveView];
        }else {
            // 外部渲染时，这里传给 SDK 的 View 不可以与自渲染使用的 View 相同，此处传nil仅做示例
            [self.zegoApi startPlayingStream:streamID inView:nil];
        }
        [self.zegoApi setViewMode:ZegoVideoViewModeScaleAspectFit ofStream:streamID];
        // 开启该 stream 的外部渲染，必须在拉流之后才能生效
        [ZegoExternalVideoRender enableVideoRender:YES streamID:streamID];
    }
}

#pragma mark - ZegoLivePlayerDelegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    // 播放流状态回调
    if (stateCode == 0) {
        ZGLogInfo(@"拉流成功，streamID:%@", streamID);
        self.navigationItem.title = @"拉流成功";
    } else {
        ZGLogWarn(@"拉流失败，streamID:%@，stateCode:%d", streamID, stateCode);
        self.navigationItem.title = @"拉流失败";
    }
}

- (void)onPlayQualityUpate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality {
    // 观看质量更新
    NSLog(@"拉流质量。vdecFps:%f,videoBitrate:%f, quanlity:%d", quality.vdecFps, quality.kbps, quality.quality);
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
    BOOL handleData = NO;
    if ([streamID isEqualToString:self.streamID]) {
        handleData = YES;
    }
    
    if (handleData) {
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
        
        // 对于拉流的渲染时，某些类型 SDK 不会做内部渲染，所以也需要自定义显示渲染视图
        if (![ZGExternalVideoRenderHelper isInternalVideoRenderType:self.viewRenderType]) {
            const unsigned char **originData = (const unsigned char **)data;
            [ZGVideoRenderDataToPixelBufferConverter copyToPixelBuffer:pixelBuffer withData:originData dataLen:dataLen width:width height:height strides:strides pixelFormat:pixelFormat];
            
            // 模拟一个消费者消费 pixelBuffer
            CVPixelBufferRetain(pixelBuffer);
            dispatch_async(_render_queue, ^{
                [ZGExternalVideoRenderHelper showRenderData:pixelBuffer inView:self.playLiveView viewMode:ZegoVideoViewModeScaleAspectFit];
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
