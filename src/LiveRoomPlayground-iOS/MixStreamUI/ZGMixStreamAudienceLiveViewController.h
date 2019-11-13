//
//  ZGMixStreamAudienceLiveViewController.h
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
 观众直播界面 controller
 */
@interface ZGMixStreamAudienceLiveViewController : UIViewController

// 房间的主播（创建着） ID
@property (nonatomic, copy) NSString *roomAnchorID;

@property (nonatomic, strong) ZGMixStreamDemo *mixStreamDemo;

+ (instancetype)instanceFromStoryboard;

@end

NS_ASSUME_NONNULL_END

#endif
