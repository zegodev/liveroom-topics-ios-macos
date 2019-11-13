//
//  ZegoLogView.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/14.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoLogView.h"
#import "ZegoLog.h"
#import "ZegoRAMStoreLogger.h"
#import "ZegoTTYLogFormatter.h"
#import "ZGShareLogViewController.h"
#import "UIViewController+TopPresent.h"

@interface ZegoLogView () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) ZegoRAMStoreLogger *logger;
@property (strong, nonatomic) ZegoTTYLogFormatter *formatter;

@property (strong, nonatomic) UIView *naviBar;
@property (strong, nonatomic) UIButton *clearBtn;
@property (strong, nonatomic) UIButton *shareBtn;
@property (strong, nonatomic) UIButton *closeBtn;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIDocumentInteractionController *documentController;

@property (copy, nonatomic) NSString *dstLogFilePath;

@property (assign, nonatomic) BOOL isDragingList;//当查看日志时就不滚动到底部

@end

static ZegoLogView *view = nil;

@implementation ZegoLogView

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.dstLogFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.dstLogFilePath error:nil];
    }
}

+ (void)show {
    if (!view) {
        view = [[ZegoLogView alloc] init];
        view.frame = UIScreen.mainScreen.bounds;
        view.alpha = 0;
        view.userInteractionEnabled = NO;
        [UIApplication.sharedApplication.keyWindow addSubview:view];
        [UIView animateWithDuration:0.5 animations:^{
            view.alpha = 1;
        } completion:^(BOOL finished) {
            view.userInteractionEnabled = YES;
        }];
    }
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.logger = ZegoLog.allLoggers[1];
    self.formatter = [ZegoTTYLogFormatter new];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onLogMessagesUpdate) name:ZegoRAMStoreLoggerLogDidChangeNotification object:nil];
    
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    
    //UI
    self.naviBar = [[UIView alloc] init];
    self.naviBar.backgroundColor = [UIColor clearColor];
    
    self.clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.clearBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.clearBtn setTitle:@"清空" forState:UIControlStateNormal];
    [self.clearBtn addTarget:self action:@selector(onClear) forControlEvents:UIControlEventTouchUpInside];
    
    self.shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.shareBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.shareBtn setTitle:@"分享" forState:UIControlStateNormal];
    [self.shareBtn addTarget:self action:@selector(onShare) forControlEvents:UIControlEventTouchUpInside];
    
    self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.closeBtn setTitle:@"退出" forState:UIControlStateNormal];
    [self.closeBtn addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    [self addSubview:self.naviBar];
    [self.naviBar addSubview:self.clearBtn];
    [self.naviBar addSubview:self.shareBtn];
    [self.naviBar addSubview:self.closeBtn];
    [self addSubview:self.tableView];
    
    //layout
    CGRect scr = UIScreen.mainScreen.bounds;
    CGFloat statusH = UIApplication.sharedApplication.statusBarFrame.size.height;
    CGFloat naviH = 44 + statusH;
    CGFloat btnW = 80;
    CGFloat btnH = naviH - statusH;
    self.naviBar.frame = CGRectMake(0, 0, scr.size.width, naviH);
    self.clearBtn.frame = CGRectMake(0, statusH, btnW, btnH);
    self.shareBtn.frame = CGRectMake(btnW, statusH, btnW, btnH);
    self.closeBtn.frame = CGRectMake(scr.size.width-btnW, statusH, btnW, btnH);
    self.tableView.frame = CGRectMake(0, self.naviBar.frame.size.height, scr.size.width, scr.size.height-self.naviBar.frame.size.height);
    
    [self.tableView reloadData];
}

- (void)onClear {
    [self.logger flush];
}

- (void)onShare {
    [self hide];
    
    ZGShareLogViewController *vc = [[ZGShareLogViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    
    UIViewController *rootVC = UIApplication.sharedApplication.keyWindow.rootViewController;
    [rootVC.topPresentedViewController presentViewController:vc animated:YES completion:nil];
}

- (void)hide {
    self.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        view = nil;
    }];
}

#pragma mark - ZegoRoomHelperLogDelegate

- (void)onLogMessagesUpdate {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        
        if (self.isDragingList) {
            return;
        }
        
        if (self.logger.logs.count > 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.logger.logs.count-1 inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.logger.logs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"UITableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    ZegoLogMessage *msg = self.logger.logs[indexPath.row];
    NSString *logString = [self.formatter formatLogMessage:msg];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text = logString;
    cell.textLabel.font = [UIFont systemFontOfSize:13];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return (action == @selector(copy:));
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        if (indexPath.row >= self.logger.logs.count) {
            return;
        }
        
        ZegoLogMessage *msg = self.logger.logs[indexPath.row];
        NSString *logString = [self.formatter formatLogMessage:msg];
        if (logString) {
            [[UIPasteboard generalPasteboard] setString:logString];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isDragingList = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        self.isDragingList = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.isDragingList = NO;
}

@end
