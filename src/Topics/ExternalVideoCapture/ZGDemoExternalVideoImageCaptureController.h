//
//  ZGDemoExternalVideoImageCaptureController.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/15.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZGDemoExternalVideoCaptureControllerProtocol.h"

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ZGDemoExternalVideoImageCaptureController : NSObject <ZGDemoExternalVideoCaptureControllerProtocol>

@property (nonatomic, weak) id<ZGDemoExternalVideoCaptureControllerDelegate> delegate;

#if TARGET_OS_OSX
- (instancetype)initWithMotionImage:(NSImage *)motionImage;
#endif

#if TARGET_OS_IOS
- (instancetype)initWithMotionImage:(UIImage *)motionImage;
#endif

@end

NS_ASSUME_NONNULL_END
