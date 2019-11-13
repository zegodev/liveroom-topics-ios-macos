//
//  ZGVideoTalkViewController.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/2.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_VideoTalk

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZGVideoTalkDemo;

@interface ZGVideoTalkViewController : UIViewController

@property (nonatomic, copy) NSString *roomID;

@property (nonatomic, strong) ZGVideoTalkDemo *videoTalkDemo;

@end

NS_ASSUME_NONNULL_END

#endif
