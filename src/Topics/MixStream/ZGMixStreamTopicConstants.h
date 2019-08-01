//
//  ZGMixStreamTopicConstants.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 混流专题的房间前缀，用于过滤其他专题的房间
extern NSString *const ZGMixStreamTopicRoomPrefix;

// 混流专题模块是否使用测试环境
extern BOOL const ZGMixStreamTopicIsUseTestEnv;

// 直播视图每行显示播放视图数目
extern NSInteger const ZGMixStreamTopicLiveViewDisplayColumnPerRow;

// 直播视图间距
extern CGFloat const ZGMixStreamTopicLiveViewSpacing;

// 流的额外信息 key
extern NSString const* ZGMixStreamTopicStreamExtraInfoKey_FirstAnchor;
extern NSString const* ZGMixStreamTopicStreamExtraInfoKey_MixStreamID;
extern NSString const* ZGMixStreamTopicStreamExtraInfoKey_Hls;
extern NSString const* ZGMixStreamTopicStreamExtraInfoKey_Rtmp;

NS_ASSUME_NONNULL_END
