//
//  ZGAuxPlayViewController.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_AudioAux

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGAuxPlayViewController : UIViewController

@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *streamID;


@end

NS_ASSUME_NONNULL_END

#endif
