//
//  ZGExternalVideoRenderDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/1/29.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoRender

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZGExternalVideoRenderDemoProtocol <NSObject>
- (ZEGOView *)getMainPlaybackView;
- (ZEGOView *)getSubPlaybackView;
- (void)onLiveStateUpdate;
@end

@interface ZGExternalVideoRenderDemo : NSObject

@property (assign, nonatomic) BOOL isLive;
@property (nonatomic, weak) id<ZGExternalVideoRenderDemoProtocol> delegate;

- (void)startLive;//start preview/publish/play published stream
- (void)stop;

@end

NS_ASSUME_NONNULL_END

#endif
