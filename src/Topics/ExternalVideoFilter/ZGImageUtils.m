//
//  ZGImageUtils.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/31.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGImageUtils.h"

@implementation ZGImageUtils

+ (bool)create32BGRAPixelBufferPool:(CVPixelBufferPoolRef*)pool width:(int)width height:(int)height {
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    
    empty = CFDictionaryCreate(kCFAllocatorDefault,
                               NULL, NULL, 0,
                               &kCFTypeDictionaryKeyCallBacks,
                               &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    
    SInt32 cvPixelFormatTypeValue = kCVPixelFormatType_32BGRA;
    CFNumberRef cfPixelFormat = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void*)(&(cvPixelFormatTypeValue)));
    
    SInt32 cvWidthValue = width;
    CFNumberRef cfWidth = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void*)(&(cvWidthValue)));
    SInt32 cvHeightValue = height;
    CFNumberRef cfHeight = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void*)(&(cvHeightValue)));
    
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                      4,
                                      &kCFTypeDictionaryKeyCallBacks,
                                      &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    CFDictionarySetValue(attrs, kCVPixelBufferPixelFormatTypeKey, cfPixelFormat);
    CFDictionarySetValue(attrs, kCVPixelBufferWidthKey, cfWidth);
    CFDictionarySetValue(attrs, kCVPixelBufferHeightKey, cfHeight);
    
    CVReturn ret = CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, attrs, pool);
    
    CFRelease(attrs);
    CFRelease(empty);
    CFRelease(cfPixelFormat);
    CFRelease(cfWidth);
    CFRelease(cfHeight);
    
    if (ret != kCVReturnSuccess) {
        return false;
    }
    
    return true;
}

+ (bool)createI420PixelBufferPool:(CVPixelBufferPoolRef*)pool width:(int)width height:(int)height {
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    
    empty = CFDictionaryCreate(kCFAllocatorDefault,
                               NULL, NULL, 0,
                               &kCFTypeDictionaryKeyCallBacks,
                               &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    
    SInt32 cvPixelFormatTypeValue = kCVPixelFormatType_420YpCbCr8PlanarFullRange;
    CFNumberRef cfPixelFormat = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void*)(&(cvPixelFormatTypeValue)));
    
    SInt32 cvWidthValue = width;
    CFNumberRef cfWidth = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void*)(&(cvWidthValue)));
    SInt32 cvHeightValue = height;
    CFNumberRef cfHeight = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void*)(&(cvHeightValue)));
    
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                      5,
                                      &kCFTypeDictionaryKeyCallBacks,
                                      &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    CFDictionarySetValue(attrs, kCVPixelBufferPixelFormatTypeKey, cfPixelFormat);
    CFDictionarySetValue(attrs, kCVPixelBufferWidthKey, cfWidth);
    CFDictionarySetValue(attrs, kCVPixelBufferHeightKey, cfHeight);
#if TARGET_OS_IOS
    CFDictionarySetValue(attrs, kCVPixelBufferOpenGLESCompatibilityKey, kCFBooleanTrue);
#elif TARGET_OS_OSX
    CFDictionarySetValue(attrs, kCVPixelBufferOpenGLCompatibilityKey, kCFBooleanTrue);
#endif
    
    CVReturn ret = CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, attrs, pool);
    
    CFRelease(attrs);
    CFRelease(empty);
    CFRelease(cfPixelFormat);
    CFRelease(cfWidth);
    CFRelease(cfHeight);
    
    if (ret != kCVReturnSuccess) {
        return false;
    }
    
    return true;
}

+ (bool)createNV12PixelBufferPool:(CVPixelBufferPoolRef*)pool width:(int)width height:(int)height {
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    
    empty = CFDictionaryCreate(kCFAllocatorDefault,
                               NULL, NULL, 0,
                               &kCFTypeDictionaryKeyCallBacks,
                               &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    
    SInt32 cvPixelFormatTypeValue = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    CFNumberRef cfPixelFormat = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void*)(&(cvPixelFormatTypeValue)));
    
    SInt32 cvWidthValue = width;
    CFNumberRef cfWidth = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void*)(&(cvWidthValue)));
    SInt32 cvHeightValue = height;
    CFNumberRef cfHeight = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, (const void*)(&(cvHeightValue)));
    
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                      5,
                                      &kCFTypeDictionaryKeyCallBacks,
                                      &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    CFDictionarySetValue(attrs, kCVPixelBufferPixelFormatTypeKey, cfPixelFormat);
    CFDictionarySetValue(attrs, kCVPixelBufferWidthKey, cfWidth);
    CFDictionarySetValue(attrs, kCVPixelBufferHeightKey, cfHeight);
