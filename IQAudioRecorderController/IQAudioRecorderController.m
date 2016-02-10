//
//  IQAudioRecorderController.m
//  IQAudioRecorderController Demo
//
//  Created by Sebastian Ludwig on 05.02.16.
//  Copyright © 2016 Iftekhar. All rights reserved.
//

#import "IQAudioRecorderController.h"


@interface IQAudioRecorderController () <IQPlaybackDurationViewDelegate>

@end

@implementation IQAudioRecorderController
{
    BOOL wasPlaying;
    
    CADisplayLink *waveformUpdateDisplayLink;
    CADisplayLink *playProgressDisplayLink;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.normalTintColor = [UIColor whiteColor];
        self.recordingTintColor = [UIColor colorWithRed:0.0/255.0 green:128.0/255.0 blue:255.0/255.0 alpha:1.0];
        self.playingTintColor = [UIColor colorWithRed:255.0/255.0 green:64.0/255.0 blue:64.0/255.0 alpha:1.0];
    }
    return self;
}

- (void)awakeFromNib
{
    [self preparePlaybackDurationview];
    
    if (!self.recorder) {
        self.recorder = [[IQAudioRecorder alloc] init];
        self.recorder.delegate = self;
        [self.recorder setup];
    }
}

- (void)setPlaybackDurationView:(IQPlaybackDurationView *)playbackDurationView
{
    _playbackDurationView = playbackDurationView;
    
    [self preparePlaybackDurationview];
}

- (BOOL)isRecording
{
    return self.recorder.isRecording;
}

- (NSString *)recordedFilePath
{
    return [self.recorder filePath];
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
    [self.recorder startRecording];
    
    self.playbackDurationView.duration = 0;
    self.playbackDurationView.currentTime = 0;
    
    [self setObjects:@[self.playButton, self.pauseButton, self.trashButton] enabled:NO];
}

- (void)stopRecording
{
    [self.recorder stopRecording];
    
    [self setObjects:@[self.playButton, self.trashButton] enabled:YES];
    [self setObjects:@[self.pauseButton] enabled:NO];
}

- (void)discardRecording
{
    [self.recorder discardRecording];
    
    self.playbackDurationView.duration = 0;
    self.playbackDurationView.currentTime = 0;
    
    [self setObjects:@[self.playButton, self.trashButton] enabled:YES];
    [self setObjects:@[self.pauseButton] enabled:NO];
}

- (void)startPlayback
{
    [self.recorder startPlayback];
    
    self.playbackDurationView.duration = self.recorder.playbackDuration;
    self.playbackDurationView.currentTime = self.recorder.currentTime;
    
    [playProgressDisplayLink invalidate];
    playProgressDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updatePlaybackProgress)];
    [playProgressDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    
    [self setObjects:@[self.recordButton, self.playButton, self.trashButton] enabled:NO];
    [self setObjects:@[self.pauseButton] enabled:YES];
}

- (void)stopPlayback
{
    [playProgressDisplayLink invalidate];
    
    [self.recorder stopPlayback];    // TODO: no reason to stop (undoes the setup needed for playback) - pause shoud do the trick (+rewind)
    
    self.playbackDurationView.currentTime = 0;
    
    [self setObjects:@[self.recordButton, self.playButton, self.trashButton] enabled:YES];
    [self setObjects:@[self.pauseButton] enabled:NO];
}

// TODO: add pausePlayback

#pragma mark Private methods

- (void)updateWaveform
{
    if (self.recorder.isRecording || self.recorder.isPlaying) {
        [self.waveformView updateWithLevel:[self.recorder updateMeters]];
        
        if (self.recorder.isRecording) {
            self.waveformView.waveColor = self.recordingTintColor;
            
            self.playbackDurationView.duration = self.recorder.currentTime;
            
            if ([self.delegate respondsToSelector:@selector(audioRecorderController:didRecordTimeInterval:)]) {
                [self.delegate audioRecorderController:self didRecordTimeInterval:self.recorder.currentTime];
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
    [self.playbackDurationView setCurrentTime:self.recorder.currentTime animated:YES];
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

- (void)audioRecorderDidFinishPlayback:(IQAudioRecorder *)recorder successfully:(BOOL)successfully
{
    if ([self.delegate respondsToSelector:@selector(audioRecorderControllerDidFinishPlayback:)]) {
        [self.delegate audioRecorderControllerDidFinishPlayback:self];
    }
}

- (void)audioRecorder:(IQAudioRecorder *)recorder didFailWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(audioRecorderController:didFailWithError:)]) {
        [self.delegate audioRecorderController:self didFailWithError:error];
    }
}

- (void)microphoneAccessDeniedForAudioRecorder:(IQAudioRecorder *)recorder
{
    if ([self.delegate respondsToSelector:@selector(microphoneAccessDeniedForAudioRecorderController:)]) {
        [self.delegate microphoneAccessDeniedForAudioRecorderController:self];
    }
}

#pragma mark - IQPlaybackDurationViewDelegate

- (void)playbackDurationView:(IQPlaybackDurationView *)playbackView didStartScrubbingAtTime:(NSTimeInterval)time
{
    wasPlaying = self.recorder.isPlaying;
    
    if (self.recorder.isPlaying) {
        [self.recorder pausePlayback];
    }
}

- (void)playbackDurationView:(IQPlaybackDurationView *)playbackView didScrubToTime:(NSTimeInterval)time
{
    self.recorder.currentTime = time;
}

- (void)playbackDurationView:(IQPlaybackDurationView *)playbackView didEndScrubbingAtTime:(NSTimeInterval)time
{
    self.recorder.currentTime = time;
    
    if (wasPlaying) {
        [self.recorder resumePlayback];
    }
}

@end
