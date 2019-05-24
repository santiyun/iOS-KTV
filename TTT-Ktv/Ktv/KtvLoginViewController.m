//
//  KtvLoginViewController.m
//  Ktv
//
//  Created by Work on 2019/3/25.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "KtvLoginViewController.h"
#import <TTTRtcEngineKit/TTTRtcEngineKit.h>
#import "TTProgressHud.h"
#import "UIView+Toast.h"
#import "KTVManager.h"

@interface KtvLoginViewController ()<TTTRtcEngineDelegate>
@property (weak, nonatomic) IBOutlet UIButton *anchorBtn;//主播按钮
@property (weak, nonatomic) IBOutlet UITextField *roomIDTF;
@property (nonatomic, strong) UIButton *roleSelectedBtn; //当前选中的角色Button
@property (nonatomic) int64_t uid;
@end

@implementation KtvLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _roleSelectedBtn = _anchorBtn;
    _uid = arc4random() % 100000 + 1;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *rid = [ud stringForKey:@"T3_KTV_ROOMID"];
    if (rid.longLongValue <= 0) {
        int64_t rid_int = arc4random() % 100000 + 1;
        rid = [NSString stringWithFormat:@"%lld", rid_int];
    }
    _roomIDTF.text = rid;
    
}

- (IBAction)roleBtnAction:(UIButton *)sender {
    if (sender.isSelected) { return; }
    _roleSelectedBtn.selected = NO;
    _roleSelectedBtn.backgroundColor = UIColor.blackColor;
    sender.selected = YES;
    sender.backgroundColor = UIColor.cyanColor;
    _roleSelectedBtn = sender;
}

- (IBAction)enterChannel:(UIButton *)sender {
    if (_roomIDTF.text.length == 0) {
        [self showToast:@"请输入19位以内的房间ID"];//可转换为大于0小于long long类型的数字
        return;
    }
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setValue:_roomIDTF.text forKey:@"T3_KTV_ROOMID"];
    [ud synchronize];
    [TTProgressHud showHud:self.view];
    
    TTTRtcClientRole role = _roleSelectedBtn.tag - 100;
    KTVManager.manager.role = role;
    //设置代理
    KTVManager.manager.engine.delegate = self;
    //设置为直播模式
    [KTVManager.manager.engine setChannelProfile:TTTRtc_ChannelProfile_LiveBroadcasting];
    //设置用户角色
    [KTVManager.manager.engine setClientRole:role];
    //请用说话者音量提示--不关注用户音量可以不调用该接口
    [KTVManager.manager.engine enableAudioVolumeIndication:1000 smooth:3];
    if (role == TTTRtc_ClientRole_Anchor) {
        //KTV 使用外部视频源
        [KTVManager.manager.engine setExternalVideoSource:YES useTexture:NO];
        //启用本地视频，默认启用...  关闭之后,需要开启
        [KTVManager.manager.engine enableLocalVideo:YES];
        //把本地音频状态设置为开启
        [KTVManager.manager.engine muteLocalAudioStream:NO];
        //建议设置和KTV视频尺寸一致
        [KTVManager.manager.engine setVideoProfile:CGSizeMake(648, 480) frameRate:15 bitRate:600];
        
        //设置推流--可选操作
        TTTPublisherConfigurationBuilder *builder = [[TTTPublisherConfigurationBuilder alloc] init];
        NSString *pushUrl = [@"rtmp://push.3ttech.cn/sdk/" stringByAppendingString:_roomIDTF.text];
        [builder setPublisherUrl:pushUrl];
        [KTVManager.manager.engine configPublisher:builder.build];
    } else if (role == TTTRtc_ClientRole_Broadcaster) {
        //副播不用视频，只需要声音
        [KTVManager.manager.engine enableLocalVideo:NO];
    } else {
        //把本地音频状态设置为关闭
        [KTVManager.manager.engine muteLocalAudioStream:YES];
        //观众不用视频，只能看视频、听声音
        [KTVManager.manager.engine enableLocalVideo:NO];
    }
    KTVManager.manager.roomId = _roomIDTF.text;
    KTVManager.manager.uid = _uid;
    [KTVManager.manager.engine joinChannelByKey:nil channelName:_roomIDTF.text uid:_uid joinSuccess:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [_roomIDTF resignFirstResponder];
}

#pragma mark - TTTRtcEngineDelegate
//加入频道成功，进入PK页面
-(void)rtcEngine:(TTTRtcEngineKit *)engine didJoinChannel:(NSString *)channel withUid:(int64_t)uid elapsed:(NSInteger)elapsed {
    [TTProgressHud hideHud:self.view];
    [self performSegueWithIdentifier:@"KTV" sender:nil];
}

//加入频道出现错误
-(void)rtcEngine:(TTTRtcEngineKit *)engine didOccurError:(TTTRtcErrorCode)errorCode {
    NSString *errorInfo = @"";
    switch (errorCode) {
        case TTTRtc_Error_Enter_TimeOut:
            errorInfo = @"超时,10秒未收到服务器返回结果";
            break;
        case TTTRtc_Error_Enter_Failed:
            errorInfo = @"无法连接服务器";
            break;
        case TTTRtc_Error_Enter_BadVersion:
            errorInfo = @"版本错误";
            break;
        case TTTRtc_Error_InvalidChannelName:
            errorInfo = @"Invalid channel name";
            break;
        case TTTRtc_Error_Enter_NoAnchor:
            errorInfo = @"房间内无主播";
            break;
        default:
            errorInfo = [NSString stringWithFormat:@"未知错误：%zd",errorCode];
            break;
    }
    [TTProgressHud hideHud:self.view];
    [self showToast:errorInfo];
}
@end