#if TARGET_OS_IOS
    CFDictionarySetValue(attrs, kCVPixelBufferOpenGLESCompatibilityKey, kCFBooleanTrue);
#elif TARGET_OS_OSX
    CFDictionarySetValue(attrs, kCVPixelBufferOpenGLCompatibilityKey, kCFBooleanTrue);
#endif
    
    CVReturn ret = CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, attrs, pool);
    
    CFRelease(attrs);
    CFRelease(empty);
    CFRelease(cfPixelFormat);
    CFRelease(cfWidth);
    CFRelease(cfHeight);
    
    if (ret != kCVReturnSuccess) {
        return false;
    }
    
    return true;
}

+ (void)destroyPixelBufferPool:(CVPixelBufferPoolRef*)pool {
    CVPixelBufferPoolRelease(*pool);
    *pool = nil;
}

+ (bool)copyPixelBufferFrom:(CVPixelBufferRef)src to:(CVPixelBufferRef)dst {
    CVReturn optRet = kCVReturnSuccess;
    optRet = CVPixelBufferLockBaseAddress(src, kCVPixelBufferLock_ReadOnly);
    if (optRet != kCVReturnSuccess) {
        return optRet;
    }
    optRet = CVPixelBufferLockBaseAddress(dst, 0);
    if (optRet != kCVReturnSuccess) {
        return optRet;
    }
    
    size_t planeCount = CVPixelBufferGetPlaneCount(src);
    if (planeCount == 0) {
        // non-planar
        void *p_dst = CVPixelBufferGetBaseAddress(dst);
        void *p_src = CVPixelBufferGetBaseAddress(src);
        size_t height = CVPixelBufferGetHeight(src);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(src);
        memcpy(p_dst, p_src, height * bytesPerRow);
    } else {
        // planar
        for (size_t plane = 0; plane < planeCount; plane++) {
            void *p_dst = CVPixelBufferGetBaseAddressOfPlane(dst, plane);
            void *p_src = CVPixelBufferGetBaseAddressOfPlane(src, plane);
            size_t height = CVPixelBufferGetHeightOfPlane(src, plane);
            size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(src, plane);
            memcpy(p_dst, p_src, height * bytesPerRow);
        }
    }
    
    CVPixelBufferUnlockBaseAddress(dst, 0);
    CVPixelBufferUnlockBaseAddress(src, kCVPixelBufferLock_ReadOnly);
    return optRet == kCVReturnSuccess;
}

#if TARGET_OS_IOS
+ (UIImage *)imageFromString:(NSString *)string attributes:(NSDictionary *)attributes {
    NSAttributedString *attributeString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
    CGRect rect = [attributeString boundingRectWithSize:CGSizeMake(100, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), YES, 0);
    
    [string drawInRect:CGRectMake(0, 0, rect.size.width, rect.size.height) withAttributes:attributes];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
#endif

+ (CIImage *)overlayImage:(CIImage *)backgroundImage image:(CIImage *)image size:(CGSize)size {
    CIFilter *filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [filter setDefaults];
    [filter setValue:backgroundImage forKey:kCIInputBackgroundImageKey];
    [filter setValue:[image imageByApplyingTransform:CGAffineTransformMakeTranslation(size.width, size.height)] forKey:kCIInputImageKey];
    
    return filter.outputImage;
}

+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image {
    CVPixelBufferRef pxbuffer = NULL;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    size_t width =  CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    size_t bytesPerRow = CGImageGetBytesPerRow(image);
    
    CFDataRef  dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(image));
    GLubyte  *imageData = (GLubyte *)CFDataGetBytePtr(dataFromImageDataProvider);
    
    CVPixelBufferCreateWithBytes(kCFAllocatorDefault,width,height,kCVPixelFormatType_32BGRA,imageData,bytesPerRow,NULL,NULL,(__bridge CFDictionaryRef)options,&pxbuffer);
    
    CFRelease(dataFromImageDataProvider);
    
    return pxbuffer;
}

+ (CGImageRef)createCGImageFromCVPixelBuffer:(CVPixelBufferRef)pixels {
    
    CVPixelBufferLockBaseAddress(pixels, kCVPixelBufferLock_ReadOnly);
    
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixels];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixels), CVPixelBufferGetHeight(pixels))];
    
    CVPixelBufferUnlockBaseAddress(pixels, kCVPixelBufferLock_ReadOnly);
    
    return videoImage;
}

@end
