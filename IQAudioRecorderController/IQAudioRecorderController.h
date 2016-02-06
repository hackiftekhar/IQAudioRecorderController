//
//  IQAudioRecorderController.h
//  IQAudioRecorderController Demo
//
//  Created by Sebastian Ludwig on 05.02.16.
//  Copyright © 2016 Iftekhar. All rights reserved.
//

@import UIKit;

#import "SCSiriWaveformView.h"
#import "IQPlaybackDurationView.h"

@class IQAudioRecorderController;

@protocol IQAudioRecorderControllerDelegate <NSObject>

@optional
- (void)audioRecorderControllerDidFinishPlayback:(IQAudioRecorderController *)controller;
- (void)audioRecorderController:(IQAudioRecorderController *)controller didRecordTimeInterval:(NSTimeInterval)time;

@end

@interface IQAudioRecorderController : NSObject

@property (weak) id<IQAudioRecorderControllerDelegate> delegate;

@property (nonatomic) IBOutlet __weak SCSiriWaveformView *waveformView;
@property (nonatomic) IBOutlet __weak IQPlaybackDurationView *playbackDurationView;

// no need to assign these, but if you do they'll be enabled and disabled when it makes sense
@property (nonatomic) IBOutlet __weak id recordButton;
@property (nonatomic) IBOutlet __weak id playButton;
@property (nonatomic) IBOutlet __weak id pauseButton;
@property (nonatomic) IBOutlet __weak id trashButton;

@property (nonatomic) IBInspectable UIColor *normalTintColor;
@property (nonatomic) IBInspectable UIColor *recordingTintColor;
@property (nonatomic) IBInspectable UIColor *playingTintColor;

@property (nonatomic, readonly, getter=isRecording) BOOL recording;
@property (nonatomic, readonly) NSString *recordedFilePath;

- (void)startUpdatingWaveformView;
- (void)stopUpdatingWaveformView;

- (void)startRecording;
- (void)stopRecording;
- (void)discardRecording;

- (void)startPlayback;
- (void)stopPlayback;

@end