//
//  ZGExternalVideoCaptureDemo.h
//  LiveRoomPlayground
//
//  Created by Sky on 2019/1/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoCapture

#import "ZGApiManager.h"
#import "ZGExternalVideoCaptureManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZGExternalVideoCaptureDemoProtocol <NSObject>

- (ZGView *)getMainPlaybackView;
- (ZGView *)getSubPlaybackView;
- (void)onLiveStateUpdate;

@end

@interface ZGExternalVideoCaptureDemo : NSObject

@property (assign, nonatomic) BOOL isLive;
@property (nonatomic, weak) id<ZGExternalVideoCaptureDemoProtocol> delegate;

- (void)startLive;//start preview/publish/play published stream
- (void)stop;

- (void)setCaptureSourceType:(ZGExternalVideoCaptureSourceType)sourceType;

@end

NS_ASSUME_NONNULL_END

#endif
