//
//  ZGMixStreamCreateRoomViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/17.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_MixStream

#import "ZGMixStreamCreateRoomViewController.h"
#import "ZGKeyCenter.h"
#import "ZGMixStreamTopicConstants.h"
#import "ZGMixStreamDemo.h"
#import "ZGMixStreamConfirmViewController.h"

NSString const* ZGMixStreamCreateRoomIDKey = @"kZGMixStreamCreateRoomID";

@interface ZGMixStreamCreateRoomViewController ()

@property (nonatomic, weak) IBOutlet UITextField *roomIDTxf;

@end

@implementation ZGMixStreamCreateRoomViewController

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MixStream" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGMixStreamCreateRoomViewController class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.zgUserID.length == 0) {
        ZGLogError(@"%@ is empty.", NSStringFromSelector(@selector(zgUserID)));
        return;
    }
    if (self.mixStreamDemo == nil) {
        ZGLogError(@"%@ is nil.", NSStringFromSelector(@selector(mixStreamDemo)));
        return;
    }
    
    [self setupUI];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)onTryEnterRoom:(id)sender {
    NSString *srcRoomID = self.roomIDTxf.text;
    if (srcRoomID.length == 0) {
        return;
    }
    
    // 房间好加个前缀
    NSString *roomID = [NSString stringWithFormat:@"%@%@", ZGMixStreamTopicRoomPrefix, srcRoomID];
    
    // 尝试进入房间
    Weakify(self);
    [ZegoHudManager showNetworkLoading];
    BOOL result = [self.mixStreamDemo joinLiveRoom:roomID userID:self.zgUserID isAnchor:YES callback:^(int errorCode, NSArray<ZegoStream *> *joinLiveStreams) {
        [ZegoHudManager hideNetworkLoading];
        
        Strongify(self);
        if (errorCode != 0) {
            [ZegoHudManager showMessage:[NSString stringWithFormat:@"创建房间失败。errorCode:%d", errorCode]];
            return;
        }
        
        [self saveValue:srcRoomID forKey:ZGMixStreamCreateRoomIDKey];
        [self gotoConfirmStartLivePage];
    }];
    
    if (!result) {
        [ZegoHudManager hideNetworkLoading];
        [ZegoHudManager showMessage:@"创建房间失败，请查看日志"];
    }
}

#pragma mark - private methods

- (void)setupUI {
    self.navigationItem.title = @"创建直播";
    
    NSString *srcRoomID = [self savedValueForKey:ZGMixStreamCreateRoomIDKey];
    self.roomIDTxf.text = srcRoomID;
}

- (void)gotoConfirmStartLivePage {
    ZGMixStreamConfirmViewController *confirmVC = [ZGMixStreamConfirmViewController instanceFromStoryboard];
    confirmVC.mixStreamDemo = self.mixStreamDemo;
    
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:confirmVC];
    
    [self presentViewController:nvc animated:YES completion:nil];
}

@end

#endif
