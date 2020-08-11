#ifndef zego_api_mediaplayer_oc_h
#define zego_api_mediaplayer_oc_h

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define ZEGOView  UIView
#define ZEGOImage UIImage
#elif TARGET_OS_OSX
#import <AppKit/AppKit.h>
#define ZEGOView  NSView
#define ZEGOImage NSImage
#endif

#import "zego-api-defines-oc.h"
#import "zego-api-mediaplayer-defines-oc.h"


/**
 多实例播放器的回调接口
 */
@protocol ZegoMediaPlayerEventWithIndexDelegate <NSObject>

@optional

/**
 开始播放
 
 @param index 播放器序号
 */
- (void)onPlayStart:(ZegoMediaPlayerIndex)index;

/**
 暂停播放
 
 @param index 播放器序号
 */
- (void)onPlayPause:(ZegoMediaPlayerIndex)index;

/**
 恢复播放
 
 @param index 播放器序号
 */
- (void)onPlayResume:(ZegoMediaPlayerIndex)index;

/**
 播放错误
 
 @param code 错误码, 详见 ZegoMediaPlayerError
 @param index 播放器序号
 */
- (void)onPlayError:(int)code playerIndex:(ZegoMediaPlayerIndex)index;

/**
 开始播放视频
 
 @param index 播放器序号
 */
- (void)onVideoBegin:(ZegoMediaPlayerIndex)index;


/**
 开始播放音频
 
 @param index 播放器序号
 */
- (void)onAudioBegin:(ZegoMediaPlayerIndex)index;


/**
 播放结束
 
 @param index 播放器序号
 */
- (void)onPlayEnd:(ZegoMediaPlayerIndex)index;

/**
 用户停止播放的回调
 
 @param index 播放器序号
 */
- (void)onPlayStop:(ZegoMediaPlayerIndex)index;

/**
 网络音乐资源播放不畅，开始尝试缓存数据。
 
 @param index 播放器序号
 @warning 只有播放网络音乐资源才需要关注这个回调
 */
- (void)onBufferBegin:(ZegoMediaPlayerIndex)index;

/**
 网络音乐资源可以顺畅播放。
 
 @param index 播放器序号
 @warning 只有播放网络音乐资源才需要关注这个回调
 */
- (void)onBufferEnd:(ZegoMediaPlayerIndex)index;

/**
 快进到指定时刻
 
 @param code >=0 成功，其它表示失败
 @param millisecond 实际快进的进度，单位毫秒
 @param index 播放器序号
 */
- (void)onSeekComplete:(int)code when:(long)millisecond playerIndex:(ZegoMediaPlayerIndex)index;

/**
 截图
 
 @param image
 @param index 播放器序号
 */
- (void)onSnapshot:(ZEGOImage *)image playerIndex:(ZegoMediaPlayerIndex)index;

/**
 预加载完成
 
 @param index 播放器序号
 @warning 调用 load 的回调
 */
- (void)onLoadComplete:(ZegoMediaPlayerIndex)index;

/**
 播放进度回调
 
 @param timestamp 当前播放进度，单位毫秒
 @param index 播放器序号
 @note 同步回调，请不要在回调中处理数据或做其他耗时操作
 */
- (void)onProcessInterval:(long)timestamp playerIndex:(ZegoMediaPlayerIndex)index;

/**
 网络文件读完结尾的回调

@param index 播放器序号
 */
- (void)onReadEOF:(ZegoMediaPlayerIndex)index;

@end

/**
 多实例播放器的视频帧数据回调
 当格式为ARGB32/ABGR32/RGBA32/BGRA32，数据通过OnPlayVideoData回调。
 当格式为I420/NV12/NV21，数据通过OnPlayVideoData2回调。
 其他非法格式都判定为I420
 */
@protocol ZegoMediaPlayerVideoPlayWithIndexDelegate <NSObject>

@optional

/**
 视频帧数据回调, 格式为ARGB32/ABGR32/RGBA32/BGRA32
 
 @param data 视频帧原始数据
 @param size 视频帧原始数据大小
 @param format 视频帧原始数据格式
 @param index 播放器序号
 @note 同步回调，请不要在回调中处理数据或做其他耗时操作
 */
- (void)onPlayVideoData:(const char *)data size:(int)size format:(struct ZegoMediaPlayerVideoDataFormat)format playerIndex:(ZegoMediaPlayerIndex)index;

/**
 视频帧数据回调, 格式为I420/NV12/NV21
 
 @param data 视频帧原始数据
 @param size 视频帧原始数据大小
 @param format 视频帧原始数据格式
 @param index 播放器序号
 @note 同步回调，请不要在回调中处理数据或做其他耗时操作
 */
- (void)onPlayVideoData2:(const char **)data size:(int *)size format:(struct ZegoMediaPlayerVideoDataFormat)format playerIndex:(ZegoMediaPlayerIndex)index;

