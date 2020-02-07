//
//  ZGExternalVideoCaptureViewController.m
//  LiveRoomPlayground-macOS
//
//  Created by Sky on 2019/1/25.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoCapture

#import "ZGExternalVideoCaptureViewController.h"
#import <MetalKit/MetalKit.h>
#import <Metal/Metal.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi.h>
#import <ZegoLiveRoomOSX/zego-api-external-video-capture-oc.h>
#import "ZGMetalPreviewYUVRenderer.h"
#import "ZGMetalPreviewBGRARenderer.h"
#import "ZGDemoExternalVideoCameraCaptureController.h"
#import "ZGDemoExternalVideoImageCaptureController.h"
#import "ZGDemoExternalVideoSreenCaptureController.h"
#import "ZGDemoExternalVideoCaptureFactory.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "Masonry.h"

@interface ZGExternalVideoCaptureViewController () <ZGDemoExternalVideoCaptureControllerDelegate, ZegoLivePublisherDelegate>

@property (nonatomic, weak) IBOutlet NSView *mainVideoView;
@property (nonatomic, weak) IBOutlet NSTextField *roomIDTxf;
@property (nonatomic, weak) IBOutlet NSTextField *streamIDTxf;
@property (nonatomic, weak) IBOutlet NSPopUpButton *sourceTypeBtn;
@property (nonatomic, weak) IBOutlet NSPopUpButton *dataFormatBtn;
@property (nonatomic, weak) IBOutlet NSButton *startPublishBtn;
@property (nonatomic, weak) IBOutlet NSTextField *inputTipLabel;

@property (nonatomic, strong) MTKView *mtkPreviewView;
@property (nonatomic) id<ZGMetalPreviewRendererProtocol> metalPreviewRenderer;
@property (nonatomic) id<ZGDemoExternalVideoCaptureControllerProtocol> videoCaptureController;
@property (nonatomic) ZGDemoExternalVideoCaptureFactory *externalVideoCaptureFactory;

@property (nonatomic) ZegoLiveRoomApi *zegoApi;
@property (nonatomic) BOOL isPublishing;

@end

@implementation ZGExternalVideoCaptureViewController

- (void)viewDidAppear {
    [super viewDidAppear];
    
    self.inputTipLabel.stringValue = @"";
    [self setupMtkPreviewViewIfNeed];
    [self invalidatePublishBtn];
    [self invalidateCanCaptureTip];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    // leave page
    [self stopLive];
}

- (IBAction)onCaptureSourceTypeChange:(NSPopUpButton *)sender {
    [self invalidateCanCaptureTip];
}

- (IBAction)onCaptureDataFormatChange:(NSPopUpButton *)sender {
    [self invalidateCanCaptureTip];
}

- (IBAction)publishBtnClick:(id)sender {
    if (self.isPublishing) {
        [self stopLive];
    } else {
        [self startLive];
    }
}

#pragma mark - private methods

// 1: camera source  2:image source 3: screen record source
- (NSInteger)captureSource {
    return self.sourceTypeBtn.indexOfSelectedItem + 1;
}

// 1:YUV  2:BRGA
- (NSInteger)captureDataFormat {
    return self.dataFormatBtn.indexOfSelectedItem + 1;
}

- (void)setupMtkPreviewViewIfNeed {
    if (!_mtkPreviewView) {
        _mtkPreviewView = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, 375, 640) device:MTLCreateSystemDefaultDevice()];
//        _mtkPreviewView.framebufferOnly = YES;
//        _mtkPreviewView.preferredFramesPerSecond = 0;
#if TARGET_OS_IOS
        _mtkPreviewView.contentScaleFactor = UIScreen.mainScreen.scale;
#endif
        [self.mainVideoView addSubview:_mtkPreviewView];
        
        [_mtkPreviewView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.bottom.mas_equalTo(0);
            make.leading.trailing.mas_equalTo(0);
        }];
    }
}

- (void)setupMetalPreviewRendererIfNeed {
    if (!_metalPreviewRenderer) {
        
        NSInteger dataFormat = self.captureDataFormat;
        if (dataFormat == 1) {
            // YUV
            _metalPreviewRenderer = [[ZGMetalPreviewYUVRenderer alloc] initWithDevice:self.mtkPreviewView.device forRenderView:self.mtkPreviewView];
        } else if (dataFormat == 2) {
            // BRGA
            _metalPreviewRenderer = [[ZGMetalPreviewBGRARenderer alloc] initWithDevice:self.mtkPreviewView.device forRenderView:self.mtkPreviewView];
        }
    }
}

