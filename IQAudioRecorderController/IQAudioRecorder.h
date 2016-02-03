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

- (void)audioRecorder:(IQAudioRecorder *)recorder didFinishPlaybackSuccessfully:(BOOL)successfully;

@end


@interface IQAudioRecorder : NSObject

@property (nonatomic, weak) id<IQAudioRecorderDelegate> delegate;

@property (nonatomic, readonly) NSString *filePath;     // HINT: maybe change to URL?
@property (nonatomic, readonly, getter=isRecording) BOOL recording;
@property (nonatomic, readonly, getter=isPlaying) BOOL playing;
@property (nonatomic, readonly) NSTimeInterval playbackDuration;
@property (nonatomic) NSTimeInterval currentTime;

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