@end

@protocol ZegoMediaPlayerAudioPlayDelegate <NSObject>

/**
 音频数据回调，仅 PCM 数据有效

 @param data 音频原始数据
 @param length 音频数据大小
 @param sample_rate 采样率
 @param channels 通道数
 @param bit_depth 位深
 @param index 播放器序号
 @note 同步回调，SDK 会直接使用该段内存中的数据
 */
- (void) onPlayAudioData:(unsigned char * const)data length:(int)length sample_rate:(int)sample_rate channels:(int)channels bit_depth:(int)bit_depth playerIndex:(ZegoMediaPlayerIndex)index;

@end

/**
 播放器

 */
@interface ZegoMediaPlayer : NSObject


/**
 初始化

 @warning Deprecated，请使用 [initWithPlayerType:playerIndex:] 代替

 @param type @see MediaPlayerType
 @return 播放器对象
 @note sdk提供多个播放器实例，通过index可以指定获取的是哪个播放器实例，没有指定index时，取到的就是 ZegoMediaPlayerIndexIndexFirst 播放器
 */
- (instancetype)initWithPlayerType:(MediaPlayerType)type;

/**
 初始化
 
 @param type @see MediaPlayerType
 @param index sdk提供多个播放器实例，通过index可以指定获取的是哪个播放器实例 @see ZegoMediaPlayerIndex
 @return 播放器对象
 */
- (instancetype)initWithPlayerType:(MediaPlayerType)type playerIndex:(ZegoMediaPlayerIndex)index;

/**
 释放播放器
 */
- (void)uninit;

/**
 设置播放器事件回调
 
 @param delegate 回调
 */
- (void)setEventWithIndexDelegate:(id<ZegoMediaPlayerEventWithIndexDelegate>)delegate;


/**
 设置视频帧数据回调
 
 @param delegate 回调
 @param format 需要返回的视频帧数据格式，@see ZegoMediaPlayerVideoPixelFormat
 */
- (void)setVideoPlayWithIndexDelegate:(id<ZegoMediaPlayerVideoPlayWithIndexDelegate>)delegate format:(ZegoMediaPlayerVideoPixelFormat)format;


/**
 设置音频数据回调

 @param delegate 回调
 */
- (void)setAudioPlayDelegate:(id<ZegoMediaPlayerAudioPlayDelegate>)delegate;


/**
 开始播放
 
 @param path 媒体文件的路径
 @param repeat 是否重复播放
 */
- (void)start:(NSString *)path repeat:(BOOL)repeat;

/**
 停止播放
 */
- (void)stop;


/**
 暂停播放
 */
- (void)pause;


/**
 恢复播放
 */
- (void)resume;


/**
 设置指定的进度进行播放

 @param millisecond 指定的进度，单位毫秒
 */
- (void)seekTo:(long)millisecond;

/**
 设置是否开启精准搜索

 @param enable 是否开启
 @note: 播放文件之前调用，即Start或Load前，播放过程中调用不起作用，但可能对下个文件的播放起作用.
 */
- (void)enableAccurateSeek:(bool)enable;

/**
 设置精确搜索的超时时间

 @param timeoutInMS 超时时间, 单位毫秒. 有效值区间 [2000, 10000]
 @note 如果不设置, SDK 内部默认是设置 5000 毫秒
 */
- (void)setAccurateSeekTimeout:(long)timeoutInMS;

/**
 获取整个文件的播放时长

 @return 文件的播放时长，单位毫秒
 */
- (long)getDuration;


/**
 获取当前播放的进度

 @return 当前播放进度，单位毫秒
 */
- (long)getCurrentDuration;


/**
 设置本地静默播放
 
 @param mute 是否静默播放
 @warning 如果设置 MediaPlayerTypeAux 模式,推出的流是有声音的
 */
- (void)muteLocal:(BOOL)mute;


/**
 预加载资源
 
 @param path 媒体文件的路径
 */
- (void)load:(NSString *)path;

#if TARGET_OS_IPHONE

/**
 设置显示视频的view

 @param view 播放的控件
 */
- (void)setView:(UIView *)view;

#elif TARGET_OS_OSX

/**
 设置显示视频的view

 @param view 播放的控件
 */
- (void)setView:(NSView *)view;

#endif

/**
 设置本地播放音量, 如果播放器设置了推流模式, 也会设置推流音量

 @param volume 音量，范围在0到100，默认值是50
 */
- (void)setVolume:(int)volume;

/**
 设置推流音量
 
 @param volume 音量，范围在0到100，默认值是50
 */
- (void)setPublishVolume:(int)volume;

/**
 设置本地播放音量
 
 @param volume 音量，范围在0到100，默认值是50
 */
- (void)setPlayVolume:(int)volume;

/**
 获取推流音量
 */
