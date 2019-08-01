//
//  ZGMixStreamConfirmViewController.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/17.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_MixStream

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZGMixStreamDemo;

/**
 确认开始混流直播的界面 controller
 */
@interface ZGMixStreamConfirmViewController : UIViewController

@property (nonatomic, strong) ZGMixStreamDemo *mixStreamDemo;

+ (instancetype)instanceFromStoryboard;

@end

NS_ASSUME_NONNULL_END

#endif
