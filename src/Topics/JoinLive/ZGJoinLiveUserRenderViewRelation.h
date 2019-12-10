//
//  ZGJoinLiveUserRenderViewRelation.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/12/1.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZGJoinLiveUserRenderViewRelation : NSObject

@property (nonatomic, assign) BOOL isLocalUser;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, weak) UIView *renderView;
@property (nonatomic, assign) BOOL mainShow;    // 是否显示在主要（大）视图

@end
