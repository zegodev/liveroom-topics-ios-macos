//
//  ZGMediaSideInfoPublishVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/21.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_MediaSideInfo

#import "ZGMediaSideInfoPublishVC.h"
#import <ZegoLiveRoom/ZegoLiveRoom.h>
#import "ZGMediaSideInfoDemo.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZGUserIDHelper.h"

@interface ZGMediaSideInfoPublishVC () <ZegoRoomDelegate, ZegoLivePublisherDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UITextView *sideInfoTextView;
@property (weak, nonatomic) IBOutlet UIButton *showSideInfoInputButn;

@property (nonatomic) ZegoLiveRoomApi *zegoApi;
@property (nonatomic) ZGMediaSideInfoDemo *mediaSideInfoController;

@property (nonatomic) UIAlertController *sendSideInfoMessageAlertVC;
@property (nonatomic) UITextField *sendSideInfoMessageTextField;

@end

@implementation ZGMediaSideInfoPublishVC

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MediaSideInfo" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGMediaSideInfoPublishVC class])];
}

- (void)dealloc {
    NSLog(@"%@ dealloc.", [self class]);
    [self stopLive];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self initializeZegoApiThenStartLive];
}

- (IBAction)showSideInfoInputButnClick:(id)sender {
    [self showSendSideInfoMessageUI];
}

#pragma mark - private methods

- (void)setupUI {
    self.navigationItem.title = @"媒体次要信息推流";
    self.sideInfoTextView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    self.sideInfoTextView.textColor = [UIColor whiteColor];
    self.sideInfoTextView.textContainerInset = UIEdgeInsetsMake(-8, 0, 0, 0);
    self.sideInfoTextView.text = nil;
}

- (UIAlertController *)sendSideInfoMessageAlertVC {
    if (!_sendSideInfoMessageAlertVC) {
        _sendSideInfoMessageAlertVC = [UIAlertController alertControllerWithTitle:@"发送媒体次要消息" message:nil preferredStyle:UIAlertControllerStyleAlert];
        Weakify(self);
        [_sendSideInfoMessageAlertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            Strongify(self);
            self.sendSideInfoMessageTextField = textField;
            textField.returnKeyType = UIReturnKeySend;
            textField.delegate = self;
        }];
        
        [_sendSideInfoMessageAlertVC addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil]];
        [_sendSideInfoMessageAlertVC addAction:[UIAlertAction actionWithTitle:@"发送" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            Strongify(self);
            [self sendCurrentInputTextAsMediaSideMessage];
            self->_sendSideInfoMessageTextField.text = nil;
            [self->_sendSideInfoMessageTextField resignFirstResponder];
        }]];
    }
    return _sendSideInfoMessageAlertVC;
}

- (ZGMediaSideInfoDemo *)mediaSideInfoController {
    if (!_mediaSideInfoController) {
        ZGMediaSideInfoDemoConfig *conf = [[ZGMediaSideInfoDemoConfig alloc] init];
        conf.onlyAudioPublish = self.onlyAudioPublish;
        _mediaSideInfoController = [[ZGMediaSideInfoDemo alloc] initWithConfig:conf];
    }
    return _mediaSideInfoController;
}

- (void)initializeZegoApiThenStartLive {
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    
    // 设置 SDK 环境，需要在 init SDK 之前设置，后面调用 SDK 的 api 才能在该环境内执行
    [ZegoLiveRoomApi setUseTestEnv:(appConfig.environment == ZGAppEnvironmentTest)];
    
    // init SDK
    ZGLogInfo(@"请求初始化");
    [ZegoHudManager showNetworkLoading];
    Weakify(self);
    self.zegoApi = [[ZegoLiveRoomApi alloc] initWithAppID:(unsigned int)appConfig.appID appSignature:[ZGAppSignHelper convertAppSignFromString:appConfig.appSign] completionBlock:^(int errorCode) {
        Strongify(self);
        [ZegoHudManager hideNetworkLoading];
        if (errorCode == 0) {
            ZGLogInfo(@"初始化完成");
        } else {
            ZGLogWarn(@"初始化失败，errorCode:%d",errorCode);
        }
        
        [self startLive];
    }];
    if (!self.zegoApi) {
        [ZegoHudManager hideNetworkLoading];
        ZGLogInfo(@"初始化失败");
    } else {
        // 设置 SDK 相关代理
        [self.zegoApi setRoomDelegate:self];
        [self.zegoApi setPublisherDelegate:self];
    }
}

