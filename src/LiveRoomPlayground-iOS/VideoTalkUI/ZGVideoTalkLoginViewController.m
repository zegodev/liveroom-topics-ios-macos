//
//  ZGVideoTalkLoginViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/2.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_VideoTalk

#import "ZGVideoTalkLoginViewController.h"
#import "ZGVideoTalkDemo.h"
#import "ZGVideoTalkViewController.h"
#import "ZGKeyCenter.h"

static NSString *ZGLoginRoomIDKey = @"ZGLoginRoomIDKey";

@interface ZGVideoTalkLoginViewController ()

@property (nonatomic, weak) IBOutlet UITextField *roomIDTxf;

@property (nonatomic, strong) ZGVideoTalkDemo *videoTalkDemo;

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
    NSString *roomID = self.roomIDTxf.text;
    [self saveValue:roomID forKey:ZGLoginRoomIDKey];
    [self gotoVideoTalkRoomWithID:roomID];
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


- (void)gotoVideoTalkRoomWithID:(NSString *)roomID {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"VideoTalk" bundle:nil];
    
    ZGVideoTalkViewController *vc = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGVideoTalkViewController class])];
    vc.roomID = roomID;
    vc.videoTalkDemo = self.videoTalkDemo;
    
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:nvc animated:YES completion:nil];
}

@end

#endif
