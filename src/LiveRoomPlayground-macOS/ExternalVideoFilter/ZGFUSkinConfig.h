//
//  ZGFUSkinConfig.h
//  LiveRoomPlayground-macOS
//
//  Created by Paaatrick on 2019/8/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGFUSkinConfig : NSObject

/**     美肤参数    **/
/** 精准美肤 (0、1)    */
@property (nonatomic, assign) BOOL skinDetect ;
/** 美肤类型 (0、1、) 清晰：0，朦胧：1    */
@property (nonatomic, assign) NSInteger heavyBlur;
/** 磨皮(0.0 - 6.0)    */
@property (nonatomic, assign) double blurLevel;
/** 美白 (0~1)    */
@property (nonatomic, assign) double colorLevel;
/** 红润 (0~1)    */
@property (nonatomic, assign) double redLevel;
/** 亮眼 (0~1)    */
@property (nonatomic, assign) double eyeBrightLevel;
/** 美牙 (0~1)    */
@property (nonatomic, assign) double toothWhitenLevel;

@end

NS_ASSUME_NONNULL_END
