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
    AudioFormatID formatID;
    NSString *fileNameExtension;
    
    AVAudioRecorder *audioRecorder;
    AVAudioPlayer *audioPlayer;
    
    BOOL recordingIsPrepared;
    
    NSString *oldSessionCategory;
}

- (instancetype)init
{
    if (self = [super init]) {
        formatID = kAudioFormatMPEG4AAC;
        fileNameExtension = @"m4a";
        
        self.format = @"aac";
        self.sampleRate = 44100;
        self.channels = 2;
    }
    return self;
}

- (instancetype)initWithFormat:(AudioFormatID)format sampleRate:(CGFloat)sampleRate numberOfChannels:(int)channels
{
    if (self = [self init]) {
        formatID = format;
        self.sampleRate = sampleRate;
        self.channels = channels;
    }
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)setup
{
    if ([self.format isEqualToString:@"mp3"]) {
        formatID = kAudioFormatMPEGLayer3;
        fileNameExtension = @"mp3";
    }
    
    NSString *fileName = [[NSProcessInfo processInfo] globallyUniqueString];
    _filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", fileName, fileNameExtension]];
    
    oldSessionCategory = [[AVAudioSession sharedInstance] category];
    
    NSDictionary *recordSetting = @{AVFormatIDKey: @(formatID),
                                    AVSampleRateKey: @(self.sampleRate),
                                    AVNumberOfChannelsKey: @(self.channels)};
    
    // Initiate and prepare the recorder
    audioRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:_filePath]
                                                settings:recordSetting
                                                   error:nil];
    audioRecorder.meteringEnabled = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self prepareForRecording];
    });
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
- (void)prepareForRecording
{
    @synchronized(self) {
        if (recordingIsPrepared) {
            return;
        }
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
        [audioRecorder prepareToRecord];
        recordingIsPrepared = YES;
    }
}

- (void)startRecording
{
    [self prepareForRecording];

    [audioRecorder record];
    
    @synchronized(self) {
        recordingIsPrepared = NO;
    }
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
    
    @synchronized(self) {
        recordingIsPrepared = NO;
    }
    
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
    if ([self.delegate respondsToSelector:@selector(audioRecorder:didFinishPlaybackSuccessfully:)]) {
        [self.delegate audioRecorder:self didFinishPlaybackSuccessfully:flag];
    }
}


@end
