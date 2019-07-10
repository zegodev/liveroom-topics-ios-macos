//
//  ZGExternalVideoCaptureBaseSource.h
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/1/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoCapture

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZGExternalVideoCaptureDataReceiver <NSObject>
- (void)capturedData:(nonnull CVImageBufferRef)image presentationTimeStamp:(CMTime)time;
@end

@protocol ZGExternalVideoCaptureSourceDelegate <NSObject>
@property (nonatomic, weak) id<ZGExternalVideoCaptureDataReceiver> receiver;
- (BOOL)start;
- (void)stop;
@end


@interface ZGExternalVideoCaptureBaseSource : NSObject <ZGExternalVideoCaptureSourceDelegate>
@property (assign, nonatomic) BOOL isRunning;
@property (nonatomic, weak) id<ZGExternalVideoCaptureDataReceiver> receiver;
@end

NS_ASSUME_NONNULL_END

#endif
