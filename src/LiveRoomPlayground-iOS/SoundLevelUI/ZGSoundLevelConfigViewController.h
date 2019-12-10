//
//  ZGSoundLevelConfigViewController.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/9/4.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_SoundLevel

#import <UIKit/UIKit.h>
#import "ZGSoundLevelManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGSoundLevelConfigViewController : UITableViewController

@property (nonatomic, strong) ZGSoundLevelManager *manager;

@end

NS_ASSUME_NONNULL_END

#endif
