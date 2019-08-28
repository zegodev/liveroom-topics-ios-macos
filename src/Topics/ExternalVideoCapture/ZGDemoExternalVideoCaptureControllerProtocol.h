//
//  ZGDemoExternalVideoCaptureSourceProtocol.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/15.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZGDemoExternalVideoCaptureControllerDelegate;

@protocol ZGDemoExternalVideoCaptureControllerProtocol <NSObject>

@property (nonatomic, weak) id<ZGDemoExternalVideoCaptureControllerDelegate> delegate;

/**
 开启拍摄
 */
- (BOOL)start;

/**
 停止拍摄
 */
- (void)stop;

@end

@protocol ZGDemoExternalVideoCaptureControllerDelegate <NSObject>
@optional
- (void)externalVideoCaptureController:(id<ZGDemoExternalVideoCaptureControllerProtocol>)controller didCapturedData:(CVImageBufferRef)imageData presentationTimeStamp:(CMTime)presentationTimeStamp;

@end


NS_ASSUME_NONNULL_END
