//
//  ZGWebRTCContentVC.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGWebRTCContentVC : UIViewController

@property (nonatomic, copy) NSURL *URL;

// 是否使用 WKWebView 打开，否则用 UIWebView
@property (nonatomic, assign) BOOL openWithWKWebView;

@end

NS_ASSUME_NONNULL_END
