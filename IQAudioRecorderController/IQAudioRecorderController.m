//
//  IQAudioRecorderController.m
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


#import "IQAudioRecorderController.h"

#import "SCSiriWaveformView.h"

#import <AVFoundation/AVFoundation.h>

/************************************/

@interface IQInternalAudioRecorderController : UIViewController <AVAudioRecorderDelegate,AVAudioPlayerDelegate,UIActionSheetDelegate>
{
    SCSiriWaveformView *musicFlowView;
    
    NSString *_recordingFilePath;
    
    BOOL _isRecording;
    
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_doneButton;
    
    UIBarButtonItem *_flexItem1;
    UIBarButtonItem *_flexItem2;
    UIBarButtonItem *_recordButton;
    UIBarButtonItem *_playButton;
    UIBarButtonItem *_pauseButton;
    UIBarButtonItem *_trashButton;
    
    NSString *_oldSessionCategory;
    
    CADisplayLink *meterUpdateDisplayLink;
    
    UIColor *_normalTintColor;
    UIColor *_selectedTintColor;
}

@property(nonatomic, weak) id<IQAudioRecorderControllerDelegate> delegate;

@property (nonatomic,strong) AVAudioPlayer *audioPlayer;
@property (nonatomic,strong) AVAudioRecorder *audioRecorder;

@end

/************************************/

@implementation IQAudioRecorderController
{
    IQInternalAudioRecorderController *_internalController;
}
@synthesize delegate = _delegate;

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    _internalController = [[IQInternalAudioRecorderController alloc] init];
    _internalController.delegate = self.delegate;
    
    self.viewControllers = @[_internalController];
    self.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationBar.translucent = YES;
    self.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    self.toolbarHidden = NO;
    self.toolbar.tintColor = self.navigationBar.tintColor;
    self.toolbar.translucent = self.navigationBar.translucent;
    self.toolbar.barStyle = self.navigationBar.barStyle;
}

-(void)setDelegate:(id<IQAudioRecorderControllerDelegate,UINavigationControllerDelegate>)delegate
{
    _delegate = delegate;
    _internalController.delegate = delegate;
}

@end

/************************************/

@implementation IQInternalAudioRecorderController

-(void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor = [UIColor darkGrayColor];

    musicFlowView = [[SCSiriWaveformView alloc] initWithFrame:view.bounds];
    musicFlowView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:musicFlowView];
    self.view = view;

    
    NSLayoutConstraint *constraintRatio = [NSLayoutConstraint constraintWithItem:musicFlowView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:musicFlowView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0];
    
    NSLayoutConstraint *constraintCenterX = [NSLayoutConstraint constraintWithItem:musicFlowView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    
    NSLayoutConstraint *constraintCenterY = [NSLayoutConstraint constraintWithItem:musicFlowView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
    
    NSLayoutConstraint *constraintWidth = [NSLayoutConstraint constraintWithItem:musicFlowView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0];
    [musicFlowView addConstraint:constraintRatio];
    [view addConstraints:@[constraintWidth,constraintCenterX,constraintCenterY]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _normalTintColor = [UIColor whiteColor];
    _selectedTintColor = [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0];

    self.view.tintColor = _normalTintColor;
    musicFlowView.backgroundColor = [self.view backgroundColor];
//    musicFlowView.idleAmplitude = 0;

    //Unique recording URL
    NSString *fileName = [[NSProcessInfo processInfo] globallyUniqueString];
    _recordingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a",fileName]];

    {
        _flexItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        _flexItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        _recordButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"audio_record"] style:UIBarButtonItemStylePlain target:self action:@selector(recordingButtonAction:)];
        _playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playAction:)];
        _pauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pauseAction:)];
        _trashButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteAction:)];
        [self setToolbarItems:@[_playButton,_flexItem1, _recordButton,_flexItem2, _trashButton] animated:NO];

        _playButton.enabled = NO;
        _trashButton.enabled = NO;
    }
    
    // Define the recorder setting
    {
        NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
        
        [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
        [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
        [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
        
        // Initiate and prepare the recorder
        _audioRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:_recordingFilePath] settings:recordSetting error:nil];
        _audioRecorder.delegate = self;
        _audioRecorder.meteringEnabled = YES;
        
        [musicFlowView setWaveColor:_normalTintColor];
        [musicFlowView setPrimaryWaveLineWidth:3.0f];
        [musicFlowView setSecondaryWaveLineWidth:1.0];
    }

    //Navigation Bar Settings
    {
        self.navigationItem.title = @"Audio Recorder";
        _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
        self.navigationItem.leftBarButtonItem = _cancelButton;
        _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self startRunningRecorder];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.audioPlayer stop];
    self.audioPlayer.delegate = nil;
    self.audioPlayer = nil;
    
    [self stopRunningRecorder];
}