- (void)setupVideoCaptureControllerIfNeed {
    if (!_videoCaptureController) {
        NSInteger captureSource = self.captureSource;
        NSInteger dataFormat = self.captureDataFormat;
        if (captureSource == 1) {
            // camera capture
            OSType pixelFormat = kCVPixelFormatType_32BGRA;
            if (dataFormat == 1) {
                pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
            }
            _videoCaptureController = [[ZGDemoExternalVideoCameraCaptureController alloc] initWithPixelFormatType:pixelFormat];
            _videoCaptureController.delegate = self;
        } else if (captureSource == 2) {
            // image capture
            if (dataFormat == 2) {
                _videoCaptureController = [[ZGDemoExternalVideoImageCaptureController alloc] initWithMotionImage:[NSImage imageNamed:@"ZegoLogo.png"]];
                _videoCaptureController.delegate = self;
            }
            // 图像 capture source 暂不支持 YUV 的类型
        } else if (captureSource == 3) {
            OSType pixelFormat = kCVPixelFormatType_32BGRA;
            if (dataFormat == 1) {
                pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
            }
            _videoCaptureController = [[ZGDemoExternalVideoSreenCaptureController alloc] initWithPixelFormatType:pixelFormat];
            _videoCaptureController.delegate = self;
        }
    }
}

- (ZGDemoExternalVideoCaptureFactory *)externalVideoCaptureFactory {
    if (!_externalVideoCaptureFactory) {
        ZGDemoExternalVideoCaptureFactory *factory = [[ZGDemoExternalVideoCaptureFactory alloc] init];
        
        __weak typeof(self) weakSelf = self;
        factory.onStartPreview = ^BOOL{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return NO;
            return [strongSelf->_videoCaptureController start];
        };
        factory.onStopPreview = ^{
            
        };
        factory.onStartCapture = ^BOOL{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return NO;
            return [strongSelf->_videoCaptureController start];
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

- (void)startPreviewAndPublish:(NSString *)streamID {
    // 外部视频采集的预览，需要自己实现
    [self setupMtkPreviewViewIfNeed];
    [self setupMetalPreviewRendererIfNeed];
    [self setupVideoCaptureControllerIfNeed];
    [self.zegoApi startPreview];
    
    // 开始推流，在 ZegoLivePublisherDelegate 的 onPublishStateUpdate:streamID:streamInfo: 中或知推流结果
    self.startPublishBtn.enabled = NO;
    if ([self.zegoApi startPublishing:streamID title:nil flag:ZEGO_SINGLE_ANCHOR]) {
        ZGLogInfo(@"请求推流");
    }
}

- (void)stopPreview {
    _metalPreviewRenderer = nil;
    [_mtkPreviewView removeFromSuperview];
    _mtkPreviewView = nil;
    
    [_zegoApi stopPreview];
}

- (void)stopLive {
    [_videoCaptureController stop];
    _videoCaptureController = nil;
    
    [self stopPreview];
    [_zegoApi stopPublishing];
    [_zegoApi logoutRoom];
    _zegoApi = nil;
    [ZegoExternalVideoCapture setVideoCaptureFactory:nil channelIndex:ZEGOAPI_CHN_MAIN];
    
    self.isPublishing = NO;
    [self invalidatePublishBtn];
    self.inputTipLabel.stringValue = @"";
}

- (void)startLive {
    NSString *roomID = self.roomIDTxf.stringValue;
    NSString *streamID = self.streamIDTxf.stringValue;
    if (roomID.length == 0 || streamID.length == 0) {
        return;
    }
    
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
    NSString *userID = [NSString stringWithFormat:@"u-%ld", (long)[NSDate date].timeIntervalSince1970];
    [ZegoLiveRoomApi setUserID:userID userName:userID];
    
    // 登录房间
    Weakify(self);
    BOOL reqResult = [_zegoApi loginRoom:roomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        Strongify(self);
        self.startPublishBtn.enabled = YES;
        if (errorCode != 0) {
            ZGLogWarn(@"登录房间失败,errorCode:%d", errorCode);
            // 登录房间失败
            return;
        }
        
        ZGLogInfo(@"登录房间成功");
        
        // 登录房间成功
        // 开始预览和推流
        [self startPreviewAndPublish:streamID];
    }];
    if (reqResult) {
        ZGLogInfo(@"请求登录房间");
        self.startPublishBtn.enabled = NO;
    } else {
        ZGLogWarn(@"请求登录房间失败");
    }
}

- (void)invalidatePublishBtn {
    if (self.isPublishing) {
        self.startPublishBtn.title = @"停止推流";
    } else {
        self.startPublishBtn.title = @"发起推流";
    }
}

- (void)invalidateCanCaptureTip {
    NSString *tip = @"";
    if (self.captureSource == 2) {
        // image source
        if (self.captureDataFormat == 1) {
            tip = @"不支持该格式输出";
        }
    }
    self.inputTipLabel.stringValue = tip;
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
        ZGLogWarn(@"推流成功");
    } else {
        ZGLogWarn(@"推流失败, stateCode:%d", stateCode);
    }
    
    self.startPublishBtn.enabled = YES;
    self.isPublishing = stateCode == 0;
    [self invalidatePublishBtn];
    
    if (!self.isPublishing) {
        [self stopLive];
    }
}

@end

#endif
