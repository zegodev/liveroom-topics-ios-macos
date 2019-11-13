//
//  ZGMixStreamAnchorLiveViewController.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_MixStream

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZGMixStreamDemo;

/**
 主播直播界面 controller
 */
@interface ZGMixStreamAnchorLiveViewController : UIViewController

// 直播的推流 stream ID
@property (nonatomic, copy) NSString *liveStreamID;

// 要进行混流的 stream ID
@property (nonatomic, copy) NSString *mixStreamID;

// 直播流程 VM 实例
@property (nonatomic, strong) ZGMixStreamDemo *mixStreamDemo;

+ (instancetype)instanceFromStoryboard;

@end

NS_ASSUME_NONNULL_END

#endif