- (void)updateMeters
{
    [_audioRecorder updateMeters];
    
    CGFloat normalizedValue = pow (10, [_audioRecorder averagePowerForChannel:0] / 20);
    
    [musicFlowView updateWithLevel:normalizedValue];
    
    if (_audioRecorder.isRecording)
    {
        float audioDurationSeconds = _audioRecorder.currentTime;
        NSInteger minutes = floor(audioDurationSeconds/60);
        NSInteger seconds = round(audioDurationSeconds - minutes * 60);
        self.navigationItem.prompt = [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];
    }
}

-(void)startRunningRecorder
{
    meterUpdateDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMeters)];
    [meterUpdateDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

-(void)stopRunningRecorder
{
    [_audioRecorder stop];
    
    [meterUpdateDisplayLink invalidate];
    meterUpdateDisplayLink = nil;
}

-(void)cancelAction:(UIBarButtonItem*)item
{
    if ([self.delegate respondsToSelector:@selector(audioRecorderControllerDidCancel:)])
    {
        IQAudioRecorderController *controller = (IQAudioRecorderController*)[self navigationController];
        [self.delegate audioRecorderControllerDidCancel:controller];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)doneAction:(UIBarButtonItem*)item
{
    if ([self.delegate respondsToSelector:@selector(audioRecorderController:didFinishWithAudioAtPath:)])
    {
        IQAudioRecorderController *controller = (IQAudioRecorderController*)[self navigationController];
        [self.delegate audioRecorderController:controller didFinishWithAudioAtPath:_recordingFilePath];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)recordingButtonAction:(UIBarButtonItem *)item
{
    if (_isRecording == NO)
    {
        _isRecording = YES;

        //UI Update
        {
            [self showNavigationButton:NO];
            [musicFlowView setWaveColor:_selectedTintColor];
            self.navigationItem.prompt = nil;
            _recordButton.tintColor = _selectedTintColor;
            _playButton.enabled = NO;
            _trashButton.enabled = NO;
        }
        
        /*
         Create the recorder
         */
        if ([[NSFileManager defaultManager] fileExistsAtPath:_recordingFilePath])
        {
            [[NSFileManager defaultManager] removeItemAtPath:_recordingFilePath error:nil];
        }
        
        _oldSessionCategory = [[AVAudioSession sharedInstance] category];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
        [_audioRecorder prepareToRecord];
        [_audioRecorder record];
    }
    else
    {
        _isRecording = NO;
        
        //UI Update
        {
            [self showNavigationButton:YES];
            [musicFlowView setWaveColor:_normalTintColor];
            _recordButton.tintColor = _normalTintColor;
            _playButton.enabled = YES;
            _trashButton.enabled = YES;
        }

        [_audioRecorder stop];
        [[AVAudioSession sharedInstance] setCategory:_oldSessionCategory error:nil];
    }
}

- (void)playAction:(UIBarButtonItem *)item
{
    _oldSessionCategory = [[AVAudioSession sharedInstance] category];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:_recordingFilePath] error:nil];
    self.audioPlayer.delegate = self;
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
    
    //UI Update
    {
        [self setToolbarItems:@[_pauseButton,_flexItem1, _recordButton,_flexItem2, _trashButton] animated:YES];
        [self showNavigationButton:NO];
        _recordButton.enabled = NO;
        _trashButton.enabled = NO;
    }
}

-(void)pauseAction:(UIBarButtonItem*)item
{
    self.audioPlayer.delegate = nil;
    [self.audioPlayer stop];
    self.audioPlayer = nil;
    
    //UI Update
    {
        [self setToolbarItems:@[_playButton,_flexItem1, _recordButton,_flexItem2, _trashButton] animated:YES];
        [self showNavigationButton:YES];
        _recordButton.enabled = YES;
        _trashButton.enabled = YES;
    }
    
    [[AVAudioSession sharedInstance] setCategory:_oldSessionCategory error:nil];
}

-(void)deleteAction:(UIBarButtonItem*)item
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Recording" otherButtonTitles:nil, nil];
    actionSheet.tag = 1;
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 1)
    {
        if (buttonIndex == actionSheet.destructiveButtonIndex)
        {
            [[NSFileManager defaultManager] removeItemAtPath:_recordingFilePath error:nil];
            
            _playButton.enabled = NO;
            _trashButton.enabled = NO;
            [self.navigationItem setRightBarButtonItem:nil animated:YES];
            self.navigationItem.prompt = nil;
        }
    }
}

-(void)showNavigationButton:(BOOL)show
{
    if (show)
    {
        [self.navigationItem setLeftBarButtonItem:_cancelButton animated:YES];
        [self.navigationItem setRightBarButtonItem:_doneButton animated:YES];
    }
    else
    {
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
    }
}

#pragma mark - AVAudioPlayerDelegate
/*
 Occurs when the audio player instance completes playback
 */
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    //To update UI on stop playing
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_pauseButton.target methodSignatureForSelector:_pauseButton.action]];
    invocation.target = _pauseButton.target;
    invocation.selector = _pauseButton.action;
    [invocation invoke];
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
//    NSLog(@"%@: %@",NSStringFromSelector(_cmd),error);
}

@end

