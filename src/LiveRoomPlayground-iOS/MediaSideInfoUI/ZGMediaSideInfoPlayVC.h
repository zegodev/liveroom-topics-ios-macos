//
//  ZGMediaSideInfoPlayVC.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/21.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_MediaSideInfo

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGMediaSideInfoPlayVC : UIViewController

@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *streamID;

+ (instancetype)instanceFromStoryboard;

@end

NS_ASSUME_NONNULL_END
#endif
