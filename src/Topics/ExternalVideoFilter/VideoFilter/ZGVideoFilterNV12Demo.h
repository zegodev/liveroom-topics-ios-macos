//
//  ZGVideoFilterNV12Demo.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/9/2.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/**
 异步 NV12 类型外部滤镜实现
 */
@interface ZGVideoFilterNV12Demo : NSObject<ZegoVideoFilter, ZegoVideoBufferPool>

@end

NS_ASSUME_NONNULL_END

#endif
