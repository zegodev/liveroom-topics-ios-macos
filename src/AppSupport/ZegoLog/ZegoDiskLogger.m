//
//  ZegoDiskLogger.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/26.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoDiskLogger.h"
#import "ZegoDiskLogFormatter.h"

@interface ZegoDiskLogger ()

@property (strong, atomic) NSMutableArray<NSString*>* msgBuffer;
@property (copy, nonatomic) NSString *path;
@property (strong, nonatomic) NSFileHandle *handle;

@end

NSUInteger ZegoDiskLggerBufferSize = 100;

@implementation ZegoDiskLogger

- (void)dealloc {
    [self flush];
    [self.handle closeFile];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

+ (instancetype)loggerWithStoragePath:(NSString *)path {
    return [[self alloc] initWithStoragePath:path];
}

- (instancetype)initWithStoragePath:(NSString *)path {
    if (self = [super init]) {
        _path = path ?:self.defaultStoragePath;
        _msgBuffer = [NSMutableArray arrayWithCapacity:ZegoDiskLggerBufferSize];
        self.formatter = [ZegoDiskLogFormatter new];
        const char *label = "zglog.diskLogger";
        self.logQueue = dispatch_queue_create(label, NULL);
    }
    return self;
}

- (instancetype)init {
    return [self initWithStoragePath:nil];
}

- (void)zg_logMessage:(ZegoLogMessage *)message {
    NSString *formattedMsg = [self.formatter formatLogMessage:message];
    [self.msgBuffer addObject:formattedMsg];
    if (self.msgBuffer.count == ZegoDiskLggerBufferSize) {
        [self flush];
    }
}

- (void)zg_flush {
    if (self.msgBuffer.count == 0) {
        return;
    }
    
    NSMutableString *log = [NSMutableString string];
    for (NSString *msg in self.msgBuffer) {
        [log appendString:msg];
    }
    
    BOOL isFileExist = [NSFileManager.defaultManager fileExistsAtPath:self.path];
    if (!isFileExist) {
        NSError *error = nil;
        [NSFileManager.defaultManager createDirectoryAtPath:self.path.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"ZGLog diskLogger create error:%@", error);
        }
        else {
            BOOL success = [NSFileManager.defaultManager createFileAtPath:self.path contents:[log dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
            if (!success) {
                NSLog(@"ZGLog diskLogger create error");
            }
        }
    }
    else {
        self.handle = [NSFileHandle fileHandleForWritingAtPath:self.path];
        if (!self.handle) {
            NSLog(@"ZGLog diskLogger write file handle failed");
        }
        else {
            [self.handle seekToEndOfFile];
            [self.handle writeData:[log dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
    [self.msgBuffer removeAllObjects];
}

- (NSString *)defaultStoragePath {
    NSString* docPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    return [docPath stringByAppendingPathComponent:@"ZegoLogs/ZGAppLog.txt"];;
}

@end
