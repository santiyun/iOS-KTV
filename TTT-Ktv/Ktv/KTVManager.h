//
//  KTVManager.h
//  Ktv
//
//  Created by Work on 2019/3/25.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TTTRtcEngineKit/TTTRtcEngineKit.h>
#import <TTTPlayerKit/TTTPlayerKit.h>


@protocol KTVPlayDelegate;
@interface KTVManager : NSObject

@property (nonatomic, strong) TTTRtcEngineKit *engine;
@property (nonatomic, weak) id<KTVPlayDelegate> delegate;
@property (nonatomic) int64_t roomId;
@property (nonatomic) int64_t uid;
@property (nonatomic) TTTRtcClientRole role;

+ (instancetype)manager;

#pragma mark - Play KTV
- (void)playKTV:(NSURL *)url playView:(void (^)(UIView *view))playView;
- (void)play;
- (void)pause;
- (void)resume;
- (void)stop;
- (void)adjustAudioVolume:(int)volume;
- (void)pullAudioData:(char *)data size:(int)size sampleRate:(int)sampleRate channels:(int)channels;

- (NSTimeInterval)totalDuration;
- (void)seekTime:(NSTimeInterval)time;

@end

@protocol KTVPlayDelegate <NSObject>

- (void)ktvManager:(KTVManager *)manager ktvStatusChanged:(TTTPlayerStatus)status;
- (void)ktvManager:(KTVManager *)manager stoppedWithError:(NSError *)error;

@end
