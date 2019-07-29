//
//  ZGShareLogViewController.m
//  LiveRoomPlayGround
//
//  Created by Sky on 2019/4/16.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGShareLogViewController.h"
#import <SSZipArchive/SSZipArchive.h>
#import "ZegoHudManager.h"

@interface ZGShareLogViewController () <UIDocumentInteractionControllerDelegate>

@property (copy, nonatomic) NSString *dstLogFilePath;
@property (strong, nonatomic) NSArray *srcLogs;
@property (strong, nonatomic) UIDocumentInteractionController *documentController;

@end

@implementation ZGShareLogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    [self setupZipFiles];
    [self zipAndShare];
}

- (void)setupZipFiles {
    // 处理各种 path
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *zegologs = [cachesPath stringByAppendingString:@"/ZegoLogs"];
    
    // 日志压缩文件路径
    NSString *dstLogFilePath = [zegologs stringByAppendingPathComponent:@"/zegoavlog.zip"];
    self.dstLogFilePath = dstLogFilePath;
    
    // 获取 Library/Caches/ZegoLogs 目录下的所有文件
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *files = [manager subpathsAtPath:zegologs];
    
    NSMutableDictionary *logFiles = [NSMutableDictionary dictionaryWithCapacity:1];
    NSMutableArray *srcLogs = [NSMutableArray arrayWithCapacity:1];
    [files enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * stop) {
        // 取出 ZegoLogs 下的 txt 日志文件
        if ([obj hasSuffix:@".txt"]) {
            NSString *logFileDir = [NSString stringWithFormat:@"%@/%@", zegologs, obj];
            [srcLogs addObject:logFileDir];
            [logFiles setObject:logFileDir forKey:obj];
        }
    }];
    
    self.srcLogs = srcLogs;
}

- (void)zipAndShare {
    // 压缩日志文件为 zip 格式
    if ([SSZipArchive createZipFileAtPath:self.dstLogFilePath withFilesAtPaths:self.srcLogs]) {
        UIDocumentInteractionController *controller = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:self.dstLogFilePath]];
        controller.delegate = self;
        self.documentController = controller;
        
        [controller presentOpenInMenuFromRect:self.view.bounds inView:self.view animated:YES];
    } else {
        [ZegoHudManager showMessage:@"压缩分享文件失败"];
    }
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
