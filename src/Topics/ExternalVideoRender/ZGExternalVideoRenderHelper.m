//
//  ZGExternalVideoRenderHelper.m
//  LiveRoomPlayground
//
//  Created by Sky on 2019/1/29.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoRender

#import "ZGExternalVideoRenderHelper.h"

@implementation ZGExternalVideoRenderHelper

+ (void)showRenderData:(CVImageBufferRef)image inView:(ZGView *)view viewMode:(ZegoVideoViewMode)viewMode {
    CGImageRef cgImage = [self getCGImageFromCVImageBuffer:image inView:view viewMode:viewMode];
    CGImageRetain(cgImage);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        view.layer.contents = CFBridgingRelease(cgImage);
        CGImageRelease(cgImage);
        
        CALayerContentsGravity contentViewMode = nil;
        switch (viewMode) {
            case ZegoVideoViewModeScaleToFill:{
                contentViewMode = kCAGravityResize;
                break;
            }
            case ZegoVideoViewModeScaleAspectFit:{
                contentViewMode = kCAGravityResizeAspect;
                break;
            }
            case ZegoVideoViewModeScaleAspectFill:{
                contentViewMode = kCAGravityResizeAspectFill;
                break;
            }
        }
        view.layer.contentsGravity = contentViewMode;
    });
    
}

+ (void)removeRenderDataInView:(ZGView *)view {
    dispatch_async(dispatch_get_main_queue(), ^{
        view.layer.contents = nil;
    });
}

+ (CGImageRef)getCGImageFromCVImageBuffer:(CVImageBufferRef)imageBuffer inView:(ZGView *)view viewMode:(ZegoVideoViewMode)viewMode {
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer))];
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    return videoImage;
}

+ (NSArray<ZGDemoVideoRenderTypeItem*> *)demoRenderTypeItems {
    return @[[ZGDemoVideoRenderTypeItem itemWithRenderType:VideoRenderTypeNone typeName:@"不开启外部渲染"],
             [ZGDemoVideoRenderTypeItem itemWithRenderType:VideoRenderTypeRgb typeName:@"外部渲染,TypeRgb"],
             [ZGDemoVideoRenderTypeItem itemWithRenderType:VideoRenderTypeYuv typeName:@"外部渲染,TypeYuv"],
             [ZGDemoVideoRenderTypeItem itemWithRenderType:VideoRenderTypeAny typeName:@"外部渲染,TypeAny"],
             [ZGDemoVideoRenderTypeItem itemWithRenderType:VideoRenderTypeExternalInternalRgb typeName:@"内部外部渲染,TypeRgb"],
             [ZGDemoVideoRenderTypeItem itemWithRenderType:VideoRenderTypeExternalInternalYuv typeName:@"内部外部渲染,TypeYuv"]];
}

+ (BOOL)isInternalVideoRenderType:(VideoRenderType)renderType {
    return renderType == VideoRenderTypeExternalInternalRgb ||
        renderType == VideoRenderTypeExternalInternalYuv;
}

@end

#endif
