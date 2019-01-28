//
//  ZGExternalVideoCaptureManager.h
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/1/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-external-video-capture-oc.h>
#import <ZegoLiveRoomOSX/ZegoVideoCapture.h>
#define ZGView NSView
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-external-video-capture-oc.h>
#import <ZegoLiveRoom/ZegoVideoCapture.h>
#define ZGView UIView
#endif

typedef NS_ENUM(NSInteger, ZGExternalVideoCaptureSourceType) {
    kZGExternalVideoCaptureSourceTypeImage = 1,
    kZGExternalVideoCaptureSourceTypeCamera = 2,
    kZGExternalVideoCaptureSourceTypeScreen = 3,
};

NS_ASSUME_NONNULL_BEGIN

@interface ZGExternalVideoCaptureManager : NSObject <ZegoVideoCaptureFactory>

@property (assign, nonatomic, readonly) ZGExternalVideoCaptureSourceType sourceType;

- (void)setSourceType:(ZGExternalVideoCaptureSourceType)sourceType;
- (void)startCapture;
- (void)stopCapture;

/**
 由于目前SDK启用外部视频采集时不会自动渲染到preivewView上，所以暂时在此代为处理
 */
- (void)setPreviewView:(nullable ZGView *)view viewMode:(ZegoVideoViewMode)viewMode;

@end

NS_ASSUME_NONNULL_END
