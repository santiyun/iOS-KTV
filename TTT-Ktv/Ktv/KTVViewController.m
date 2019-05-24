//
//  KTVViewController.m
//  Ktv
//
//  Created by Work on 2019/3/25.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "KTVViewController.h"
#import <TTTRtcEngineKit/TTTRtcEngineKit.h>
#import <TTTPlayerKit/TTTPlayerKit.h>
#import "KTVManager.h"
#import "TTProgressHud.h"
#import "UIView+Toast.h"

#define SWDITH UIScreen.mainScreen.bounds.size.width

@interface KTVViewController ()<KTVPlayDelegate, TTTRtcEngineDelegate>
@property (weak, nonatomic) IBOutlet UIView *playBackView;
@property (weak, nonatomic) IBOutlet UIImageView *videoPlayer;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIView *anchorView;
@property (weak, nonatomic) IBOutlet UISlider *audioMixSlider;
@property (weak, nonatomic) IBOutlet UISlider *localSlider;
@property (weak, nonatomic) IBOutlet UIButton *changeRoleBtn;
@property (weak, nonatomic) IBOutlet UIButton *muteSelfBtn;
@property (weak, nonatomic) IBOutlet UILabel *audioStatsLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoStatsLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *uidLabel;

@property (nonatomic, strong) NSURL *ktvUrl;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) int64_t anchorUid;
@property (nonatomic) TTTPlayerStatus status;
@end

@implementation KTVViewController {
    FILE *_file;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _ktvUrl = [NSBundle.mainBundle URLForResource:@"1080.mp4" withExtension:nil];
    _roomIDLabel.text = [NSString stringWithFormat:@"房间Id: %@", KTVManager.manager.roomId];
    _uidLabel.text = [NSString stringWithFormat:@"用户Id: %lld", KTVManager.manager.uid];
    KTVManager.manager.engine.delegate = self;
    KTVManager.manager.delegate = self;
    if (KTVManager.manager.role == TTTRtc_ClientRole_Anchor) {
        _changeRoleBtn.hidden = YES;
    } else if (KTVManager.manager.role == TTTRtc_ClientRole_Audience) {
        _muteSelfBtn.hidden = YES;
        _anchorView.hidden = YES;
        _playBtn.hidden = YES;
    }
}

- (IBAction)playOrPauseKTV:(UIButton *)sender {
    if (sender.isSelected) {//暂停播放
        [KTVManager.manager pause];
    } else {//处于暂停状态就恢复播放...没有播放就开始播放
        //没有播放的状态就去播放歌曲，暂停状态就恢复播放
        if (_isPlaying) {
            [KTVManager.manager resume];
        } else {
            [KTVManager.manager playKTV:_ktvUrl playView:^(UIView *view) {
                CGFloat width = SWDITH - 20;
                view.frame = CGRectMake(0, 0, width, width / 4 * 3);
                [self.playBackView insertSubview:view belowSubview:self.playBtn];
            }];
            //注意Xcode调试状态在部分系统出现卡住主线程几秒的现象===不在调试状态，Release包不会出现这个现象
            [KTVManager.manager play];
            _isPlaying = YES;
        }
    }
    sender.selected = !sender.isSelected;
}

- (IBAction)changeSong:(UIButton *)sender {
    if (_isPlaying) {//切歌的时候需要注意先停止原来的播放，再播放下一个
        _isPlaying = NO;
        _playBtn.selected = NO;
        [KTVManager.manager stop];
    }
    if ([self.ktvUrl.absoluteString isEqualToString:@"http://39.107.116.40/res/tpl/default/file/guoke.mp4"]) {
        _ktvUrl = [NSBundle.mainBundle URLForResource:@"1080.mp4" withExtension:nil];
    } else {
        self.ktvUrl = [NSURL URLWithString:@"http://39.107.116.40/res/tpl/default/file/guoke.mp4"];
    }
    //切歌时建议延2秒重新打开新的KTV
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self playOrPauseKTV:self.playBtn];
    });
}

//调节KTV播放的音量
- (IBAction)audioMixSliderAction:(UISlider *)sender {
    [KTVManager.manager adjustAudioVolume:sender.value];
}
//调节本地唱歌的音量
- (IBAction)localSliderAction:(UISlider *)sender {
    [KTVManager.manager.engine adjustAudioMixingSoloVolume:sender.value];
}

- (IBAction)changeRole:(UIButton *)sender {
    if (sender.isSelected) {//副播切观众
        [KTVManager.manager.engine setClientRole:TTTRtc_ClientRole_Audience];
        [KTVManager.manager.engine muteLocalAudioStream:YES];
        _muteSelfBtn.selected = NO;
        _muteSelfBtn.hidden = YES;
    } else {//观众切副播
        [KTVManager.manager.engine setClientRole:TTTRtc_ClientRole_Broadcaster];
        [KTVManager.manager.engine muteLocalAudioStream:NO];
        [KTVManager.manager.engine enableLocalVideo:NO];
        _muteSelfBtn.selected = NO;
        _muteSelfBtn.hidden = NO;
    }
    sender.selected = !sender.isSelected;
}

