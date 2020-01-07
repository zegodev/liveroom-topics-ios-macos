
# liveroom-topics-iOS/macOS

>国内用户推荐去码云下载，速度更快 [https://gitee.com/zegodev/liveroom-topics-ios-macos.git](https://gitee.com/zegodev/liveroom-topics-ios-macos.git)  

## Demo 使用指引
本 Demo 包含若个 Target。
- `LiveRoomPlayground-iOS`为 iOS 项目。
- `GameLive`是录屏进程程序。
- `GameLiveSetupUI`是 iOS11 以下录屏必须的录屏界面程序。
- `LiveRoomPlayground-macOS`是 macOS 项目。

1.项目代码没有包含 Zego SDK，需要下载相应的 SDK，引入到项目，才能运行项目。
- 若需要运行 `LiveRoomPlayground-iOS`，请下载 [iOS SDK](https://storage.zego.im/downloads/ZegoLiveRoom-MediaPlayer-iOS.zip)，解压得到 `ZegoLiveRoom.framework`，然后放入 `src/libs/iOS` 目录。
- 若需要运行 `LiveRoomPlayground-macOS`，请下载 [macOS SDK](https://storage.zego.im/downloads/ZegoLiveRoom-MediaPlayer-MacOS-OC.zip)，解压得到 `ZegoLiveRoom.framework`，然后放入 `src/libs/macOS` 目录。

> iOS SDK 包含真机版（iphoneos）和真机+模拟器混合版（iphoneos_simulator），请选择合适的版本，但在导出包时，请确保使用真机版，否则打包会报错。


2.`ZGKeyCenter.m`中填写正确的 `appID` 和 `appSign`，若无，请在[即构管理控制台](https://console.zego.im/acount/register)申请。

3.如果需要体验外部滤镜，需要在`authpack.h`文件中填写正确的 faceUnity 的证书。

4.因为下载的 SDK 不包含`声浪/音频频谱`模块，使用 Demo 时请把 `ModuleCompileDefine.h` 文件中的相关模块宏定义注释掉，否则会编译不过。如下处理：
```
// #define _Module_SoundLevel @"声浪/音频频谱"
```

专题目录如下：
## 快速开始  
### [推流](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/Topics/Common)  
### [拉流](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/Topics/Common)  
## 常用功能
### [视频通话](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/Topics/VideoTalk)
### [直播连麦](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/Topics/JoinLive)
### [房间消息 iOS](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/LiveRoomPlayground-iOS/RoomMessageUI)
## 进阶功能  
### [混流](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/Topics/MixStream)
### [混音](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/Topics/AudioAux)
### [声浪/音频频谱](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/Topics/SoundLevel)
### [媒体播放器 iOS](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/LiveRoomPlayground-iOS/MediaPlayerUI)
### [媒体播放器 Macos](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/LiveRoomPlayground-macOS/MediaPlayerUI)
### [媒体次要信息 iOS](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/LiveRoomPlayground-iOS/MediaSideInfoUI)
### [媒体次要信息 Macos](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/LiveRoomPlayground-macOS/MediaSideInfoUI)
### [分层视频编码](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/Topics/SVC)
### [本地媒体录制](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/Topics/MediaRecord)
### [视频外部渲染 iOS](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/LiveRoomPlayground-iOS/ExternalVideoRenderUI)
### [视频外部渲染 Macos](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/LiveRoomPlayground-macOS/ExternalVideoRender)  
### [视频外部采集 iOS](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/LiveRoomPlayground-iOS/ExternalVideoCaptureUI)
### [视频外部采集 Macos](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/LiveRoomPlayground-macOS/ExternalVideoCapture)
### [自定义前处理(faceUnity)](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/Topics/ExternalVideoFilter)
### [变声、混响、立体声 iOS](https://github.com/zegodev/liveroom-topics-ios-macos/tree/master/src/LiveRoomPlayground-iOS/AudioProcessingUI)

## ZEGO Support
Please visit [ZEGO Developer Center](https://www.zego.im/html/document/#Application_Scenes/Video_Live)
