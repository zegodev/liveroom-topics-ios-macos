//
//  ZGExternalVideoFilterPlayViewController.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/7.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


/**
 本类用于在已有其他设备开始外部滤镜推流后，使用本类拉流体验外部滤镜效果
 
 @discussion 精简了拉流的业务逻辑，具体的拉流业务请查看”拉流“基础模块
 */
@interface ZGExternalVideoFilterPlayViewController : UIViewController

@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *streamID;

@end

NS_ASSUME_NONNULL_END

#endif
