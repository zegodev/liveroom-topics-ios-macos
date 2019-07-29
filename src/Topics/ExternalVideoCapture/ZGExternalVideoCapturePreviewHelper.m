//
//  ZGExternalVideoCapturePreviewHelper.m
//  ZegoLiveRoomWrapper
//
//  Created by Sky on 2019/6/12.
//  Copyright © 2019 zego. All rights reserved.
//

#ifdef _Module_ExternalVideoCapture

#import "ZGExternalVideoCapturePreviewHelper.h"
#import "ZegoMTKRenderView.h"

@implementation ZGExternalVideoCapturePreviewHelper

+ (void)showCaptureData:(CVImageBufferRef)image inView:(ZEGOView *)view viewMode:(ZegoVideoViewMode)viewMode {
    CVBufferRetain(image);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ZegoMTKRenderView *renderView = [self getRenderViewFromView:view];
        
        if (!renderView) {
            [self createSubRenderViewInView:view];
        }
        
        [renderView renderImage:image viewMode:viewMode];
        
        CVBufferRelease(image);
    });
}

+ (ZegoMTKRenderView *)getRenderViewFromView:(ZEGOView *)view {
    for (ZEGOView *subview in view.subviews) {
        if ([subview isKindOfClass:ZegoMTKRenderView.class]) {
            return (ZegoMTKRenderView *)subview;
        }
    }
    
    return nil;
}

+ (ZegoMTKRenderView *)createSubRenderViewInView:(ZEGOView *)view {
    ZegoMTKRenderView *renderView = [[ZegoMTKRenderView alloc] initWithFrame:view.bounds];
    
#if TARGET_OS_OSX
    [view addSubview:renderView positioned:NSWindowBelow relativeTo:nil];
#elif TARGET_OS_IOS
    [view insertSubview:renderView atIndex:0];
#endif
    
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:renderView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
    
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:renderView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:renderView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0];
    
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:renderView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0];
    
    [view addConstraints:@[left, top, width, height]];
    
    return renderView;
}

+ (void)removeCaptureDataInView:(ZEGOView *)view {
    dispatch_async(dispatch_get_main_queue(), ^{
        ZegoMTKRenderView *renderView = [self getRenderViewFromView:view];
        [renderView removeFromSuperview];
    });
}

@end

#endif
