//
//  ZGMediaPlayerMediaItem.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/23.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGMediaPlayerMediaItem.h"

@implementation ZGMediaPlayerMediaItem

+ (instancetype)itemWithFileUrl:(NSString*)fileUrl mediaName:(NSString*)mediaName isVideo:(BOOL)isVideo {
    ZGMediaPlayerMediaItem *item = [[ZGMediaPlayerMediaItem alloc] init];
    item.fileUrl = fileUrl;
    item.mediaName = mediaName;
    item.isVideo = isVideo;
    return item;
}

@end
