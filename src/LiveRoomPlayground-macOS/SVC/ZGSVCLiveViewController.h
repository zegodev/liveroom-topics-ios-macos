//
//  ZGSVCLiveViewController.h
//  LiveRoomPlayground-macOS
//
//  Created by Sky on 2018/11/13.
//  Copyright © 2018 Zego. All rights reserved.
//

#ifdef _Module_ScalableVideoCoding

#import <Cocoa/Cocoa.h>
#import "ZGApiManager.h"

@class ZGRoomInfo;

NS_ASSUME_NONNULL_BEGIN

@interface ZGSVCLiveViewController : NSViewController

@property (strong, nonatomic) ZGRoomInfo *roomInfo;
@property (assign ,nonatomic) ZegoRole role;

@end

NS_ASSUME_NONNULL_END

#endif
