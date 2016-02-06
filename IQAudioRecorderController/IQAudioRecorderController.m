//
//  IQAudioRecorderController.m
//  IQAudioRecorderController Demo
//
//  Created by Sebastian Ludwig on 05.02.16.
//  Copyright © 2016 Iftekhar. All rights reserved.
//

#import "IQAudioRecorderController.h"

#import "IQAudioRecorder.h"

@interface IQAudioRecorderController () <IQAudioRecorderDelegate, IQPlaybackDurationViewDelegate>

@end

@implementation IQAudioRecorderController
{
    BOOL wasPlaying;
    IQAudioRecorder *recorder;
    
    CADisplayLink *waveformUpdateDisplayLink;
    CADisplayLink *playProgressDisplayLink;
}

- (instancetype)init
{
    if (self = [super init]) {
        recorder = [[IQAudioRecorder alloc] init];
        recorder.delegate = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [recorder prepareForRecording];
        });
        
        self.normalTintColor = [UIColor whiteColor];
        self.recordingTintColor = [UIColor colorWithRed:0.0/255.0 green:128.0/255.0 blue:255.0/255.0 alpha:1.0];
        self.playingTintColor = [UIColor colorWithRed:255.0/255.0 green:64.0/255.0 blue:64.0/255.0 alpha:1.0];
    }
    return self;
}

- (void)awakeFromNib
{
    [self preparePlaybackDurationview];
}

- (void)setPlaybackDurationView:(IQPlaybackDurationView *)playbackDurationView
{
    _playbackDurationView = playbackDurationView;
    
    [self preparePlaybackDurationview];
}

- (BOOL)isRecording
{
    return recorder.isRecording;
}

- (NSString *)recordedFilePath
{
    return [recorder filePath];
}

- (void)startUpdatingWaveformView
{
    [waveformUpdateDisplayLink invalidate];
    waveformUpdateDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateWaveform)];
    [waveformUpdateDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    // TODO: this should probably go somewhere else
    [self setObjects:@[self.playButton, self.pauseButton, self.trashButton] enabled:NO];
}

- (void)stopUpdatingWaveformView
{
    [waveformUpdateDisplayLink invalidate];
}

- (void)startRecording
{
    [recorder startRecording];
    
    [self setObjects:@[self.playButton, self.pauseButton, self.trashButton] enabled:NO];
}

- (void)stopRecording
{
    [recorder stopRecording];
    
    [self setObjects:@[self.playButton, self.pauseButton, self.trashButton] enabled:YES];
}

- (void)discardRecording
{
    [recorder discardRecording];
    
    [self setObjects:@[self.playButton, self.pauseButton, self.trashButton] enabled:NO];
}

- (void)startPlayback
{
    [recorder startPlayback];
    
    [self.playbackDurationView setDuration:recorder.playbackDuration];
    [self.playbackDurationView setCurrentTime:recorder.currentTime];
    
    [playProgressDisplayLink invalidate];
    playProgressDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updatePlaybackProgress)];
    [playProgressDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    
    [self setObjects:@[self.recordButton, self.playButton, self.trashButton] enabled:NO];
    [self setObjects:@[self.pauseButton] enabled:YES];
}

- (void)stopPlayback
{
    [playProgressDisplayLink invalidate];
    
    [recorder stopPlayback];    // TODO: no reason to stop - pause shoud do the trick (+rewind)
    
    [self setObjects:@[self.recordButton, self.playButton, self.trashButton] enabled:YES];
    [self setObjects:@[self.pauseButton] enabled:NO];
}

#pragma mark Private methods

- (void)updateWaveform
{
    if (recorder.isRecording || recorder.isPlaying) {
        [self.waveformView updateWithLevel:[recorder updateMeters]];
        
        if (recorder.isRecording) {
            self.waveformView.waveColor = self.recordingTintColor;
            if ([self.delegate respondsToSelector:@selector(audioRecorderController:didRecordTimeInterval:)]) {
                [self.delegate audioRecorderController:self didRecordTimeInterval:recorder.currentTime];
            }
        } else {
            self.waveformView.waveColor = self.playingTintColor;
        }
    } else {
        [self.waveformView setWaveColor:self.normalTintColor];
        [self.waveformView updateWithLevel:0];
    }
}

- (void)updatePlaybackProgress
{
    [self.playbackDurationView setCurrentTime:recorder.currentTime animated:YES];
}

- (void)preparePlaybackDurationview
{
    self.playbackDurationView.delegate = self;
    self.playbackDurationView.textColor = self.normalTintColor;
    self.playbackDurationView.sliderTintColor = self.playingTintColor;
}

- (void)setObjects:(NSArray *)objects enabled:(BOOL)enabled
{
    for (id object in objects) {
        if ([object respondsToSelector:@selector(setEnabled:)]) {
            [object setEnabled:enabled];
        }
    }
}

#pragma mark - IQAudioRecorderDelegate

- (void)audioRecorder:(IQAudioRecorder *)recorder didFinishPlaybackSuccessfully:(BOOL)successfully
{
    if ([self.delegate respondsToSelector:@selector(audioRecorderControllerDidFinishPlayback:)]) {
        [self.delegate audioRecorderControllerDidFinishPlayback:self];
    }
}

#pragma mark - IQPlaybackDurationViewDelegate

- (void)playbackDurationView:(IQPlaybackDurationView *)playbackView didStartScrubbingAtTime:(NSTimeInterval)time
{
    wasPlaying = recorder.isPlaying;
    
    if (recorder.isPlaying) {
        [recorder pausePlayback];
    }
}

- (void)playbackDurationView:(IQPlaybackDurationView *)playbackView didScrubToTime:(NSTimeInterval)time
{
    recorder.currentTime = time;
}

- (void)playbackDurationView:(IQPlaybackDurationView *)playbackView didEndScrubbingAtTime:(NSTimeInterval)time
{
    recorder.currentTime = time;
    
    if (wasPlaying) {
        [recorder resumePlayback];
    }
}

@end
