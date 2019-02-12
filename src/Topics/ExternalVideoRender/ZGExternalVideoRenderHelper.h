//
//  ZGExternalVideoRenderHelper.h
//  LiveRoomPlayground
//
//  Created by Sky on 2019/1/29.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZGExternalVideoRenderDemo.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGExternalVideoRenderHelper : NSObject

+ (void)showRenderData:(CVImageBufferRef)image inView:(ZGView *)view viewMode:(ZegoVideoViewMode)viewMode;
+ (void)removeRenderDataInView:(ZGView *)view;

@end

NS_ASSUME_NONNULL_END
