//
//  ZGMetalPreviewBGRARenderer.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/14.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGMetalPreviewBGRARenderer.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@interface ZGMetalPreviewBGRARenderer () <MTKViewDelegate>

@property (nonatomic) id<MTLDevice> device;
@property (nonatomic, weak) MTKView *renderView;

@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, strong) id<MTLBuffer> vertices;
@property (nonatomic, assign) NSUInteger numVertices;

@property (assign, nonatomic) CVMetalTextureCacheRef textureCache;

@property (assign, nonatomic) ZegoVideoViewMode renderViewMode;

@end

@implementation ZGMetalPreviewBGRARenderer

- (instancetype)initWithDevice:(id<MTLDevice>)device forRenderView:(MTKView *)renderView {
    if (self = [super init]) {
        self.device = device;
        self.renderView = renderView;
        [self setup];
    }
    return self;
}

- (void)setRenderViewMode:(ZegoVideoViewMode)renderViewMode {
    _renderViewMode = renderViewMode;
    [self.renderView draw];
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (!pixelBuffer) return;
    
    CVMetalTextureRef tmpTexture = NULL;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                self.textureCache,
                                                                pixelBuffer,
                                                                NULL,
                                                                MTLPixelFormatBGRA8Unorm,
                                                                CVPixelBufferGetWidth(pixelBuffer),
                                                                CVPixelBufferGetHeight(pixelBuffer),
                                                                0,
                                                                &tmpTexture);
    
    if(status == kCVReturnSuccess) {
        self.texture = CVMetalTextureGetTexture(tmpTexture);
        CFRelease(tmpTexture);
    }
    
    self.renderView.drawableSize = self.renderView.bounds.size;
    [self.renderView draw];
}

#pragma mark - private methods

- (void)setup {
    self.renderView.delegate = self;
    // TextureCache的创建
    CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureCache);
    
    [self setupPipeline];
}

-(void)setupPipeline {
    id<MTLLibrary> defaultLibrary = self.device.newDefaultLibrary;
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.sampleCount = 1;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.renderView.colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
    
    pipelineStateDescriptor.vertexFunction = [defaultLibrary newFunctionWithName:@"mapTexture"];
    pipelineStateDescriptor.fragmentFunction = [defaultLibrary newFunctionWithName:@"displayTexture"];
    
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                     error:NULL];
    self.commandQueue = self.device.newCommandQueue;
}

- (MTLViewport)calculateAppropriateViewPort:(CGSize)drawableSize textureSize:(CGSize)textureSize {
    MTLViewport viewport;
    switch (self.renderViewMode) {
        case ZegoVideoViewModeScaleToFill:{
            viewport = (MTLViewport){0, 0, drawableSize.width, drawableSize.height, -1, 1};
        }
            break;
        case ZegoVideoViewModeScaleAspectFit:{
            double newTextureW, newTextureH, newOrigenX, newOrigenY;
            
            if (drawableSize.width/drawableSize.height < textureSize.width/textureSize.height) {
                newTextureW = drawableSize.width;
                newTextureH = textureSize.height * drawableSize.width / textureSize.width;
                newOrigenX = 0;
                newOrigenY = (drawableSize.height - newTextureH) / 2;
            }
            else {
                newTextureH = drawableSize.height;
                newTextureW = textureSize.width * drawableSize.height / textureSize.height;
                newOrigenY = 0;
                newOrigenX = (drawableSize.width - newTextureW) / 2;
            }
            
            viewport = (MTLViewport){newOrigenX, newOrigenY, newTextureW, newTextureH, -1, 1};
        }
            break;
        case ZegoVideoViewModeScaleAspectFill:{
            double newTextureW, newTextureH, newOrigenX, newOrigenY;
            
            if (drawableSize.width/drawableSize.height < textureSize.width/textureSize.height) {
                newTextureH = drawableSize.height;
                newTextureW = textureSize.width * drawableSize.height / textureSize.height;
                newOrigenY = 0;
                newOrigenX = (drawableSize.width - newTextureW) / 2;
            }
            else {
                newTextureW = drawableSize.width;
                newTextureH = textureSize.height * drawableSize.width / textureSize.width;
                newOrigenX = 0;
                newOrigenY = (drawableSize.height - newTextureH) / 2;
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
    id <CAMetalDrawable> currentDrawable = view.currentDrawable;
    id <MTLCommandBuffer> commandBuffer = self.commandQueue.commandBuffer;
    MTLRenderPassDescriptor *currentRenderPassDescriptor = view.currentRenderPassDescriptor;
    if (!currentDrawable || !commandBuffer || !currentRenderPassDescriptor) {
        return;
    }
    
    id <MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:currentRenderPassDescriptor];
    
    CGSize textureSize = CGSizeMake(self.texture.width, self.texture.height);
    MTLViewport viewport = [self calculateAppropriateViewPort:view.drawableSize textureSize:textureSize];
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
