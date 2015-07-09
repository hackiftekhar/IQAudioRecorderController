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
    
    BOOL recordingIsPrepared;
    
    NSString *oldSessionCategory;
}

- (instancetype)init
{
    if (self = [super init]) {
        // Unique recording URL
        NSString *fileName = [[NSProcessInfo processInfo] globallyUniqueString];
        _filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a",fileName]];
        
        oldSessionCategory = [[AVAudioSession sharedInstance] category];
        
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
            
            [self prepareForRecording];
        }

    }
    return self;
}

- (void)dealloc
{
    [audioRecorder stop];
    [audioPlayer stop];
    
    [[AVAudioSession sharedInstance] setCategory:oldSessionCategory error:nil];
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

// HINT: at the moment this overwrites the current recording -> create new recorder with different URL?
// HINT: this method is likely (and should) to be called on a background thread -> ensure thread safety
- (void)prepareForRecording
{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioRecorder prepareToRecord];
    recordingIsPrepared = YES;
}

- (void)startRecording
{
    if (!recordingIsPrepared) {
        [self prepareForRecording];
    }
    [audioRecorder record];
    recordingIsPrepared = NO;
}

- (void)stopRecording
{
    [audioRecorder stop];
}

- (void)discardRecording
{
    [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
    [self prepareForRecording];
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
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    recordingIsPrepared = NO;
    
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.filePath] error:nil];
    audioPlayer.delegate = self;
    audioPlayer.meteringEnabled = YES;
    [audioPlayer prepareToPlay];
    [audioPlayer play];
}

- (void)stopPlayback
{
    [audioPlayer stop];
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
