//
//  ZGDemoExternalVideoCameraCaptureController.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/15.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZGDemoExternalVideoCaptureControllerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 摄像头外部采集视频 controller
 */
@interface ZGDemoExternalVideoCameraCaptureController : NSObject <ZGDemoExternalVideoCaptureControllerProtocol>

@property (nonatomic, weak) id<ZGDemoExternalVideoCaptureControllerDelegate> delegate;

- (instancetype)initWithPixelFormatType:(OSType)pixelFormatType;

- (void)changeCaptureOrientation:(BOOL)change;

@end

NS_ASSUME_NONNULL_END
