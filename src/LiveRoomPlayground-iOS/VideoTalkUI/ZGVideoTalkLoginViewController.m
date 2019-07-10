//
//  ZGVideoTalkLoginViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/2.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGVideoTalkLoginViewController.h"
#import "ZGVideoTalkDemo.h"
#import "ZGVideoTalkViewController.h"
#import "ZGKeyCenter.h"

static NSString *ZGLoginRoomIDKey = @"ZGLoginRoomIDKey";

@interface ZGVideoTalkLoginViewController ()

@property (nonatomic, weak) IBOutlet UITextField *roomIDTxf;

@property (nonatomic, strong) ZGVideoTalkDemo *videoTalkDemo;

@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *userName;

@end

@implementation ZGVideoTalkLoginViewController

- (void)dealloc {
#if DEBUG
    NSLog(@"%@ dealloc.", [self class]);
#endif
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    // 获取到 userID 和 userName
    self.userID = [NSString stringWithFormat:@"u_%ld", (long)[NSDate date].timeIntervalSince1970];
    self.userName = self.userID;
    
    // step1: 设置 ZegoLiveRoomApi 上下文
    [self setupZegoLiveRoomApiDefault];
    
    // step2: 初始化 ZGVideoTalkDemo
    [ZegoHudManager showNetworkLoading];
    Weakify(self);
    self.videoTalkDemo = [[ZGVideoTalkDemo alloc] initWithAppID:ZGKeyCenter.appID appSign:ZGKeyCenter.appSign completionBlock:^(ZGVideoTalkDemo *demo, int errorCode) {
        [ZegoHudManager hideNetworkLoading];
        // 初始化结果回调，errorCode == 0 表示成功
        NSLog(@"初始化结果, errorCode: %d", errorCode);
        Strongify(self);
        
        if (errorCode == 0) {
            // 成功后，调用其他方法才有效
            [demo setEnableMic:YES];
            [demo setEnableCamera:YES];
            return;
        }
        
        [ZegoHudManager showMessage:[NSString stringWithFormat:@"初始化失败, errorCode:%d", errorCode]];
    }];
    
    
    // step3: 使用 ZGVideoTalkDemo 提供的接口，如登录房间
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)onTryEnterRoom:(id)sender {
    // 尝试进入房间
    NSString *roomID = self.roomIDTxf.text;
    NSString *streamID = [NSString stringWithFormat:@"VideoTalkDemo_s_%@", self.userID];
    
    [ZegoHudManager showNetworkLoading];
    Weakify(self);
    BOOL result = [self.videoTalkDemo joinTalkRoom:roomID userID:self.userID streamID:streamID callback:^(int errorCode) {
        [ZegoHudManager hideNetworkLoading];
        
        Strongify(self);
        BOOL success = errorCode == 0;
        if (!success) {
            [ZegoHudManager showMessage:@"登录房间失败"];
            return;
        }
        
        [self saveValue:roomID forKey:ZGLoginRoomIDKey];
        [self joinVideoTalk];
    }];
    
    if (!result) {
        [ZegoHudManager hideNetworkLoading];
        [ZegoHudManager showMessage:@"参数不合法或已经登录房间"];
    }
}

#pragma mark - private methods

- (void)setupUI {
    NSString *roomID = [self savedValueForKey:ZGLoginRoomIDKey];
    self.roomIDTxf.text = roomID;
}


/**
 设置该模块的 ZegoLiveRoomApi 默认上下文
 */
- (void)setupZegoLiveRoomApiDefault {
    [ZegoLiveRoomApi setUseTestEnv:YES];
    [ZegoLiveRoomApi enableExternalRender:NO];
    [ZegoLiveRoomApi setVideoFilterFactory:nil];
    [ZegoLiveRoomApi setVideoCaptureFactory:nil];
}


- (void)joinVideoTalk {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"VideoTalk" bundle:nil];
    
    ZGVideoTalkViewController *vc = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGVideoTalkViewController class])];
    vc.videoTalkDemo = self.videoTalkDemo;
    
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:nvc animated:YES completion:nil];
}

@end
