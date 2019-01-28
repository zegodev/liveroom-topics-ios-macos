//
//  ZGTopicsTableViewController.h
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZGTopicsTableViewControllerDelegate <NSObject>

- (void)onTopicSelected:(NSString*)topic;

@end

@interface ZGTopicsTableViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>

- (void)setTopicList:(NSArray<NSString*>*)topics;

@property (weak) id<ZGTopicsTableViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
