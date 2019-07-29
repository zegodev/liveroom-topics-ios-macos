//
//  JoinLiveCreateRoomViewController.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/11.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_JoinLive

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZGJoinLiveDemo;

@interface ZGJoinLiveCreateRoomViewController : UIViewController

@property (nonatomic, copy) NSString *zgUserID;
@property (nonatomic, strong) ZGJoinLiveDemo *joinLiveDemo;

@end

NS_ASSUME_NONNULL_END

#endif
