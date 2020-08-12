# liveroom-topics-iOS/macOS

>国内用户推荐去码云下载，速度更快 [https://gitee.com/zegodev/liveroom-topics-ios-macos.git](https://gitee.com/zegodev/liveroom-topics-ios-macos.git)  

## Demo 使用指引
本 Demo 包含若个 Target。
- `LiveRoomPlayground-iOS`为 iOS 项目。
- `GameLive`是录屏进程程序。
- `GameLiveSetupUI`是 iOS11 以下录屏必须的录屏界面程序。
- `LiveRoomPlayground-macOS`是 macOS 项目。

由于 SDK 体积太大，现在 Demo 默认不再包含 SDK 文件，请先在[官网 SDK 下载页面](https://doc-zh.zego.im/zh/3134.html)下载 SDK 替换路径 src/libs/iOS 或者 src/libs/macOS 下的 ZegoLiveRoom.framework 或者 ZegoLiveRoomOSX.framework 文件


1.`ZGKeyCenter.m`中填写正确的 `appID` 和 `appSign`，若无，请在[即构管理控制台](https://console.zego.im/acount/register)申请。

2.如果需要体验外部滤镜，需要在`authpack.h`文件中填写正确的 faceUnity 的证书。

3.本Demo包含了`声浪（频率功率谱）`模块，若需要体验，把Demo中 `ModuleCompileDefine.h` 文件中 `_Module_SoundLevel` 宏打开，这样就可以在Demo首页的模块列表中出现`声浪/音频频谱`入口进行体验，如下处理：
```
#define _Module_SoundLevel @"声浪/音频频谱"
```

专题目录如下：
## 快速开始  
### [推流](/src/LiveRoomPlayground-iOS/PublishUI)  
### [拉流](/src/LiveRoomPlayground-iOS/PlayUI)  
## 常用功能
### [视频通话](/src/Topics/VideoTalk)
### [直播连麦](/src/Topics/JoinLive)
### [房间消息 iOS](/src/LiveRoomPlayground-iOS/RoomMessageUI)
## 进阶功能  
### [混流](/src/Topics/MixStream)
### [混音](/src/Topics/AudioAux)
### [声浪/音频频谱](/src/Topics/SoundLevel)
### [媒体播放器 iOS](/src/LiveRoomPlayground-iOS/MediaPlayerUI)
### [媒体播放器 Macos](/src/LiveRoomPlayground-macOS/MediaPlayerUI)
### [音效播放器 iOS](/src/LiveRoomPlayground-iOS/AudioPlayerUI)
### [媒体次要信息 iOS](/src/LiveRoomPlayground-iOS/MediaSideInfoUI)
### [媒体次要信息 Macos](/src/LiveRoomPlayground-macOS/MediaSideInfoUI)
### [分层视频编码](/src/Topics/SVC)
### [本地媒体录制](/src/Topics/MediaRecord)
### [视频外部渲染 iOS](/src/LiveRoomPlayground-iOS/ExternalVideoRenderUI)
### [视频外部渲染 Macos](/src/LiveRoomPlayground-macOS/ExternalVideoRender)  
### [视频外部采集 iOS](/src/LiveRoomPlayground-iOS/ExternalVideoCaptureUI)
### [视频外部采集 Macos](/src/LiveRoomPlayground-macOS/ExternalVideoCapture)
### [自定义前处理(faceUnity)](/src/Topics/ExternalVideoFilter)
### [变声、混响、立体声 iOS](/src/LiveRoomPlayground-iOS/AudioProcessingUI)

## ZEGO Support
Please visit [ZEGO Developer Center](https://www.zego.im/html/document/#Application_Scenes/Video_Live)



