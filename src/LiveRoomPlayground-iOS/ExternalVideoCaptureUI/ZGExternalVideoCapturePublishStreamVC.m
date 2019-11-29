//
//  ZGExternalVideoCapturePublishStreamVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/15.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_ExternalVideoCapture

#import "ZGExternalVideoCapturePublishStreamVC.h"
#import <MetalKit/MetalKit.h>
#import <Metal/Metal.h>
#import <ZegoLiveRoom/ZegoLiveRoom.h>
#import <ZegoLiveRoom/zego-api-external-video-capture-oc.h>
#import "ZGMetalPreviewYUVRenderer.h"
#import "ZGMetalPreviewBGRARenderer.h"
#import "ZGDemoExternalVideoCameraCaptureController.h"
#import "ZGDemoExternalVideoImageCaptureController.h"
#import "ZGDemoExternalVideoCaptureFactory.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZGUserIDHelper.h"
#import "Masonry.h"

@interface ZGExternalVideoCapturePublishStreamVC () <ZGDemoExternalVideoCaptureControllerDelegate, ZegoLivePublisherDelegate>

@property (nonatomic) MTKView *mtkPreviewView;
@property (nonatomic) id<ZGMetalPreviewRendererProtocol> metalPreviewRenderer;
@property (nonatomic) id<ZGDemoExternalVideoCaptureControllerProtocol> videoCaptureController;
@property (nonatomic) ZGDemoExternalVideoCaptureFactory *externalVideoCaptureFactory;

@property (nonatomic) ZegoLiveRoomApi *zegoApi;

@end

@implementation ZGExternalVideoCapturePublishStreamVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"VideoExternalCapture" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGExternalVideoCapturePublishStreamVC class])];
}

- (void)dealloc {
    NSLog(@"%@ dealloc.", [self class]);
    
    [_videoCaptureController stop];
    [self stopPreview];
    [self.zegoApi stopPublishing];
    [self.zegoApi logoutRoom];
    [ZegoExternalVideoCapture setVideoCaptureFactory:nil channelIndex:ZEGOAPI_CHN_MAIN];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"视频外部采集-推流";
    [self setupMtkPreviewViewIfNeed];
    [self setupMetalPreviewRendererIfNeed];
    [self startLive];
}

#pragma mark - private methods

- (void)setupMtkPreviewViewIfNeed {
    if (!_mtkPreviewView) {
        _mtkPreviewView = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, 375, 640) device:MTLCreateSystemDefaultDevice()];
        _mtkPreviewView.framebufferOnly = YES;
        _mtkPreviewView.preferredFramesPerSecond = 0;
#if TARGET_OS_IOS
        _mtkPreviewView.contentScaleFactor = UIScreen.mainScreen.scale;
#endif
        [self.view addSubview:_mtkPreviewView];
        
        [_mtkPreviewView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_topLayoutGuide);
            make.bottom.equalTo(self.mas_bottomLayoutGuide);
            make.leading.trailing.mas_equalTo(0);
        }];
    }
}

- (void)setupMetalPreviewRendererIfNeed {
    if (!_metalPreviewRenderer) {
        
        if (self.captureDataFormat == 1) {
            // YUV
            _metalPreviewRenderer = [[ZGMetalPreviewYUVRenderer alloc] initWithDevice:self.mtkPreviewView.device forRenderView:self.mtkPreviewView];
        } else if (self.captureDataFormat == 2) {
            // BRGA
            _metalPreviewRenderer = [[ZGMetalPreviewBGRARenderer alloc] initWithDevice:self.mtkPreviewView.device forRenderView:self.mtkPreviewView];
        }
    }
}

- (id<ZGDemoExternalVideoCaptureControllerProtocol>)videoCaptureController {
    if (!_videoCaptureController) {
        if (self.captureSource == 1) {
            // camera capture
            OSType pixelFormat = kCVPixelFormatType_32BGRA;
            if (self.captureDataFormat == 1) {
                pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
            }
            _videoCaptureController = [[ZGDemoExternalVideoCameraCaptureController alloc] initWithPixelFormatType:pixelFormat];
            _videoCaptureController.delegate = self;
        } else if (self.captureSource == 2) {
            // image capture, FIXME: 还不支持该类型
            if (self.captureDataFormat == 2) {
                _videoCaptureController = [[ZGDemoExternalVideoImageCaptureController alloc] initWithMotionImage:[UIImage imageNamed:@"watermark-zego.png"]];
                _videoCaptureController.delegate = self;
            }
            // 图像 capture source 暂不支持 YUV 的类型
        } else if (self.captureSource == 3) {
            // screen record, FIXME: 还不支持该类型
        }
    }
    return _videoCaptureController;
}

