//
//  IQAudioRecorder.m
//  IQAudioRecorderController Demo
//
//  Created by Sebastian Ludwig on 09.07.15.
//  Copyright (c) 2015 Iftekhar. All rights reserved.
//

#import "IQAudioRecorder.h"

@interface IQAudioRecorder () <AVAudioPlayerDelegate>

@end

@implementation IQAudioRecorder
{
    AVAudioRecorder *audioRecorder;
    AVAudioPlayer *audioPlayer;
    
    NSString *oldSessionCategory;
}

- (instancetype)init
{
    if (self = [super init]) {
        // Unique recording URL
        NSString *fileName = [[NSProcessInfo processInfo] globallyUniqueString];
        _filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a",fileName]];
        
        // Define the recorder setting
        {
            NSDictionary *recordSetting = @{AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                            AVSampleRateKey: @(44100.0),
                                            AVNumberOfChannelsKey: @(2)};
            
            // Initiate and prepare the recorder
            audioRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:_filePath]
                                                        settings:recordSetting
                                                           error:nil];
            audioRecorder.meteringEnabled = YES;
        }

    }
    return self;
}

- (void)dealloc
{
    [audioRecorder stop];
    [audioPlayer stop];
}

- (CGFloat)updateMeters
{
    if (audioRecorder.isRecording) {
        [audioRecorder updateMeters];
        
        CGFloat normalizedValue = pow(10, [audioRecorder averagePowerForChannel:0] / 20);
        return normalizedValue;
    }
    else if (audioPlayer.isPlaying) {
        [audioPlayer updateMeters];
        
        CGFloat normalizedValue = pow(10, [audioPlayer averagePowerForChannel:0] / 20);
        return normalizedValue;
    }
    return 0;
}

- (NSTimeInterval)currentTime
{
    if (self.isRecording) {
        return audioRecorder.currentTime;
    }
    
    return audioPlayer.currentTime;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    if (!self.isRecording) {
        audioPlayer.currentTime = currentTime;
    }
}

#pragma mark Recording

- (void)startRecording
{
    // TODO: do this beforehand
    oldSessionCategory = [[AVAudioSession sharedInstance] category];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioRecorder prepareToRecord];
    
    [audioRecorder record];
}

- (void)stopRecording
{
    [audioRecorder stop];
    [[AVAudioSession sharedInstance] setCategory:oldSessionCategory error:nil];
}

- (void)discardRecording
{
    [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
}

- (BOOL)isRecording
{
    return audioRecorder.isRecording;
}

#pragma mark Playback

- (NSTimeInterval)playbackDuration
{
    return audioPlayer.duration;
}

- (void)startPlayback
{
    // TODO: prevent playback while recording is running and vice versa
    
    oldSessionCategory = [[AVAudioSession sharedInstance] category];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.filePath] error:nil];
    audioPlayer.delegate = self;
    audioPlayer.meteringEnabled = YES;
    [audioPlayer prepareToPlay];
    [audioPlayer play];
}

- (void)stopPlayback
{
    [audioPlayer stop];
    [[AVAudioSession sharedInstance] setCategory:oldSessionCategory error:nil];
}

- (void)pausePlayback
{
    [audioPlayer pause];
}

- (void)resumePlayback
{
    [audioPlayer play];
}

- (BOOL)isPlaying
{
    return audioPlayer.isPlaying;
}

#pragma mark - AVAudioPlayerDelegate

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self.delegate audioRecorder:self didFinishPlaybackSuccessfully:flag];
}


@end
