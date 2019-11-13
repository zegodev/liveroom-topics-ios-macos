//
//  JoinLiveCreateRoomViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/11.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_JoinLive

#import "ZGJoinLiveCreateRoomViewController.h"
#import "ZGKeyCenter.h"
#import "ZGJoinLiveDemo.h"
#import "ZGJoinLiveTopicConstants.h"
#import "ZGJoinLiveViewController.h"


static NSString *ZGLoginRoomIDKey = @"ZGLoginRoomIDKey";

@interface ZGJoinLiveCreateRoomViewController ()

@property (nonatomic, weak) IBOutlet UITextField *roomIDTxf;

@end

@implementation ZGJoinLiveCreateRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.zgUserID.length == 0) {
        ZGLogError(@"%@ is empty.", NSStringFromSelector(@selector(zgUserID)));
        return;
    }
    if (self.joinLiveDemo == nil) {
        ZGLogError(@"%@ is nil.", NSStringFromSelector(@selector(joinLiveDemo)));
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
    NSString *roomID = [NSString stringWithFormat:@"%@%@", ZGJoinLiveTopicRoomPrefix, srcRoomID];
    
    [self saveValue:srcRoomID forKey:ZGLoginRoomIDKey];
    [self gotoLivePageWithRoomID:roomID];
}

#pragma mark - private methods

- (void)setupUI {
    self.navigationItem.title = @"创建直播";
    
    NSString *srcRoomID = [self savedValueForKey:ZGLoginRoomIDKey];
    self.roomIDTxf.text = srcRoomID;
}

- (void)gotoLivePageWithRoomID:(NSString *)roomID {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"JoinLive" bundle:nil];
    ZGJoinLiveViewController *liveVC = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGJoinLiveViewController class])];
    liveVC.roomAnchorID = self.zgUserID;
    liveVC.roomID = roomID;
    liveVC.currentUserID = self.zgUserID;
    liveVC.joinLiveDemo = self.joinLiveDemo;
    
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:liveVC];
    nvc.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:nvc animated:YES completion:nil];
}

@end

#endif
