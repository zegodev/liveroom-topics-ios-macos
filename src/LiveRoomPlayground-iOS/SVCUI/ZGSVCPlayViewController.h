//
//  ZGSVCPlayViewController.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/13.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ScalableVideoCoding

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGSVCPlayViewController : UIViewController

@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *streamID;

@end

NS_ASSUME_NONNULL_END

#endif