- (ZGDemoExternalVideoCaptureFactory *)externalVideoCaptureFactory {
    if (!_externalVideoCaptureFactory) {
        ZGDemoExternalVideoCaptureFactory *factory = [[ZGDemoExternalVideoCaptureFactory alloc] init];
        
        __weak typeof(self) weakSelf = self;
        factory.onStartPreview = ^BOOL{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return NO;
            return [strongSelf.videoCaptureController start];
        };
        factory.onStopPreview = ^{
            
        };
        factory.onStartCapture = ^BOOL{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return NO;
            return [strongSelf.videoCaptureController start];
        };
        factory.onStopCapture = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf->_videoCaptureController stop];
                [strongSelf stopPreview];
            });
        };
        
        _externalVideoCaptureFactory = factory;
    }
    return _externalVideoCaptureFactory;
}

- (void)startPreview {
    // 外部视频采集的预览，需要自己实现
    [self setupMtkPreviewViewIfNeed];
    [self setupMetalPreviewRendererIfNeed];
    [self.zegoApi startPreview];
}

- (void)stopPreview {
    _metalPreviewRenderer = nil;
    [_mtkPreviewView removeFromSuperview];
    _mtkPreviewView = nil;
    
    [_zegoApi stopPreview];
}

- (void)startLive {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    
    // 设置 SDK 环境，需要在 init SDK 之前设置，后面调用 SDK 的 api 才能在该环境内执行
    // 设置环境
    [ZegoLiveRoomApi setUseTestEnv:(appConfig.environment == ZGAppEnvironmentTest)];
    // 设置硬编硬解
    [ZegoLiveRoomApi requireHardwareEncoder:appConfig.openHardwareEncode];
    [ZegoLiveRoomApi requireHardwareDecoder:appConfig.openHardwareDecode];
    
    // 设置是否使用外部视频采集    
    [ZegoExternalVideoCapture setVideoCaptureFactory:self.externalVideoCaptureFactory channelIndex:ZEGOAPI_CHN_MAIN];
    
    // init SDK
    ZGLogInfo(@"请求初始化");
    self.zegoApi = [[ZegoLiveRoomApi alloc] initWithAppID:(unsigned int)appConfig.appID appSignature:[ZGAppSignHelper convertAppSignFromString:appConfig.appSign] completionBlock:^(int errorCode) {
        if (errorCode != 0) {
            ZGLogWarn(@"初始化失败，errorCode:%d", errorCode);
        } else {
            ZGLogInfo(@"初始化成功");
        }
    }];
    if (!self.zegoApi) {
        ZGLogWarn(@"初始化失败，请检查参数是否正确");
    } else {
        // 设置 SDK 相关代理
        [self.zegoApi setPublisherDelegate:self];
    }
    
    // 获取 userID，userName 并设置到 SDK 中。必须在 loginRoom 之前设置，否则会出现登录不进行回调的问题
    // 这里演示简单将时间戳作为 userID，将 userID 和 userName 设置成一样。实际使用中可以根据需要，设置成业务相关的 userID
    NSString *userID = ZGUserIDHelper.userID;
    [ZegoLiveRoomApi setUserID:userID userName:userID];
    
    // 登录房间
    Weakify(self);
    [ZegoHudManager showNetworkLoading];
    BOOL reqResult = [_zegoApi loginRoom:self.roomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
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
        // 开始预览
        [self startPreview];
        
        // 开始推流，在 ZegoLivePublisherDelegate 的 onPublishStateUpdate:streamID:streamInfo: 中或知推流结果
        if ([self.zegoApi startPublishing:self.streamID title:nil flag:ZEGO_SINGLE_ANCHOR]) {
            ZGLogInfo(@"请求推流");
        }
    }];
    if (reqResult) {
        ZGLogInfo(@"请求登录房间");
    } else {
        ZGLogWarn(@"请求登录房间失败");
    }
}

#pragma mark - ZGDemoExternalVideoCaptureControllerDelegate

- (void)externalVideoCaptureController:(id<ZGDemoExternalVideoCaptureControllerProtocol>)controller didCapturedData:(CVImageBufferRef)imageData presentationTimeStamp:(CMTime)presentationTimeStamp {
    
    // 推流
    [_externalVideoCaptureFactory postCapturedData:imageData withPresentationTimeStamp:presentationTimeStamp];
    
    // 预览
    CVBufferRetain(imageData);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_metalPreviewRenderer displayPixelBuffer:imageData];
        CVBufferRelease(imageData);
    });
}

#pragma mark - ZegoLivePublisherDelegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    if (stateCode == 0) {
        ZGLogInfo(@"推流成功, streamID:%@", streamID);
    } else {
        ZGLogWarn(@"推流失败, streamID:%@", streamID);
    }
}

@end
#endif