- (int)getPublishVolume;

/**
 获取本地播放音量
 */
- (int)getPlayVolume;

/**
 设置播放文件的音轨
 
 @param streamIndex 音轨序号，可以通过 getAudioStreamCount 接口获取音轨个数
 */
- (long)setAudioStream:(long)streamIndex;

/**
 设置播放器类型
 
 @param type @see MediaPlayerType
 */
- (void)setPlayerType:(MediaPlayerType)type;

/**
 获取当前播放视频的截图

 @note 只有在调用 setView 设置了显示控件，以及播放状态的情况下，才能正常截图。
 */
- (void)takeSnapshot;

/**
 获取音轨个数
 
 @return 音轨个数
 */
- (long)getAudioStreamCount;

/**
 设置是否重复播放
 
 @param enable YES:重复播放，NO：不重复播放
 */
- (void)enableRepeatMode:(BOOL)enable;

/**
 设置播放进度回调间隔。
 
 @param interval 回调间隔，单位毫秒。有效值为大于等于 0。默认值为 0。
 
 @note 设置 interval 大于 0 时，就会收到 OnPlaybackProgress 回调。interval = 0 时，停止回调。
 @note 回调不会严格按照设定的回调间隔值返回，而是以处理音频帧或者视频帧的频率来判断是否需要回调。
 */
- (BOOL)setProcessInterval:(long)interval;

/**
 设置使用硬件解码
 
 @return 设置是否成功
 
 @note 当前只支持 iOS 系统
 @note 需要在加载媒体资源之前设置，即在 start 或者 load 之前
 @note 即使设置了使用硬件解码，引擎也会根据当前硬件情况决定是否使用
 @note 多次调用没有影响
 */
- (BOOL)requireHWDecoder;

/**
 设置播放器播放控件的显示模式

 @param mode 显示模式，详见 ZegoVideoViewMode，默认为 ZegoVideoViewModeScaleAspectFit
 */
- (void)setViewMode:(ZegoVideoViewMode)mode;

/**
 设置播放的背景颜色

 @param color 颜色,取值为0x00RRGGBB
 */
- (void)setBackgroundColor:(int)color;

/**
 清除播放控件播放结束后, 在控件上保留的最后一帧画面
 */
- (void)clearView;

/**
 设置播放声道
 
 @param channel 声道, 参见 ZegoMediaPlayerAudioChannel 定义. 播放器初始化时默认是 ZegoMediaPlayerAudioChannelAll
 */
- (void)setActiveAudioChannel:(ZegoMediaPlayerAudioChannel)channel;

/**
 设置声道音调
 
 @param channel 声道, 参见 ZegoMediaPlayerAudioChannel 定义
 @param value 音调偏移值, 有效值范围 [-8.0, 8.0], 播放器初始化时默认是 0
 @note 可选择设置左声道、右声道、左右声道，当只设置一个声道时，另一个声道保持原值
 */
- (void)setAudioChannel:(ZegoMediaPlayerAudioChannel)channel keyShift:(float)value;

/**
 设置网络素材最大的缓存时长和缓存数据大小, 以先达到者为准

 @param time 缓存最大时长, 单位 ms, 有效值为大于等于 2000, 如果填 0, 表示不限制
 @param size 缓存最大尺寸, 单位 byte, 有效值为大于等于 5000000, 如果填 0, 表示不限制
 @note 不允许 time 和 size 都为 0
 @note SDK 内部默认 timeInMS 为 5000, sizeInByte 为 15*1024*1024
 @note 在 start 或者 load 之前调用, 设置一次, 生命周期内一直有效
 */
- (void)setOnlineResourceCacheDuration:(int)time andSize:(int)size;

/**
 获取网络素材缓存队列的缓存数据可播放的时长和缓存数据大小
 @param time 缓存数据可播放的时长, 单位 ms
 @param size 缓存数据大小, 单位 byte
 @return true 调用成功, false 调用失败
 */
- (bool)getOnlineResourceCacheStat:(int*)time andSize:(int*)size;

/**
 设置缓冲回调的阈值, 缓冲区可播放时长大于阈值时，开始播放, 并回调 OnBufferEnd

 @param threshold  阈值, 单位 ms
 @note 在 Start 或者 Load 之前调用, 设置一次, 生命周期内一直有效
 @note SDK 默认值是 5000ms
 */
- (void)setBufferThreshold:(int)threshold;

/**
 设置加载资源的超时时间

 @param timeout 超时时间, 单位 ms, 有效值为大于等于 1000
 @note 在 start 或者 load 之前设置, 设置一次, 生命周期内一直有效
 @note 当打开文件超过设定超时时间，会失败并回调 onPlayError
 @note SDK 默认会一直等待
 */
- (void)setLoadResourceTimeout:(int)timeout;

@end

#endif /* zego_api_mediaplayer_oc_h */
