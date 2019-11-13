//
//  ZGMixStreamTopicMixStreamFlags.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/23.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGMixStreamTopicMixStreamFlags : NSObject

@property (nonatomic, copy) NSString *mixStreamID;
@property (nonatomic, assign) BOOL isFirstAnchor;
@property (nonatomic, copy) NSString *hls;
@property (nonatomic, copy) NSString *rtmp;

@end

NS_ASSUME_NONNULL_END
