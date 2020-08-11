//
//  ZGPixelBufferPoolController.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2020/7/21.
//  Copyright © 2020 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZGPixelBufferPool : NSObject
{
    CVPixelBufferPoolRef _pool;
    int _width;
    int _height;
    OSType _format;
}

- (CVPixelBufferPoolRef)bufferPool;
- (int)width;
- (int)height;
- (OSType)format;

@end

@interface ZGPixelBufferPoolController : NSObject

- (ZGPixelBufferPool *)createPixelBufferPool:(int)width height:(int)height format:(OSType)format streamID:(NSString* )streamID;
- (BOOL)destroyPixelBufferPool:(NSString *)streamID;
- (void)destroyAllPixelBufferPool;
- (ZGPixelBufferPool *)getPixelBufferPool:(NSString *)streamID;

@end
