//
//  ZGDemoExternalVideoSreenCaptureController.h
//  LiveRoomPlayground-macOS
//
//  Created by jeffreypeng on 2019/8/16.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZGDemoExternalVideoCaptureControllerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 屏幕录制外部视频采集控制器，只在 Mac osx 可用。
 */
@interface ZGDemoExternalVideoSreenCaptureController : NSObject  <ZGDemoExternalVideoCaptureControllerProtocol>

@property (nonatomic, weak) id<ZGDemoExternalVideoCaptureControllerDelegate> delegate;

- (instancetype)initWithPixelFormatType:(OSType)pixelFormatType;

@end

NS_ASSUME_NONNULL_END
