//
//  ZGMetalPreviewYUVRenderer.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/14.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGMetalPreviewYUVRenderer.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import "LYShaderTypes.h"

@interface ZGMetalPreviewYUVRenderer () <MTKViewDelegate>

@property (nonatomic) id<MTLDevice> device;
@property (nonatomic, weak) MTKView *renderView;
@property (nonatomic, assign) ZegoVideoViewMode renderViewMode;

@property (nonatomic) id<MTLCommandQueue> commandQueue;
@property (nonatomic) id<MTLRenderPipelineState> pipelineState;

@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;
@property (nonatomic, strong) id<MTLTexture> yTexture;
@property (nonatomic, strong) id<MTLTexture> uvTexture;
@property (nonatomic, strong) id<MTLBuffer> vertices;
@property (nonatomic, strong) id<MTLBuffer> convertMatrix;
@property (nonatomic, assign) NSUInteger numVertices;

@property (nonatomic, assign) NSUInteger displayFrameCountLoop;

@end

@implementation ZGMetalPreviewYUVRenderer

- (void)dealloc {
    // Release texture cache
    if (self.textureCache) {
        CVMetalTextureCacheFlush(self.textureCache, 0);
        CFRelease(self.textureCache);
    }
}

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
    
    id<MTLTexture> textureY = nil;
    id<MTLTexture> textureUV = nil;
    // textureY 设置
    {
        size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
        size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
        MTLPixelFormat pixelFormat = MTLPixelFormatR8Unorm; // 这里的颜色格式不是RGBA
        
        CVMetalTextureRef texture = NULL; // CoreVideo的Metal纹理
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, pixelBuffer, NULL, pixelFormat, width, height, 0, &texture);
        
        self.displayFrameCountLoop++;
        if (self.displayFrameCountLoop > 15) {
            // 定期 CVMetalTextureCacheFlush，释放内存
            if (self.textureCache) {
                CVMetalTextureCacheFlush(self.textureCache, 0);
            }
            self.displayFrameCountLoop = 0;
        }
        
        if(status == kCVReturnSuccess)
        {
            textureY = CVMetalTextureGetTexture(texture); // 转成Metal用的纹理
            self.yTexture = textureY;
            CFRelease(texture);
        }
    }
    
    // textureUV 设置
    {
        size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
        size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
        MTLPixelFormat pixelFormat = MTLPixelFormatRG8Unorm; // 2-8bit的格式
        
        CVMetalTextureRef texture = NULL; // CoreVideo的Metal纹理
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, self.textureCache, pixelBuffer, NULL, pixelFormat, width, height, 1, &texture);
        if(status == kCVReturnSuccess)
        {
            textureUV = CVMetalTextureGetTexture(texture); // 转成Metal用的纹理
            self.uvTexture = textureUV;
            CFRelease(texture);
        }
    }
    
    [self.renderView draw];
}

#pragma mark - private methods

- (void)setup {
    self.renderView.delegate = self;
    // TextureCache的创建
    CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureCache);

    [self setupPipeline];
    [self setupVertex];
    [self setupMatrix];
}

/**
 
 // BT.601, which is the standard for SDTV.
 matrix_float3x3 kColorConversion601Default = (matrix_float3x3){
 (simd_float3){1.164,  1.164, 1.164},
 (simd_float3){0.0, -0.392, 2.017},
 (simd_float3){1.596, -0.813,   0.0},
 };
 
 //// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
 matrix_float3x3 kColorConversion601FullRangeDefault = (matrix_float3x3){
 (simd_float3){1.0,    1.0,    1.0},
 (simd_float3){0.0,    -0.343, 1.765},
 (simd_float3){1.4,    -0.711, 0.0},
 };
 
 //// BT.709, which is the standard for HDTV.
 matrix_float3x3 kColorConversion709Default[] = {
 (simd_float3){1.164,  1.164, 1.164},
 (simd_float3){0.0, -0.213, 2.112},
 (simd_float3){1.793, -0.533,   0.0},
 };
 */
