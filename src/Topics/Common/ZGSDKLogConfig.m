//
//  ZGSDKLogConfig.m
//  LiveRoomPlayground-iOS
//
//  Created by zego on 2020/11/26.
//  Copyright © 2020 Zego. All rights reserved.
//

#import "ZGSDKLogConfig.h"
#import "ZGAppGlobalConfigManager.h"


@implementation ZGSDKLogConfig

+ (void)sdkLogConfig {
    
    ZGAppGlobalConfig *configInfo = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    
    unsigned int fileSize = configInfo.logFileSize * 1024 * 1024;

    NSSearchPathDirectory directory = [configInfo.logFileBaseDirName isEqualToString:@"Document"] ?  NSDocumentDirectory : NSLibraryDirectory;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    NSString *baseDir = [paths objectAtIndex:0];
    NSMutableString *filePathMutalbe = baseDir.mutableCopy;
    [filePathMutalbe appendString:@"/Caches/ZegoLogs"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePathMutalbe.copy]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePathMutalbe.copy withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [ZegoLiveRoomApi setLogDir:baseDir size:fileSize subFolder:@"Caches/ZegoLogs"];
    [ZegoLiveRoomApi setVerbose:configInfo.showLogUnCrypt];
    
}
@end
