//
//  ZGLoginRoomViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/17.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGLoginRoomViewController.h"
#import "ZGLoginRoomDemo.h"
#import "ZGStartPublishViewController.h"

@interface ZGLoginRoomViewController ()

@property (weak, nonatomic) IBOutlet UITextField *roomIDTxf;

@end

static NSString *ZGLoginRoomIDKey = @"ZGLoginRoomIDKey";

@implementation ZGLoginRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}

- (void)setupUI {
    NSString *roomID = [self savedValueForKey:ZGLoginRoomIDKey];
    self.roomIDTxf.text = roomID;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)onLoginRoom:(id)sender {
    NSString *roomID = self.roomIDTxf.text;

    [ZegoHudManager showNetworkLoading];
    
    Weakify(self);
    BOOL result = [ZGLoginRoomDemo.shared loginRoom:roomID role:ZEGO_ANCHOR completion:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        [ZegoHudManager hideNetworkLoading];
        
        Strongify(self);
        
        BOOL success = errorCode == 0;
        if (!success) {
            [ZegoHudManager showMessage:@"登录房间失败"];
            return;
        }
        
        [self saveValue:roomID forKey:ZGLoginRoomIDKey];
        [self jumpToStartPublish];
    }];
    
    if (!result) {
        [ZegoHudManager hideNetworkLoading];
        [ZegoHudManager showMessage:@"参数不合法或已经登录房间"];
    }
}

- (IBAction)getSourceCode:(id)sender {
    [UIApplication jumpToWeb:ZGLoginDocURL];
}

- (void)jumpToStartPublish {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Publish" bundle:nil];
    ZGStartPublishViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ZGStartPublishViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}


@end
