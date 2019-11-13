//
//  ZGMediaPlayerChooseFileVC.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/23.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_MediaPlayer

#import <UIKit/UIKit.h>
#import "ZGMediaPlayerMediaItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGMediaPlayerChooseFileVC : UITableViewController

/**
 选中某个文件后的回调处理
 */
@property (nonatomic, copy) void(^fileDidSelectedHandler)(ZGMediaPlayerMediaItem *mediaItem);

+ (instancetype)instanceFromStoryboard;

@end

NS_ASSUME_NONNULL_END
#endif
