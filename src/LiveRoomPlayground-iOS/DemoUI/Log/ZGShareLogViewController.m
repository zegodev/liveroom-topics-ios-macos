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

@property (strong, nonatomic) UIDocumentInteractionController *documentController;

@end

@implementation ZGShareLogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    [self zipAppSDKLogAndPresentSharePage];
}

- (NSArray<NSString*> *)zegoSDKLogFilesInDir:(NSString *)logDir {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *files = [manager subpathsAtPath:logDir];
    
    NSMutableArray<NSString*> *logFiles = [NSMutableArray array];
    [files enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * stop) {
        // 取出 ZegoLogs 下的 txt 日志文件
        if ([obj hasSuffix:@".txt"]) {
            NSString *logFileDir = [logDir stringByAppendingPathComponent:obj];
            [logFiles addObject:logFileDir];
        }
    }];
    return [logFiles copy];
}

- (void)zipAppSDKLogAndPresentSharePage {
    // 在异步线程压缩文件·
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // app 的 zego SDK 日志
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *zegologDir = [cachesPath stringByAppendingPathComponent:@"ZegoLogs"];
        
        NSArray<NSString*> *srcLogFiles = [self zegoSDKLogFilesInDir:zegologDir];
        if (srcLogFiles.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [ZegoHudManager showMessage:@"暂无日志"];
            });
            return;
        }
        
        // 目标压缩包路径
        NSString *logZipFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"app_zegoavlog.zip"];
        BOOL zipRet = [SSZipArchive createZipFileAtPath:logZipFilePath withFilesAtPaths:srcLogFiles];
        NSLog(@"zip ret: %d", zipRet);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (zipRet) {
                UIDocumentInteractionController *controller = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:logZipFilePath]];
                controller.delegate = self;
                self.documentController = controller;
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    CGRect tarRect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 10);
                    [controller presentOpenInMenuFromRect:tarRect inView:self.view animated:YES];
                } else {
                    [controller presentOpenInMenuFromRect:self.view.bounds inView:self.view animated:YES];
                }
            } else {
                [ZegoHudManager showMessage:@"压缩分享文件失败"];
            }
        });
    });
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
