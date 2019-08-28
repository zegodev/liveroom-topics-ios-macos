//
//  ZGImageUtils.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/31.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 处理图像工具类
 */
@interface ZGImageUtils : NSObject


/**
 创建 BGRA32 类型的 PixelBufferPool

 @param pool CVPixelBufferPoolRef, The newly created pool will be placed here
 @param width Image Width
 @param height Image Height
 @return bool 是否成功创建 PixelBufferPool
 */
+ (bool)create32BGRAPixelBufferPool:(CVPixelBufferPoolRef *)pool width:(int)width height:(int)height;

/**
 创建 I420 类型的 PixelBufferPool
 
 @param pool CVPixelBufferPoolRef, The newly created pool will be placed here
 @param width Image Width
 @param height Image Height
 @return bool 是否成功创建 PixelBufferPool
 */
+ (bool)createI420PixelBufferPool:(CVPixelBufferPoolRef*)pool width:(int)width height:(int)height;


/**
 释放 CVPixelBufferPoolRef

 @param pool 待释放的 CVPixelBufferPoolRef
 */
+ (void)destroyPixelBufferPool:(CVPixelBufferPoolRef *)pool;


/**
 拷贝 CVPixelBufferRef

 @param src Source CVPixelBufferRef
 @param dst Destination Destination
 @return bool 是否成功拷贝
 */
+ (bool)copyPixelBufferFrom:(CVPixelBufferRef)src to:(CVPixelBufferRef)dst;

#if TARGET_OS_IOS
+ (UIImage *)imageFromString:(NSString *)string attributes:(NSDictionary *)attributes;
#endif
+ (CIImage *)overlayImage:(CIImage *)backgroundImage image:(CIImage *)image size:(CGSize)size;
+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image;
+ (CGImageRef)createCGImageFromCVPixelBuffer:(CVPixelBufferRef)pixels;

@end
