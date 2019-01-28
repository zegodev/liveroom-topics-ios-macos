//
//  ZGExternalVideoCaptureScreenSource.h
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/1/24.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGExternalVideoCaptureBaseSource.h"

NS_ASSUME_NONNULL_BEGIN

/**
 iOS需要在控制面板长按录制然后选择本App，就可以使用App进行录屏的推流(iOS11及以上支持)
 */
@interface ZGExternalVideoCaptureScreenSource : ZGExternalVideoCaptureBaseSource

@end

NS_ASSUME_NONNULL_END
