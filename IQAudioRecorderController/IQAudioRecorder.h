//
// https://github.com/hackiftekhar/IQAudioRecorderController
//  IQAudioRecorderViewController.h
// Copyright (c) 2013-14 Iftekhar Qurashi.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>
#import "SCSiriWaveformView.h"

@class IQAudioRecorder;

@protocol IQAudioRecorderDelegate <NSObject>

@optional
- (void)audioRecorderDidFinishPlayback:(IQAudioRecorder *)recorder successfully:(BOOL)successfully;
- (void)audioRecorder:(IQAudioRecorder *)recorder didFailWithError:(NSError *)error;
- (void)microphoneAccessDeniedForAudioRecorder:(IQAudioRecorder *)recorder;

@end


@interface IQAudioRecorder : NSObject

// only to be changed from IB - has no effect if set after initialization
@property (nonatomic) IBInspectable NSString *format;
@property (nonatomic) IBInspectable CGFloat sampleRate;
@property (nonatomic) IBInspectable int channels;

@property (nonatomic, weak) IBOutlet id<IQAudioRecorderDelegate> delegate;

@property (nonatomic, readonly) NSString *filePath;     // HINT: maybe change to URL?
@property (nonatomic, readonly, getter=isRecording) BOOL recording;
@property (nonatomic, readonly, getter=isPlaying) BOOL playing;
@property (nonatomic, readonly) NSTimeInterval playbackDuration;
@property (nonatomic) NSTimeInterval currentTime;

- (instancetype)initWithFormat:(AudioFormatID)format sampleRate:(CGFloat)sampleRate numberOfChannels:(int)channels;

- (void)setup;  // needs to be called before using the instance, if you create the recorder instance in code

- (void)prepareForRecording;    // you may call this method to ensure the recording can start as quickly as possible. BEWARE: overwrites any previous recordings at the moment!
- (void)startRecording;
- (void)stopRecording;
- (void)discardRecording;

- (void)startPlayback;
- (void)pausePlayback;
- (void)resumePlayback;
- (void)stopPlayback;

- (CGFloat)updateMeters;

@end
