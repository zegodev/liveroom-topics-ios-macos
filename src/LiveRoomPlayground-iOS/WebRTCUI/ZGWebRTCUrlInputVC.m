//
//  ZGWebRTCUrlInputVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/16.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGWebRTCUrlInputVC.h"
#import "ZGWebRTCContentVC.h"

@interface ZGWebRTCUrlInputVC ()

@property (weak, nonatomic) IBOutlet UITextView *inputUrlTextView;
@property (weak, nonatomic) IBOutlet UIButton *UIWebViewOpenButn;
@property (weak, nonatomic) IBOutlet UIButton *WKWebViewOpenButn;

@end

@implementation ZGWebRTCUrlInputVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"WebRTC" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGWebRTCUrlInputVC class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)openURLByUIWebView:(id)sender {
    NSURL *URL = [self inputURL];
    if (!URL) return;
    
    ZGWebRTCContentVC *vc = [[ZGWebRTCContentVC alloc] init];
    vc.URL = URL;
    vc.openWithWKWebView = NO;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)openURLByWKWebView:(id)sender {
    NSURL *URL = [self inputURL];
    if (!URL) return;
    
    ZGWebRTCContentVC *vc = [[ZGWebRTCContentVC alloc] init];
    vc.URL = URL;
    vc.openWithWKWebView = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - private methods

- (void)setupUI {
    self.inputUrlTextView.layer.borderColor = [UIColor colorWithWhite:0.6 alpha:1].CGColor;
    self.inputUrlTextView.layer.borderWidth = 0.5f;
}

- (NSURL *)inputURL {
    NSString *url = self.inputUrlTextView.text;
    NSURL *URL = [NSURL URLWithString:url];
    return URL;
}

@end
