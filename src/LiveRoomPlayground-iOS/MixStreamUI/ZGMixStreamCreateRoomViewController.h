//
//  ZGMixStreamCreateRoomViewController.h
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
 创建房间界面 controller
 */
@interface ZGMixStreamCreateRoomViewController : UIViewController

@property (nonatomic, copy) NSString *zgUserID;
@property (nonatomic, strong) ZGMixStreamDemo *mixStreamDemo;

+ (instancetype)instanceFromStoryboard;

@end

NS_ASSUME_NONNULL_END

#endif