//对自己做开启/关闭静音操作
- (IBAction)muteLocalAudio:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    [KTVManager.manager.engine muteLocalAudioStream:sender.isSelected];
}
///离开房间
- (IBAction)leaveChannel:(id)sender {
    if (_isPlaying) {
        [KTVManager.manager stop];
    }
    [KTVManager.manager.engine leaveChannel:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - TTTRtcEngineDelegate
//用户加入房间
-(void)rtcEngine:(TTTRtcEngineKit *)engine didJoinedOfUid:(int64_t)uid clientRole:(TTTRtcClientRole)clientRole isVideoEnabled:(BOOL)isVideoEnabled elapsed:(NSInteger)elapsed {
    if (clientRole == TTTRtc_ClientRole_Anchor) {
        TTTRtcVideoCanvas *videoCanvas = [[TTTRtcVideoCanvas alloc] init];
        videoCanvas.uid = uid;
        videoCanvas.view = _videoPlayer;
        videoCanvas.renderMode = TTTRtc_Render_Hidden;
        [engine setupRemoteVideo:videoCanvas];
        _anchorUid = uid;
    }
}

//KTV时需要通过ijk获取相关参数的音频数据
-(void)rtcEngine:(TTTRtcEngineKit *)engine pullAudioData:(char *)data size:(int)size sampleRate:(NSUInteger)sampleRate channels:(int)channels {
    //注意正在播放时才能去拉取音频数据
    if (_status == TTTPlayerStatusPlaying) {
        [KTVManager.manager pullAudioData:data size:size sampleRate:(int)sampleRate channels:channels];
    }
}

- (void)rtcEngine:(TTTRtcEngineKit *)engine reportRtcStats:(TTTRtcStats *)stats {
    if (KTVManager.manager.role == TTTRtc_ClientRole_Anchor) {
        _audioStatsLabel.text = [NSString stringWithFormat:@"A-↑%ldkbps", stats.txAudioKBitrate];
        _videoStatsLabel.text = [NSString stringWithFormat:@"V-↑%ldkbps", stats.txVideoKBitrate];
    }
}

- (void)rtcEngine:(TTTRtcEngineKit *)engine remoteAudioStats:(TTTRtcRemoteAudioStats *)stats {
    //只关注主播
    if (stats.uid == _anchorUid) {
        _audioStatsLabel.text = [NSString stringWithFormat:@"A-↓%ldkbps", stats.receivedBitrate];
    }
}

- (void)rtcEngine:(TTTRtcEngineKit *)engine remoteVideoStats:(TTTRtcRemoteVideoStats *)stats {
    //只关注主播
    if (stats.uid == _anchorUid) {
        _videoStatsLabel.text = [NSString stringWithFormat:@"V-↓%ldkbps", stats.receivedBitrate];
    }
}
//网络链接丢失，会自动重连
- (void)rtcEngineConnectionDidLost:(TTTRtcEngineKit *)engine {
    [TTProgressHud showHud:self.view message:@"网络链接丢失，正在重连..."];
}

//重连失败，需要退出房间
- (void)rtcEngineReconnectServerTimeout:(TTTRtcEngineKit *)engine {
    [TTProgressHud hideHud:self.view];
    [self.view.window showToast:@"网络丢失，请检查网络"];
    [engine leaveChannel:nil];
    if (_isPlaying) {
        [KTVManager.manager stop];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
//重连成功
- (void)rtcEngineReconnectServerSucceed:(TTTRtcEngineKit *)engine {
    [TTProgressHud hideHud:self.view];
}

//房间内被踢出
- (void)rtcEngine:(TTTRtcEngineKit *)engine didKickedOutOfUid:(int64_t)uid reason:(TTTRtcKickedOutReason)reason {
    NSString *errorInfo = @"";
    switch (reason) {
        case TTTRtc_KickedOut_KickedByHost:
            errorInfo = @"被主播踢出";
            break;
        case TTTRtc_KickedOut_PushRtmpFailed:
            errorInfo = @"rtmp推流失败";
            break;
        case TTTRtc_KickedOut_MasterExit:
            errorInfo = @"主播已退出";
            break;
        case TTTRtc_KickedOut_ReLogin:
            errorInfo = @"重复登录";
            break;
        case TTTRtc_KickedOut_NewChairEnter:
            errorInfo = @"其他人以主播身份进入";
            break;
        default:
            errorInfo = @"未知错误";
            break;
    }
    [self.view.window showToast:errorInfo];
    [engine leaveChannel:nil];
    if (_isPlaying) {
        [KTVManager.manager stop];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - KTVPlayDelegate
- (void)ktvManager:(KTVManager *)manager ktvStatusChanged:(TTTPlayerStatus)status {
    _status = status;
    if (status == TTTPlayerStatusStopped) {//播放结束
        _playBtn.selected = NO;
        _isPlaying = NO;
        [KTVManager.manager stop];
    }
}

- (void)ktvManager:(KTVManager *)manager stoppedWithError:(NSError *)error {
    
}

@end
