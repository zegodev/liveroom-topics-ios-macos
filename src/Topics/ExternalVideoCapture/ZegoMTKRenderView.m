//
//  ZegoMTKRenderView.m
//  ZegoLiveRoomWrapper
//
//  Created by Sky on 2019/7/3.
//  Copyright © 2019 zego. All rights reserved.
//

#if !TARGET_OS_SIMULATOR

#ifdef _Module_ExternalVideoCapture

#import "ZegoMTKRenderView.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@interface ZegoMTKRenderView () <MTKViewDelegate>

@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, strong) id<MTLBuffer> vertices;
@property (nonatomic, assign) NSUInteger numVertices;

@property (assign, nonatomic) CVMetalTextureCacheRef textureCache;

@property (assign, nonatomic) ZegoVideoViewMode viewMode;

@end

@implementation ZegoMTKRenderView

- (instancetype)initWithFrame:(CGRect)frameRect device:(id<MTLDevice>)device {
    if (self = [super initWithFrame:frameRect device:device]) {
#if TARGET_OS_OSX
        self.layer.backgroundColor = NSColor.blackColor.CGColor;
#elif TARGET_OS_IOS
        self.backgroundColor = UIColor.blackColor;
#endif
        [self customInit];
    }
    
    return self;
}

- (void)customInit {
    [self setupView];
    [self setupPipeline];
}


- (void)setupView {
    if (!self.device) {
        self.device = MTLCreateSystemDefaultDevice();
    }
    
    self.framebufferOnly = YES;
    self.preferredFramesPerSecond = 0;
    
#if TARGET_OS_IOS
    self.contentScaleFactor = UIScreen.mainScreen.scale;
#endif
    
    self.delegate = self;
}

-(void)setupPipeline {
    id<MTLLibrary> defaultLibrary = self.device.newDefaultLibrary;
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.sampleCount = 1;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
    
    pipelineStateDescriptor.vertexFunction = [defaultLibrary newFunctionWithName:@"mapTexture"];
    pipelineStateDescriptor.fragmentFunction = [defaultLibrary newFunctionWithName:@"displayTexture"];
    
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                     error:NULL];
    self.commandQueue = self.device.newCommandQueue;
    
    CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureCache);
}

- (void)renderImage:(CVPixelBufferRef)image viewMode:(ZegoVideoViewMode)viewMode {
    CVMetalTextureRef tmpTexture = NULL;
    
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                self.textureCache,
                                                                image,
                                                                NULL,
                                                                MTLPixelFormatBGRA8Unorm,
                                                                CVPixelBufferGetWidth(image),
                                                                CVPixelBufferGetHeight(image),
                                                                0,
                                                                &tmpTexture);
    
    if(status == kCVReturnSuccess) {
        self.viewMode = viewMode;
        self.texture = CVMetalTextureGetTexture(tmpTexture);
        CFRelease(tmpTexture);
    }
    
    self.drawableSize = self.bounds.size;
    
    [self draw];
}

- (MTLViewport)getAppropriateViewPort {
    CGSize drawSize = self.drawableSize;
    CGSize textureSize = CGSizeMake(self.texture.width, self.texture.height);
    
    MTLViewport viewport;
    
    switch (self.viewMode) {
        case ZegoVideoViewModeScaleToFill:{
            viewport = (MTLViewport){0, 0, drawSize.width, drawSize.height, -1, 1};
        }
            break;
        case ZegoVideoViewModeScaleAspectFit:{
            double newTextureW, newTextureH, newOrigenX, newOrigenY;
            
            if (drawSize.width/drawSize.height < textureSize.width/textureSize.height) {
                newTextureW = drawSize.width;
                newTextureH = textureSize.height * drawSize.width / textureSize.width;
                newOrigenX = 0;
                newOrigenY = (drawSize.height - newTextureH) / 2;
            }
            else {
                newTextureH = drawSize.height;
                newTextureW = textureSize.width * drawSize.height / textureSize.height;
                newOrigenY = 0;
                newOrigenX = (drawSize.width - newTextureW) / 2;
            }
            
            viewport = (MTLViewport){newOrigenX, newOrigenY, newTextureW, newTextureH, -1, 1};
        }
            break;
        case ZegoVideoViewModeScaleAspectFill:{
            double newTextureW, newTextureH, newOrigenX, newOrigenY;
            
            if (drawSize.width/drawSize.height < textureSize.width/textureSize.height) {
                newTextureH = drawSize.height;
                newTextureW = textureSize.width * drawSize.height / textureSize.height;
                newOrigenY = 0;
                newOrigenX = (drawSize.width - newTextureW) / 2;
            }
            else {
                newTextureW = drawSize.width;
                newTextureH = textureSize.height * drawSize.width / textureSize.width;
                newOrigenX = 0;
                newOrigenY = (drawSize.height - newTextureH) / 2;
            }
            
            viewport = (MTLViewport){newOrigenX, newOrigenY, newTextureW, newTextureH, -1, 1};
        }
            break;
    }
    
    return viewport;
}


#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)drawInMTKView:(nonnull MTKView *)view {
#if TARGET_OS_IOS
    BOOL isBackground = UIApplication.sharedApplication.applicationState == UIApplicationStateBackground;
    if (isBackground) {//后台调用部分系统版本会导致崩溃
        return;
    }
#endif
    
    id <CAMetalDrawable> currentDrawable = self.currentDrawable;
    id <MTLCommandBuffer> commandBuffer = self.commandQueue.commandBuffer;
    MTLRenderPassDescriptor *currentRenderPassDescriptor = self.currentRenderPassDescriptor;
    id <MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:currentRenderPassDescriptor];
    
    MTLViewport viewport = [self getAppropriateViewPort];
    [encoder setViewport:viewport];
    
    [encoder pushDebugGroup:@"RenderFrame"];
    [encoder setRenderPipelineState:self.pipelineState];
    [encoder setFragmentTexture:self.texture atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4 instanceCount:1];
    [encoder popDebugGroup];
    [encoder endEncoding];
    
    
    [commandBuffer presentDrawable:currentDrawable];
    [commandBuffer commit];
}

@end

#endif

#endif
