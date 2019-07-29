//
//  ZGExternalVideoCapturePreviewHelper.h
//  ZegoLiveRoomWrapper
//
//  Created by Sky on 2019/6/12.
//  Copyright © 2019 zego. All rights reserved.
//

#ifdef _Module_ExternalVideoCapture

#import "ZGExternalVideoCaptureManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGExternalVideoCapturePreviewHelper : NSObject

+ (void)showCaptureData:(CVImageBufferRef)image inView:(ZEGOView *)view viewMode:(ZegoVideoViewMode)viewMode;

+ (void)removeCaptureDataInView:(ZEGOView *)view;

@end

NS_ASSUME_NONNULL_END

#endif
