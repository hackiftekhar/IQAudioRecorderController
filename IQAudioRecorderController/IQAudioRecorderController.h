//
//  IQAudioRecorderController.h
// https://github.com/hackiftekhar/IQAudioRecorderController
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

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SCSiriWaveformView.h"

@class IQInternalAudioRecorderController;

@protocol IQAudioRecorderControllerDelegate <NSObject>

- (void)audioRecorderController:(IQInternalAudioRecorderController *)controller didFinishWithAudioAtPath:(NSString *)filePath;
- (void)audioRecorderControllerDidCancel:(IQInternalAudioRecorderController *)controller;

@end


@interface IQInternalAudioRecorderController : UIViewController <AVAudioRecorderDelegate,AVAudioPlayerDelegate,UIActionSheetDelegate>
{
    //Recording...
    AVAudioRecorder *_audioRecorder;
    SCSiriWaveformView *musicFlowView;
    NSString *_recordingFilePath;
    BOOL _isRecording;
    CADisplayLink *meterUpdateDisplayLink;
    
    //Playing
    AVAudioPlayer *_audioPlayer;
    BOOL _wasPlaying;
    UIView *_viewPlayerDuration;
    UISlider *_playerSlider;
    UILabel *_labelCurrentTime;
    UILabel *_labelRemainingTime;
    CADisplayLink *playProgressDisplayLink;
    
    //Navigation Bar
    NSString *_navigationTitle;
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_doneButton;
    
    //Toolbar
    UIBarButtonItem *_flexItem1;
    UIBarButtonItem *_flexItem2;
    UIBarButtonItem *_playButton;
    UIBarButtonItem *_pauseButton;
    UIBarButtonItem *_recordButton;
    UIBarButtonItem *_trashButton;
    
    //Private variables
    NSString *_oldSessionCategory;
    UIColor *_normalTintColor;
    UIColor *_recordingTintColor;
    UIColor *_playingTintColor;
}

@property(nonatomic, weak) id<IQAudioRecorderControllerDelegate> delegate;

@property(nonatomic, assign) BOOL shouldShowRemainingTime;

+ (UINavigationController *)embeddedIQAudioRecorderControllerWithDelegate:(id<IQAudioRecorderControllerDelegate, UINavigationControllerDelegate>)delegate;

@end
