//
//  FUManager.m
//  FULiveDemo
//
//  Created by 刘洋 on 2017/8/18.
//  Copyright © 2017年 刘洋. All rights reserved.
//

#import "FUManager-mac.h"
#import "FURenderer.h"
#import "authpack_mac.h"
#import <sys/utsname.h>


@interface FUManager ()
{
    //MARK: Faceunity
    
    /*
     0.美颜
     1.普通道具
     2.考锯齿
     3.美妆
     */
    
    int items[4];
    int frameID;
    
    NSDictionary *hintDic;
    
    NSDictionary *alertDic ;
}

@property (nonatomic) int deviceOrientation;
@property (nonatomic) int faceNum;
@end

static FUManager *shareManager = NULL;

@implementation FUManager

+ (FUManager *)shareManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManager = [[FUManager alloc] init];
    });
    
    return shareManager;
}

+ (void)releaseManager {
    shareManager = nil;
}

- (instancetype)init
{
    if (self = [super init]) {
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"v3.bundle" ofType:nil];
        /**这里新增了一个参数shouldCreateContext，设为YES的话，不用在外部设置context操作，我们会在内部创建并持有一个context。
         还有设置为YES,则需要调用FURenderer.h中的接口，不能再调用funama.h中的接口。*/
        [[FURenderer shareRenderer] setupWithDataPath:path authPackage:&g_auth_package authSize:sizeof(g_auth_package) shouldCreateContext:YES];
        
        NSData *tongueData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tongue.bundle" ofType:nil]];
        int ret2 = fuLoadTongueModel((void *)tongueData.bytes, (int)tongueData.length) ;
        NSLog(@"fuLoadTongueModel %@",ret2 == 0 ? @"failure":@"success" );
        
        NSLog(@"sdk-------%@",[FURenderer getVersion]);
        //
//        
//        // 性能优先关闭
//        self.performance = NO ;
    }
    
    return self;
}



/**销毁全部道具*/
- (void)destoryAllItems
{
    [FURenderer destroyAllItems];    
    /**销毁道具后，为保证被销毁的句柄不再被使用，需要将int数组中的元素都设为0*/
    for (int i = 0; i < sizeof(items) / sizeof(int); i++) {
        items[i] = 0;
    }    
    /**销毁道具后，清除context缓存*/
    [FURenderer OnDeviceLost];

}


#pragma -Faceunity Load Data

/**加载美颜道具*/
- (void)loadFilter{
    if (items[0] == 0) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"face_beautification.bundle" ofType:nil];
//        items[0] = [FURenderer itemWithContentsOfFile:path];
        
        NSData *itemData = [[NSData alloc] initWithContentsOfFile:path];
        self -> items[0] = fuCreateItemFromPackage((void *)itemData.bytes, (int)itemData.length);
        [FURenderer itemSetParam:items[0] withName:@"is_opengl_es" value:@(0)];//mac端隐藏设置
    }
}

/**
 加载普通道具
 - 先创建再释放可以有效缓解切换道具卡顿问题
 */
- (void)loadItem:(NSString *)itemName
{
    //    self.selectedItem = itemName ;
    
    int destoryItem = items[1];
    if (itemName != nil && ![itemName isEqual: @"noitem"]) {
        /**先创建道具句柄*/
        
        //        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.bundle", itemName]];
        //
        //        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        //            path = [[NSBundle mainBundle] pathForResource:[itemName stringByAppendingString:@".bundle"] ofType:nil];
        //        }
        
        NSString *path = [[NSBundle mainBundle] pathForResource:[itemName stringByAppendingString:@".bundle"] ofType:nil];
        
        int itemHandle = [FURenderer itemWithContentsOfFile:path];
        
        // 人像驱动 设置 3DFlipH
        BOOL isPortraitDrive = [itemName hasPrefix:@"picasso_e"];
        BOOL isAnimoji = [itemName hasSuffix:@"_Animoji"];
        if (isPortraitDrive) {
            [FURenderer itemSetParam:itemHandle withName:@"is3DFlipH" value:@(0)];
            [FURenderer itemSetParam:itemHandle withName:@"isFlipExpr" value:@(0)];

        }
        if (isAnimoji) {
            [FURenderer itemSetParam:itemHandle withName:@"{\"thing\":\"<global>\",\"param\":\"follow\"}" value:@(1)];
            [FURenderer itemSetParam:itemHandle withName:@"is3DFlipH" value:@(0)];
            [FURenderer itemSetParam:itemHandle withName:@"isFlipExpr" value:@(0)];
            [FURenderer itemSetParam:itemHandle withName:@"isFlipTrack" value:@(0)];
            [FURenderer itemSetParam:itemHandle withName:@"isFlipLight" value:@(0)];
        }
        
        if ([itemName isEqualToString:@"luhantongkuan_ztt_fu"]) {
            [FURenderer itemSetParam:itemHandle withName:@"flip_action" value:@(1)];
        }
        /**将刚刚创建的句柄存放在items[1]中*/
        items[1] = itemHandle;
    }else{
        /**为避免道具句柄被销毁会后仍被使用导致程序出错，这里需要将存放道具句柄的items[1]设为0*/
        items[1] = 0;
    }
    NSLog(@"faceunity: load item");
    
    /**后销毁老道具句柄*/
    if (destoryItem != 0)
    {
        NSLog(@"faceunity: destroy item");
        [FURenderer destroyItem:destoryItem];
    }
}



