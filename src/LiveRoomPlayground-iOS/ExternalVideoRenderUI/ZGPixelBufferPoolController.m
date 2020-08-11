//
//  ZGPixelBufferPoolController.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2020/7/21.
//  Copyright © 2020 Zego. All rights reserved.
//

#import "ZGPixelBufferPoolController.h"

@implementation ZGPixelBufferPool

- (instancetype)initWithPool:(CVPixelBufferPoolRef)pool width:(int)width height:(int)height format:(OSType)format {
    self = [super init];
    if(self) {
        _pool = pool;
        _width = width;
        _height = height;
        _format = format;
    }
    
    return self;
}

- (CVPixelBufferPoolRef)bufferPool { return _pool; }
- (int)width { return _width; }
- (int)height { return _height; }
- (OSType)format { return _format; }

@end


@interface ZGPixelBufferPoolController ()

@property (nonatomic) NSMutableDictionary<NSString*, ZGPixelBufferPool*> *pools;
@property (nonatomic) NSRecursiveLock *poolsLock;

@end

@implementation ZGPixelBufferPoolController

-(instancetype) init {
    if(self = [super init]) {
        _pools = [[NSMutableDictionary alloc] init];
        _poolsLock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

- (ZGPixelBufferPool *)createPixelBufferPool:(int)width height:(int)height format:(OSType)format streamID:(NSString* )streamID {
    
    [self.poolsLock lock];
    
    BOOL existKey = [self.pools.allKeys containsObject:streamID];
    if (existKey) {
        //如果当前流的内存池已存在，则删除，重新创建
        ZGPixelBufferPool *pool = [self getPixelBufferPool:streamID];
        if(pool != nil) {
            CVPixelBufferPoolRef pool_ = [pool bufferPool];
            CVPixelBufferPoolFlushFlags flag = 0;
            CVPixelBufferPoolFlush(pool_, flag);
            CFRelease(pool_);
        }
        [self.pools removeObjectForKey:streamID];
    }
    
    NSDictionary *pixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithBool:YES], (id)kCVPixelBufferOpenGLCompatibilityKey,
                                           [NSNumber numberWithInt:width], (id)kCVPixelBufferWidthKey,
                                           [NSNumber numberWithInt:height], (id)kCVPixelBufferHeightKey,
                                           [NSDictionary dictionary], (id)kCVPixelBufferIOSurfacePropertiesKey,
                                           [NSNumber numberWithInt:format], (id)kCVPixelBufferPixelFormatTypeKey,
                                           nil
                                           ];
    CVPixelBufferPoolRef pool_;
    CFDictionaryRef ref = (__bridge CFDictionaryRef)pixelBufferAttributes;
    CVReturn ret = CVPixelBufferPoolCreate(nil, nil, ref, &pool_);
    if (ret != kCVReturnSuccess) {
        [self.poolsLock unlock];
        return nil;
    }
    
    ZGPixelBufferPool *objPool = [[ZGPixelBufferPool alloc] initWithPool:pool_ width:width height:height format:format];
    self.pools[streamID] = objPool;
    
    [self.poolsLock unlock];
    return objPool;
}

- (BOOL)destroyPixelBufferPool:(NSString *)streamID {
    [self.poolsLock lock];
    
    BOOL existKey = [self.pools.allKeys containsObject:streamID];
    if (!existKey) {
        [self.poolsLock lock];
        return NO;
    }
    
    ZGPixelBufferPool *objPool = [self getPixelBufferPool:streamID];
    if(objPool == nil) {
        [self.poolsLock unlock];
        return NO;
    }
    
    CVPixelBufferPoolRef pool_ = [objPool bufferPool];
    CVPixelBufferPoolFlushFlags flag = 0;
    CVPixelBufferPoolFlush(pool_, flag);
    CFRelease(pool_);
    
    [self.pools removeObjectForKey:streamID];
    
    [self.poolsLock unlock];
    
    return YES;
}

- (void)destroyAllPixelBufferPool {
    [self.poolsLock lock];
    
    NSDictionary* pools = [self.pools copy];
    for(NSString *streamID in pools.allKeys) {
        [self destroyPixelBufferPool:streamID];
    }
    
    [self.poolsLock unlock];
}

- (ZGPixelBufferPool *)getPixelBufferPool:(NSString *)streamID {
    ZGPixelBufferPool *pool = nil;
    
    [self.poolsLock lock];
   
    pool = self.pools[streamID];
    
    [self.poolsLock unlock];
    
    return pool;
}

@end
