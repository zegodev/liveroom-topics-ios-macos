//
//  ZGWebRTCContentVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGWebRTCContentVC.h"
#import <WebKit/WebKit.h>
#import "Masonry.h"

@interface ZGWebRTCContentVC ()

@property (nonatomic) WKWebView *wkWebView;
@property (nonatomic) UIWebView *uiWebView;

@end

@implementation ZGWebRTCContentVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self openURL];
}

- (WKWebView *)wkWebView {
    if (!_wkWebView) {
        WKWebViewConfiguration *conf = [[WKWebViewConfiguration alloc] init];
        conf.allowsInlineMediaPlayback = YES;
        conf.allowsAirPlayForMediaPlayback = YES;
        conf.allowsPictureInPictureMediaPlayback = YES;
        _wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 375, 640) configuration:conf];
    }
    return _wkWebView;
}

- (UIWebView *)uiWebView {
    if (!_uiWebView) {
        _uiWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 375, 640)];
        _uiWebView.allowsInlineMediaPlayback = YES;
        _uiWebView.allowsPictureInPictureMediaPlayback = YES;
    }
    return _uiWebView;
}

- (void)setupUI {
    self.navigationItem.title = @"显示URL内容";
    
    UIView *webView = nil;
    if (self.openWithWKWebView) {
        webView = self.wkWebView;
    } else {
        webView = self.uiWebView;
    }
    [self.view addSubview:webView];
    [webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.mas_equalTo(0);
        make.top.equalTo(self.mas_topLayoutGuide);
        make.bottom.equalTo(self.mas_bottomLayoutGuide);
    }];
}

- (void)openURL {
    NSURL *URL = self.URL;
    if (!URL) return;
    
    if (self.openWithWKWebView) {
        [_wkWebView loadRequest:[NSURLRequest requestWithURL:URL]];
    } else {
        [_uiWebView loadRequest:[NSURLRequest requestWithURL:URL]];
    }
}

@end