- (void)startLive {
    // 预览
    [self.zegoApi enableCamera:!self.onlyAudioPublish];
    if (!self.onlyAudioPublish) {
        [self.zegoApi setPreviewView:self.previewView];
        [self.zegoApi startPreview];
    }
    
    // 获取 userID，userName 并设置到 SDK 中。
    // 必须在 loginRoom 之前设置，否则会出现登录不进行回调的问题
    // 这里演示简单将时间戳作为 userID，将 userID 和 userName 设置成一样。实际使用中可以根据需要，设置成业务相关的 userID
    NSString *userID = ZGUserIDHelper.userID;
    [ZegoLiveRoomApi setUserID:userID userName:userID];
    
    NSString *roomID = self.roomID;
    NSString *streamID = self.streamID;
    // 登录
    Weakify(self);
    [ZegoHudManager showNetworkLoading];
    BOOL reqResult = [self.zegoApi loginRoom:roomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        Strongify(self);
        [ZegoHudManager hideNetworkLoading];
        
        if (errorCode != 0) {
            ZGLogWarn(@"登录房间失败,errorCode:%d", errorCode);
            // 登录房间失败
            [ZegoHudManager showMessage:[NSString stringWithFormat:@"登录房间失败,errorCode:%d", errorCode]];
            return;
        }
        
        // 登录房间成功
        // 推流前激活媒体次要信息通道，推流之后才能发送次要信息
        [self.mediaSideInfoController activateMediaSideInfoForPublishChannel:ZEGOAPI_CHN_MAIN];
        
        // 开始推流，在 ZegoLivePublisherDelegate 的 onPublishStateUpdate:streamID:streamInfo: 中或知推流结果
        ZGLogInfo(@"登录房间成功");
        if ([self.zegoApi startPublishing:streamID title:nil flag:ZEGO_SINGLE_ANCHOR]) {
            ZGLogInfo(@"请求推流");
        }
    }];
    if (reqResult) {
        ZGLogInfo(@"请求登录房间");
    }
}

- (void)stopLive {
    [_zegoApi stopPreview];
    ZGLogInfo(@"停止预览");
    
    // 停止推流
    [_zegoApi stopPublishing];
    ZGLogInfo(@"停止推流");
    // 登出房间
    [_zegoApi logoutRoom];
    ZGLogInfo(@"退出房间");
}

- (void)showSendSideInfoMessageUI {
    [self presentViewController:self.sendSideInfoMessageAlertVC animated:YES completion:^{
        [self.sendSideInfoMessageTextField becomeFirstResponder];
    }];
}

/**
 将当前输入的文本作为媒体次要信息进行发送
 
 @return 是否请求了发送
 */
- (BOOL)sendCurrentInputTextAsMediaSideMessage {
    // 发送逻辑
    if (!_sendSideInfoMessageTextField) { return NO; }
    
    NSString *messageContent = _sendSideInfoMessageTextField.text;
    if (messageContent.length == 0) { return NO; }
    
    NSData *messageData = [messageContent dataUsingEncoding:NSUTF8StringEncoding];
    [self.mediaSideInfoController sendMediaSideInfo:messageData];
    [self appendSideInfoMessageAndMakeVisible:messageContent];
    return YES;
}

- (void)appendSideInfoMessageAndMakeVisible:(NSString *)sideInfoMessage {
    if (!sideInfoMessage || sideInfoMessage.length == 0) {
        return;
    }
    
    NSString *oldText = self.sideInfoTextView.text;
    NSString *newText = [NSString stringWithFormat:@"%@\n%@", oldText, sideInfoMessage];
    
    self.sideInfoTextView.text = newText;
    if(newText.length > 0 ) {
        UITextView *textView = self.sideInfoTextView;
        NSRange bottom = NSMakeRange(newText.length -1, 1);
        [textView scrollRangeToVisible:bottom];
        //        NSRange range = NSMakeRange(textView.text.length, 0);
        //        [textView scrollRangeToVisible:range];
        // an iOS bug, see https://stackoverflow.com/a/20989956/971070
        [textView setScrollEnabled:NO];
        [textView setScrollEnabled:YES];
    }
}

#pragma mark - ZegoRoomDelegate

- (void)onKickOut:(int)reason roomID:(NSString *)roomID {
    ZGLogWarn(@"被踢出房间, reason:%d", reason);
}

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"已断开和房间的连接, errorCode:%d", errorCode);
}

- (void)onReconnect:(int)errorCode roomID:(NSString *)roomID {
    ZGLogInfo(@"重连, errorCode:%d", errorCode);
}

#pragma mark - ZegoLivePublisherDelegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    // stateCode == 0 表示推流成功
    if (stateCode == 0) {
        ZGLogInfo(@"推流请求成功");
        self.showSideInfoInputButn.enabled = YES;
    } else {
        ZGLogInfo(@"推流请求失败，stateCode:%d",stateCode);
        self.showSideInfoInputButn.enabled = NO;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self sendCurrentInputTextAsMediaSideMessage]) {
        textField.text = nil;
        [textField resignFirstResponder];
        [_sendSideInfoMessageAlertVC dismissViewControllerAnimated:YES completion:nil];
        return NO;
    } else {
        return YES;
    }
}

@end
#endif
