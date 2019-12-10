//
//  ZGAppGlobalConfigViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/6.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGAppGlobalConfigViewController.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import <ZegoLiveRoom/ZegoLiveRoomApi.h>
#import "ZGWebRTCUrlInputVC.h"
#import "ZGTopicCommonDefines.h"
#import <SSZipArchive/SSZipArchive.h>

@interface ZGAppGlobalConfigViewController () <UIDocumentInteractionControllerDelegate>

@property (strong, nonatomic) UIDocumentInteractionController *documentController;

@property (weak, nonatomic) IBOutlet UITextField *appIDTxf;
@property (weak, nonatomic) IBOutlet UITextView *appSignTxv;
@property (weak, nonatomic) IBOutlet UISegmentedControl *environmentSegCtrl;
@property (weak, nonatomic) IBOutlet UILabel *VEVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *SDKVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *openHardwareEncodeSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *openHardwareDecodeSwitch;

@end

@implementation ZGAppGlobalConfigViewController

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"GlobalConfig" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGAppGlobalConfigViewController class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (IBAction)copyVEVersion:(id)sender {
    [[UIPasteboard generalPasteboard] setString:[ZegoLiveRoomApi version2]];
}

- (IBAction)copySDKVersion:(id)sender {
    [[UIPasteboard generalPasteboard] setString:[ZegoLiveRoomApi version]];
}

#pragma mark - private methods

- (void)setupUI {
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.navigationItem.title = @"设置";
    UIBarButtonItem *resetItem = [[UIBarButtonItem alloc] initWithTitle:@"重置" style:UIBarButtonItemStylePlain target:self action:@selector(resetConfig:)];
    UIBarButtonItem *saveChangeItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(saveAppGlobalConfig:)];
    self.navigationItem.rightBarButtonItems = @[saveChangeItem,resetItem];
    
    self.appSignTxv.layer.borderColor = [UIColor colorWithWhite:0.6 alpha:1].CGColor;
    self.appSignTxv.layer.borderWidth = 0.5f;
    
    self.VEVersionLabel.text = [NSString stringWithFormat:@"VE 版本：%@", [ZegoLiveRoomApi version2]];
    self.SDKVersionLabel.text = [NSString stringWithFormat:@"SDK 版本：%@", [ZegoLiveRoomApi version]];
    self.appVersionLabel.text = [NSString stringWithFormat:@"Demo 版本：%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];

    ZGAppGlobalConfig *config = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    [self applyConfig:config];
}

- (void)resetConfig:(id)sender {
    [self.view endEditing:YES];
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:@"确定重置为默认设置吗？" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"重置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        ZGAppGlobalConfig *config = [ZGAppGlobalConfigManager defaultGlobalConfig];
        [[ZGAppGlobalConfigManager sharedInstance] setGlobalConfig:config];
        [ZegoHudManager showMessage:@"已重置为默认设置"];
        [self applyConfig:config];
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)saveAppGlobalConfig:(id)sender {
    [self.view endEditing:YES];
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:@"确定保存当前修改的设置吗？" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        ZGAppGlobalConfig *config = [[ZGAppGlobalConfig alloc] init];
        config.appID = (unsigned int)[self.appIDTxf.text longLongValue];
        config.appSign = self.appSignTxv.text;
        config.environment = self.environmentSegCtrl.selectedSegmentIndex == 0?ZGAppEnvironmentTest:ZGAppEnvironmentOfficial;
        config.openHardwareEncode = self.openHardwareEncodeSwitch.isOn;
        config.openHardwareDecode = self.openHardwareDecodeSwitch.isOn;
        
        [[ZGAppGlobalConfigManager sharedInstance] setGlobalConfig:config];
        [ZegoHudManager showMessage:@"已保存设置"];
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)applyConfig:(ZGAppGlobalConfig *)configInfo {
    if (!configInfo) {
        return;
    }
    self.appIDTxf.text = @(configInfo.appID).stringValue;
    self.appSignTxv.text = configInfo.appSign;
    self.environmentSegCtrl.selectedSegmentIndex = configInfo.environment == ZGAppEnvironmentTest?0:1;
    self.openHardwareEncodeSwitch.on = configInfo.openHardwareEncode;
    self.openHardwareDecodeSwitch.on = configInfo.openHardwareDecode;
}

- (void)openWebRTCURLTestPage {
    ZGWebRTCUrlInputVC *vc = [ZGWebRTCUrlInputVC instanceFromStoryboard];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            [self openWebRTCURLTestPage];
        } else if (indexPath.row == 1) {
            [self zipReplayKitUploadExtensionSDKLogAndPresentSharePage];
        } else if (indexPath.row == 2) {
            [self clearHostAppZegoSDKLog];
        }
    }
}

- (void)clearHostAppZegoSDKLog {
    NSLog(@"begin clearHostAppZegoSDKLog");
    NSArray<NSString*> *srcLogFiles = [self zegoSDKLogFilesInDir:ZG_HOST_APP_ZEGO_LOG_DIR_FULLPATH];
    if (srcLogFiles.count > 0) {
        for (NSString *logFilePath in srcLogFiles) {
            NSError *err;
            [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:&err];
            if (err) {
                NSLog(@"Failed to remove file(%@), err:%@", logFilePath, err);
            } else {
                NSLog(@"Succeed to remove file(%@)", logFilePath);
            }
        }
    }
    NSLog(@"end clearHostAppZegoSDKLog");
}

- (NSString *)createZegoLogDirIfNeed {
    // 设置录屏进程的 Zego SDK 日志路径
    NSURL *groupURL = [[NSFileManager defaultManager]
    containerURLForSecurityApplicationGroupIdentifier:ZGAPP_GROUP_NAME];
    NSURL *replayKitZegoLogDirURL = [groupURL URLByAppendingPathComponent:ZGAPP_REPLAYKIT_UPLOAD_EXTENSION_ZEGO_LOG_DIR isDirectory:YES];
    NSError *err = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:replayKitZegoLogDirURL withIntermediateDirectories:YES attributes:nil error:&err];
    NSString *dir = replayKitZegoLogDirURL.path;
    NSLog(@"create zego log dir:%@, error:%@", dir, err);
    if (err) {
        return nil;
    }
    return dir;
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

- (void)zipReplayKitUploadExtensionSDKLogAndPresentSharePage {
    // 在异步线程压缩文件·
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 录屏扩展的日志
        NSString *extensionSDKLogDir = [self createZegoLogDirIfNeed];
        if (!extensionSDKLogDir) {
            ZGLogWarn(@"获取录屏扩展 zego sdk 日志目录失败");
            return;
        }
        
        NSArray<NSString*> *srcLogFiles = [self zegoSDKLogFilesInDir:extensionSDKLogDir];
        if (srcLogFiles.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [ZegoHudManager showMessage:@"暂无日志"];
            });
            return;
        }
        
        // 目标压缩包路径
        NSString *logZipFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"upload_extension_zegoavlog.zip"];
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

#pragma mark - UIDocumentInteractionControllerDelegate
- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
    [controller dismissMenuAnimated:YES];
}

@end