- (void)loadAnimojiFaxxBundle {
    /**先创建道具句柄*/
    NSString *path = [[NSBundle mainBundle] pathForResource:@"fxaa.bundle" ofType:nil];
    int itemHandle = [FURenderer itemWithContentsOfFile:path];
    
    /**销毁老的道具句柄*/
    if (items[2] != 0) {
        NSLog(@"faceunity: destroy item");
        [FURenderer destroyItem:items[2]];
    }
    
    /**将刚刚创建的句柄存放在items[2]中*/
    items[2] = itemHandle;
}


- (int)changeParamsStr:(NSString *)sdkStr index:(int)index value:(id)value{
    if (!sdkStr || [sdkStr isEqualToString:@""] || index >= sizeof(items)/sizeof(items[0]) ) {
        NSLog(@"-------设置参数有误");
        return 0;
    }
    int r = [FURenderer itemSetParam:items[index] withName:sdkStr value:value];
    if (r != 1) {
        NSLog(@"(%@)(%f)(return - %d)(item - %d) - sdk 设置失败",sdkStr,[value floatValue],r,items[index]);
    }
    return r;
}

/**设置美颜参数*/
- (void)setAllSkinParam {
    [FURenderer itemSetParam:items[0] withName:@"skin_detect" value:@(self.skinDetectEnable)]; //是否开启皮肤检测
    [FURenderer itemSetParam:items[0] withName:@"heavy_blur" value:@(self.blurShape)]; // 美肤类型 (0、1、) 清晰：0，朦胧：1
    [FURenderer itemSetParam:items[0] withName:@"blur_level" value:@(self.blurLevel * 6.0 )]; //磨皮 (0.0 - 6.0)
    [FURenderer itemSetParam:items[0] withName:@"color_level" value:@(self.whiteLevel)]; //美白 (0~1)
    [FURenderer itemSetParam:items[0] withName:@"red_level" value:@(self.redLevel)]; //红润 (0~1)
    [FURenderer itemSetParam:items[0] withName:@"eye_bright" value:@(self.eyelightingLevel)]; // 亮眼
    [FURenderer itemSetParam:items[0] withName:@"tooth_whiten" value:@(self.beautyToothLevel)];// 美牙
}


/**将道具绘制到pixelBuffer*/
- (CVPixelBufferRef)renderItemsToPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    
    /*Faceunity核心接口，将道具及美颜效果绘制到pixelBuffer中，执行完此函数后pixelBuffer即包含美颜及贴纸效果*/
    CVPixelBufferRef buffer = [[FURenderer shareRenderer] renderPixelBuffer:pixelBuffer withFrameId:frameID items:items itemCount:sizeof(items)/sizeof(int) flipx:NO];//flipx 参数设为YES可以使道具做水平方向的镜像翻转
    frameID += 1;
    return buffer;
}



/**获取错误信息*/
- (NSString *)getError
{
    // 获取错误码
    int errorCode = fuGetSystemError();
    
    if (errorCode != 0) {
        
        // 通过错误码获取错误描述
        NSString *errorStr = [NSString stringWithUTF8String:fuGetSystemErrorString(errorCode)];
        
        return errorStr;
    }
    
    return nil;
}



#pragma  mark -  工具


-(unsigned char *)convertSourceImageToBitmapRGBA:(NSImage *)image{
    //由NSImage创建CGImageRef
    struct CGImageSource* source = CGImageSourceCreateWithData((__bridge CFDataRef)[image TIFFRepresentation], NULL);
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             (id)kCFBooleanFalse, (id)kCGImageSourceShouldCache,
                             (id)kCFBooleanTrue, (id)kCGImageSourceShouldAllowFloat,
                             nil];
    CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(source, 0, (CFDictionaryRef)options);
    
    //由CGImageRef创建CGContextRef
    CGContextRef context = [self newBitmapRGBA8ContextFromImage:imageRef];
    if (!context) {
        NSLog(@"picProcessing::convertSourceImageToBitmapRGBA:failed to create a context!");
        return nil;
    }
    
    //获取CGImageRef的宽高，并将CGImageRef画到CGContextRef中，以获取rawdata
    float imageWidth = CGImageGetWidth(imageRef);
    float imageHeight = CGImageGetHeight(imageRef);
//    float bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    CGRect imgRect = CGRectMake(0, 0, imageWidth, imageHeight);
    CGContextDrawImage(context, imgRect, imageRef);
    
    //获取CGContextRef中的rawdata的指针
    unsigned char * bitmapData = CGBitmapContextGetData(context);
    
    return bitmapData;
}

-(CGContextRef)newBitmapRGBA8ContextFromImage:(CGImageRef)image
{
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    uint32_t *bitmapData;
    
    size_t bitsPerPixel = 32;
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;
    
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    size_t bytesperRow = width * bytesPerPixel;
    size_t bufferLength = bytesperRow * height;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if(!colorSpace) {
        NSLog(@"Error allocating color space RGB\n");
        return NULL;
    }
    
    // Allocate memory for image data
    bitmapData = (uint32_t *)malloc(bufferLength);
    
    if(!bitmapData) {
        NSLog(@"Error allocating memory for bitmap\n");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    
    //Create bitmap context
    
    context = CGBitmapContextCreate(bitmapData,
                                    width,
                                    height,
                                    bitsPerComponent,
                                    bytesperRow,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);    // RGBA
    if(!context) {
        free(bitmapData);
        NSLog(@"picProcessing::newBitmapRGBA8ContextFromImage:Bitmap context not created");
    }
    
    CGColorSpaceRelease(colorSpace);
    
    return context;
}

@end
