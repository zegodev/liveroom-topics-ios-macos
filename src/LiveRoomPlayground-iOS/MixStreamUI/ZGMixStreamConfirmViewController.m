//
//  ZGMixStreamConfirmViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/17.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_MixStream

#import "ZGMixStreamConfirmViewController.h"
#import "ZGMixStreamDemo.h"
#import "ZGMixStreamAnchorLiveViewController.h"
#import "ZGMixStreamConfigViewController.h"

NSString* const ZGMixStreamConfirmStreamIDKey = @"kZGMixStreamConfirmStreamID";
NSString* const ZGMixStreamConfirmMixStreamIDKey = @"kZGMixStreamConfirmMixStreamID";

@interface ZGMixStreamConfirmViewController ()

@property (nonatomic, weak) IBOutlet UITextField *streamIDTxf;
@property (nonatomic, weak) IBOutlet UITextField *mixStreamIDTxf;

@end

@implementation ZGMixStreamConfirmViewController

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MixStream" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGMixStreamConfirmViewController class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.mixStreamDemo == nil) {
        ZGLogError(@"%@ is nil.", NSStringFromSelector(@selector(mixStreamDemo)));
        return;
    }
    
    [self setupUI];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)confirmLiveButnClick:(id)sender {
    // TODO:
    NSString *streamID = self.streamIDTxf.text;
    NSString *mixStreamID = self.mixStreamIDTxf.text;
    if (streamID.length == 0) {
        NSLog(@"请填写 streamID");
        return;
    }
    if (mixStreamID.length == 0) {
        NSLog(@"请填写 mixStreamID");
        return;
    }
    
    [self enterLivePageWithStreamID:streamID mixStreamID:mixStreamID];
}

#pragma mark - private methods

- (void)setupUI {
    self.navigationItem.title = @"发起推流";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"退出" style:UIBarButtonItemStylePlain target:self action:@selector(closePage:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"混流配置" style:UIBarButtonItemStylePlain target:self action:@selector(gotoMixStreamSettingPage:)];
    
    NSString *cachedStreamID = [self savedValueForKey:ZGMixStreamConfirmStreamIDKey];
    NSString *cachedMixStreamID = [self savedValueForKey:ZGMixStreamConfirmMixStreamIDKey];
    self.streamIDTxf.text = cachedStreamID;
    self.mixStreamIDTxf.text = cachedMixStreamID;
}

- (void)closePage:(id)sender {
    [self.mixStreamDemo leaveLiveRoom];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)gotoMixStreamSettingPage:(id)sender {
    
    ZGMixStreamConfigViewController *confVC = [ZGMixStreamConfigViewController instanceFromStoryboard];
    [self.navigationController pushViewController:confVC animated:YES];
}

- (void)enterLivePageWithStreamID:(NSString *)streamID mixStreamID:(NSString *)mixStreamID {
    
    [self saveValue:streamID forKey:ZGMixStreamConfirmStreamIDKey];
    [self saveValue:mixStreamID forKey:ZGMixStreamConfirmMixStreamIDKey];
    
    ZGMixStreamAnchorLiveViewController *liveVC = [ZGMixStreamAnchorLiveViewController instanceFromStoryboard];
    liveVC.liveStreamID = streamID;
    liveVC.mixStreamID = mixStreamID;
    liveVC.mixStreamDemo = self.mixStreamDemo;
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:liveVC];
    
    // 关闭当前页面，弹出直播页面
    [self dismissViewControllerAnimated:NO completion:^{
        UIViewController *rootVC = [[UIApplication sharedApplication].keyWindow rootViewController];
        [rootVC presentViewController:nvc animated:YES completion:nil];
    }];
}

@end

#endif