- (void)setupMatrix { // 设置好转换的矩阵
    matrix_float3x3 kColorConversion601FullRangeMatrix = (matrix_float3x3){
        (simd_float3){1.0,    1.0,    1.0},
        (simd_float3){0.0,    -0.343, 1.765},
        (simd_float3){1.4,    -0.711, 0.0},
    };
    
    vector_float3 kColorConversion601FullRangeOffset = (vector_float3){ -(16.0/255.0), -0.5, -0.5}; // 这个是偏移
    
    LYConvertMatrix matrix;
    // 设置参数
    matrix.matrix = kColorConversion601FullRangeMatrix;
    matrix.offset = kColorConversion601FullRangeOffset;
    
    self.convertMatrix = [self.device newBufferWithBytes:&matrix
                                                  length:sizeof(LYConvertMatrix)
                                                 options:MTLResourceStorageModeShared];
}

// 设置渲染管道
-(void)setupPipeline {
    id<MTLLibrary> defaultLibrary = [self.device newDefaultLibrary]; // .metal
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"]; // 顶点shader，vertexShader是函数名
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"samplingShader"]; // 片元shader，samplingShader是函数名
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.renderView.colorPixelFormat; // 设置颜色格式
    NSError *error;
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                       error:&error]; // 创建图形渲染管道，耗性能操作不宜频繁调用
    if (error) {
        UIViewController *rootVC = [[UIApplication sharedApplication].keyWindow rootViewController];
        
        NSString *alertStr = [NSString stringWithFormat:@"⚠️问题原因：%@\n请将该问题反馈给对应开发，谢谢！🙂", error.description];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Metal 渲染遇到问题" message:alertStr preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [rootVC presentViewController:alert animated:true completion:nil];
        return;
    }
    self.commandQueue = [self.device newCommandQueue]; // CommandQueue是渲染指令队列，保证渲染指令有序地提交到GPU
}

// 设置顶点
- (void)setupVertex {
    static const LYVertex quadVertices[] =
    {   // 顶点坐标，分别是x、y、z、w；    纹理坐标，x、y；
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0, -1.0, 0.0, 1.0 },  { 0.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        
        { {  1.0, -1.0, 0.0, 1.0 },  { 1.f, 1.f } },
        { { -1.0,  1.0, 0.0, 1.0 },  { 0.f, 0.f } },
        { {  1.0,  1.0, 0.0, 1.0 },  { 1.f, 0.f } },
    };
    self.vertices = [self.device newBufferWithBytes:quadVertices
                                             length:sizeof(quadVertices)
                                            options:MTLResourceStorageModeShared]; // 创建顶点缓存
    self.numVertices = sizeof(quadVertices) / sizeof(LYVertex); // 顶点个数
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

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)drawInMTKView:(MTKView *)view {
    id<MTLTexture> yTexture = self.yTexture;
    id<MTLTexture> uvTexture = self.uvTexture;
    if (!yTexture || !uvTexture) {
        return;
    }

    // 每次渲染都要单独创建一个CommandBuffer
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    if(!commandBuffer || !renderPassDescriptor) {
        return;
    }
    // MTLRenderPassDescriptor描述一系列attachments的值，类似GL的FrameBuffer；同时也用来创建MTLRenderCommandEncoder
    
//    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.5, 1.0f); // 设置默认颜色
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor]; //编码绘制指令的Encoder
    
    CGSize textureSize = CGSizeMake(MAX(yTexture.width, uvTexture.width), MAX(yTexture.height, uvTexture.height));
    MTLViewport viewport = [self calculateAppropriateViewPort:view.drawableSize textureSize:textureSize];
    [renderEncoder setViewport:viewport]; // 设置显示区域
    
    [renderEncoder setRenderPipelineState:self.pipelineState]; // 设置渲染管道，以保证顶点和片元两个shader会被调用
    
    [renderEncoder setVertexBuffer:self.vertices
                            offset:0
                           atIndex:LYVertexInputIndexVertices]; // 设置顶点缓存
    
    [renderEncoder setFragmentTexture:yTexture
                              atIndex:LYFragmentTextureIndexTextureY]; // 设置纹理
    [renderEncoder setFragmentTexture:uvTexture
                              atIndex:LYFragmentTextureIndexTextureUV]; // 设置纹理
    
    [renderEncoder setFragmentBuffer:self.convertMatrix
                              offset:0
                             atIndex:LYFragmentInputIndexMatrix];
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:self.numVertices]; // 绘制
    
    [renderEncoder endEncoding]; // 结束
    
    [commandBuffer presentDrawable:view.currentDrawable]; // 显示
    
    [commandBuffer commit]; // 提交；
}

@end
