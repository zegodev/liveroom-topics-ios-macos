//
//  ZGExternalVideoCapturePublishStreamVC.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/15.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_ExternalVideoCapture

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGExternalVideoCapturePublishStreamVC : UIViewController

@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *streamID;

// 采集源类型。1: 摄像头，2:图像，3:录屏
@property (nonatomic, assign) NSInteger captureSource;

// 采集数据格式。1: YUV，2:BRGA
@property (nonatomic, assign) NSInteger captureDataFormat;

+ (instancetype)instanceFromStoryboard;

@end

NS_ASSUME_NONNULL_END
#endif
