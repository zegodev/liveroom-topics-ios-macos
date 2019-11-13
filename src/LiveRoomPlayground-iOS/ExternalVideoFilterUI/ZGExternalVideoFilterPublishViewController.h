//
//  ZGExternalVideoFilterPublishViewController.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


/**
 外部滤镜推流的 UI，集成了 FaceUnity 的美颜道具控制器
 */
@interface ZGExternalVideoFilterPublishViewController : UIViewController

@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *streamID;

@property (nonatomic, assign) NSInteger selectedFilterBufferType;

@end

NS_ASSUME_NONNULL_END

#endif
