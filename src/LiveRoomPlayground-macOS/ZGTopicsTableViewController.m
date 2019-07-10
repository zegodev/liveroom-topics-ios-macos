//
//  ZGTopicsTableViewController.m
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGTopicsTableViewController.h"

@implementation ZGTopicsTableViewController {
    NSArray<NSString*>* _topicList;
}

- (void)viewDidLoad {
    NSLog(@"%s", __func__);
}

- (void)setTopicList:(NSArray<NSString*>*)topics {
    _topicList = topics;
    [[self tableView] reloadData];
}


#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionIsChanging:(NSNotification *)notification {
    NSLog(@"%s", __func__);
    
    if ([self.delegate respondsToSelector:@selector(onTopicSelected:)]) {
        NSInteger row = [self tableView].selectedRow;
        if (row != -1) {
            [self.delegate onTopicSelected:_topicList[row]];
        }
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSLog(@"%s", __func__);
    NSTableCellView* cell = [tableView makeViewWithIdentifier:@"TopicCellView" owner:nil];
    [cell.textField setStringValue:_topicList[row]];
    return cell;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSLog(@"%s", __func__);
    return _topicList.count;
}

#pragma mark - Private

- (NSTableView*)tableView {
    return (NSTableView*)self.view;
}


@end
