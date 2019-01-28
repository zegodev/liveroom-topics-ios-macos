//
//  ZGExternalVideoCapturePreviewHelper.h
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/1/23.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGExternalVideoCaptureManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGExternalVideoCapturePreviewHelper : NSObject

+ (void)showCaptureData:(CVImageBufferRef)image inView:(ZGView *)view viewMode:(ZegoVideoViewMode)viewMode;
+ (void)removeCaptureDataInView:(ZGView *)view;

@end

NS_ASSUME_NONNULL_END
