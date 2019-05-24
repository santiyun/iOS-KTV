//
//  KTVManager.m
//  Ktv
//
//  Created by Work on 2019/3/25.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "KTVManager.h"
#import <TTTPlayerKit/TTTPlayerKit.h>

@interface KTVManager ()<TTTPlayerDelegate>
@property (nonatomic, strong) TTTPlayer *player;
@end

@implementation KTVManager
static id _manager;
+ (instancetype)manager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
    });
    return _manager;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [super allocWithZone:zone];
    });
    return _manager;
}

- (id)copyWithZone:(NSZone *)zone
{
    return _manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //初始化TTTRtcEngineKit对象，输入申请的AppID
        _engine = [TTTRtcEngineKit sharedEngineWithAppId:@"test900572e02867fab8131651339518" delegate:nil];
    }
    return self;
}

#pragma mark - TTTPlayerKit
- (void)pullAudioData:(char *)data size:(int)size sampleRate:(int)sampleRate channels:(int)channels {
    [_player pullKTVAudioData:data size:size sampleRate:sampleRate channels:channels];
}

- (void)adjustAudioVolume:(int)volume {
    [_player adjustKTVVolume:volume];
}

- (void)playKTV:(NSURL *)url playView:(void (^)(UIView *))playView {
    _player = [TTTPlayer playerWithURL:url options:TTTPlayerOptions.defaultOptions];
    _player.delegate = self;
    //播放KTV必须调用该接口
    [_player prepareForKTV];
    if (playView) {
        playView(_player.playerView);
    }
}

- (void)play {
    [_player play];
}

- (void)pause {
    [_player pause];
}

- (void)resume {
    [_player resume];
}

- (void)stop {
    [_player stop];
    _player = nil;
}

- (void)seekTime:(NSTimeInterval)time {
    [_player seekTo:time];
}

- (NSTimeInterval)totalDuration {
    return self.player.totalDuration;
}

#pragma mark - TTTPlayerDelegate
//播放器状态变更
- (void)player:(TTTPlayer *)player statusDidChange:(TTTPlayerStatus)playerStatus {
    if ([_delegate respondsToSelector:@selector(ktvManager:ktvStatusChanged:)]) {
        [_delegate ktvManager:self ktvStatusChanged:playerStatus];
    }
}
//p播放停止
- (void)player:(TTTPlayer *)player stoppedWithError:(NSError *)error {
    if ([_delegate respondsToSelector:@selector(ktvManager:stoppedWithError:)]) {
        [_delegate ktvManager:self stoppedWithError:error];
    }
}

//KTV播放返回的视频yuv数据
-(void)player:(TTTPlayer *)player videoData:(NSData *)data width:(int)width height:(int)height {
    if (width == 0 || height == 0) { return; }
    TTTRtcVideoFrame *videoFrame = [[TTTRtcVideoFrame alloc] init];
    videoFrame.format = TTTRtc_VideoFrameFormat_I420;
    videoFrame.dataBuffer = data;
    videoFrame.strideInPixels = width;
    videoFrame.height = height;
    [_engine pushExternalVideoFrame:videoFrame];
}

//KTV播放返回的音频数据
- (void)player:(TTTPlayer *)player audioData:(NSData *)data {
    [_engine pushExternalAudioData:data];
}

@end
