# 在线KTV
在线KTV模式越来越受到大家的欢迎，在一个房间内，拿麦者可以自定义调节歌曲伴奏音量，或者进行切歌操作，房间内的多人同时可以进行实时语音聊天。

## 典型场景
用户A创建一个KTV房间，此时A用户就是房主，后续进入房间的角色都是观众，房主可以加载一个本地或在线的MV视频文件进行在线演唱，对房间有控制权

> 房主：
1. 创建KTV房间，点歌并开始演唱；
2. 房主关闭房间后，所有的用户退出房间；


# 功能列表

1. 创建 TTT 音频引擎对象 [sharedEngineWithAppId](http://3ttech.cn/index.php?menu=68&type=iOS#sharedEngineWithAppId)
2. 设置频道直播模式 [setChannelProfile](http://3ttech.cn/index.php?menu=68&type=iOS#setChannelProfile)
3. 设置用户角色 [setClientRole](http://3ttech.cn/index.php?menu=68&type=iOS#setClientRole)  麦上用户: BROADCASTER， 麦下用户: AUDIENCE
4. 启用说话音量提示 [enableAudioVolumeIndication](http://3ttech.cn/index.php?menu=68&type=iOS#enableAudioVolumeIndication)
5. 置视频编码属性（自定义） [setVideoProfile](http://3ttech.cn/index.php?menu=68&type=iOS#setVideoProfile)
6. 加入频道 [joinChannelByKey](http://3ttech.cn/index.php?menu=68&type=iOS#joinChannelByKey)
7. 离开频道 [leaveChannel](http://3ttech.cn/index.php?menu=68&type=iOS#leaveChannel)
8. 静音/取消静音，可选操作 [muteLocalAudioStream](http://3ttech.cn/index.php?menu=68&type=iOS#muteLocalAudioStream)
9. 禁用/启用本地视频功能 [enableLocalVideo](http://3ttech.cn/index.php?menu=68&type=iOS#enableLocalVideo)
10. 配置外部视频源 [setExternalVideoSource](http://3ttech.cn/index.php?menu=68&type=iOS#setExternalVideoSource)
11. 推送外部视频帧 [pushExternalVideoFrame](http://3ttech.cn/index.php?menu=68&type=iOS#pushExternalVideoFrame)
12. 推送外部音频数据 **pushExternalAudioData**参考SDK

# 重要接口
1. **setExternalVideoSource** KTV模式在加入房间之前必须启用该接口
2. **pushExternalVideoFrame** 推送TTTPlayerKit回调的视频数据
3. **-(void)rtcEngine:(TTTRtcEngineKit *)engine pullAudioData:(char *)data size:(int)size sampleRate:(NSUInteger)sampleRate channels:(int)channels** 实现**TTTRtcEngineDelegate**回调，在回调里面拉取TTTPlayerKit里音频数据，在**TTTPlayerDelegate**KTV音频数据回调里面 推送外部音频数据**pushExternalAudioData**
4. TTTPlayerKit相关使用封装在**KTVManager**，接口使用参考demo


# 示例程序

#### 准备工作
1. 请使用TTTLib目录下的两个Framework库
2. 登录三体云官网 [http://dashboard.3ttech.cn/index/login](http://dashboard.3ttech.cn/index/login) 注册体验账号，进入控制台新建自己的应用并获取APPID。

## iOS工程配置

SDK包含**TTTRtcEngineVoiceKit.framework**和**TTTPlayerKit.framework** 

**两个framework只支持真机，不支持模拟器**

 在**KTVManager.m**目录下填写申请的AppID

工程已做如下配置，直接运行工程

1. 设置Bitcode为NO
2. 设置后台音频模式
3. 导入系统库

* libxml2.tbd
* libc++.tbd
* libz.tbd
* libsqlite3.tbd
* ReplayKit.framework
* CoreTelephony.framework
* SystemConfiguration.framework


# 常见问题
1. 由于部分模拟器会存在功能缺失或者性能问题，所以 SDK 不支持模拟器的使用。
2. 注意Xcode调试状态在部分系统出现卡住主线程几秒的现象，不在调试状态，Release包不会出现这个现象
