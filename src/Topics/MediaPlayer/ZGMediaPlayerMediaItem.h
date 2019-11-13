//
//  ZGMediaPlayerMediaItem.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/23.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGMediaPlayerMediaItem : NSObject

@property (nonatomic, copy) NSString *fileUrl;
@property (nonatomic, copy) NSString *mediaName;
@property (nonatomic, assign) BOOL isVideo;

+ (instancetype)itemWithFileUrl:(NSString*)fileUrl mediaName:(NSString*)mediaName isVideo:(BOOL)isVideo;

@end

NS_ASSUME_NONNULL_END
