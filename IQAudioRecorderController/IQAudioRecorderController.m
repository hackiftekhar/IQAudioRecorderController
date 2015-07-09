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

#import "IQAudioRecorder.h"

@interface IQAudioRecorderController () <IQAudioRecorderDelegate, UIActionSheetDelegate>

@end

/************************************/

@implementation IQAudioRecorderController
{
    //Recording...
    IQAudioRecorder *recorder;
    SCSiriWaveformView *musicFlowView;
    CADisplayLink *meterUpdateDisplayLink;
    
    //Playing
    BOOL _wasPlaying;
    UIView *_viewPlayerDuration;
    UISlider *_playerSlider;
    UILabel *_labelCurrentTime;
    UILabel *_labelRemainingTime;
    CADisplayLink *playProgressDisplayLink;
    
    //Navigation Bar
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_doneButton;
    
    //Toolbar
    NSArray *_recordToolbarItems;
    NSArray *_playToolbarItems;
    
    //Private variables
    UIColor *_originalToolbarTintColor;
    UIColor *_originalNavigationBarTintColor;
}


+ (UINavigationController *)embeddedIQAudioRecorderControllerWithDelegate:(id<IQAudioRecorderControllerDelegate, UINavigationControllerDelegate>)delegate
{
    IQAudioRecorderController *recorderController = [IQAudioRecorderController new];
    recorderController.delegate = delegate;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:recorderController];
    navigationController.delegate = delegate;
    
    navigationController.navigationBar.tintColor = [UIColor whiteColor];
    navigationController.navigationBar.translucent = YES;
    navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    navigationController.toolbarHidden = NO;
    navigationController.toolbar.tintColor = navigationController.navigationBar.tintColor;
    navigationController.toolbar.translucent = navigationController.navigationBar.translucent;
    navigationController.toolbar.barStyle = navigationController.navigationBar.barStyle;
    
    return navigationController;
}

+ (NSString *)timeStringForTimeInterval:(NSTimeInterval)timeInterval
{
    NSInteger ti = (NSInteger)timeInterval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    
    if (hours > 0)
    {
        return [NSString stringWithFormat:@"%02li:%02li:%02li", (long)hours, (long)minutes, (long)seconds];
    }
    else
    {
        return  [NSString stringWithFormat:@"%02li:%02li", (long)minutes, (long)seconds];
    }
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.title = self.title ?: @"Audio Recorder";
    
    self.recordButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"audio_record"] style:UIBarButtonItemStylePlain target:self action:@selector(recordingButtonAction:)];
    self.playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playAction:)];
    self.trashButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteAction:)];
    
    recorder = [[IQAudioRecorder alloc] init];
    recorder.delegate = self;
}

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
    
    self.normalTintColor = self.normalTintColor ?: [UIColor whiteColor];
    self.recordingTintColor = self.recordingTintColor ?: [UIColor colorWithRed:0.0/255.0 green:128.0/255.0 blue:255.0/255.0 alpha:1.0];
    self.playingTintColor = self.playingTintColor ?: [UIColor colorWithRed:255.0/255.0 green:64.0/255.0 blue:64.0/255.0 alpha:1.0];
    
    musicFlowView.backgroundColor = [self.view backgroundColor];
//    musicFlowView.idleAmplitude = 0;
    musicFlowView.primaryWaveLineWidth = 3.0f;
    musicFlowView.secondaryWaveLineWidth = 1.0;

    // Navigation Bar Settings
    {
        _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
        self.navigationItem.leftBarButtonItem = _cancelButton;
        _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
        self.navigationController.navigationBar.tintColor = self.normalTintColor;
    }
    
    // Toolbar
    {
        UIBarButtonItem *_pauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pauseAction:)];
        UIBarButtonItem *_flexItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *_flexItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

        _recordToolbarItems = @[self.playButton,_flexItem1, self.recordButton,_flexItem2, self.trashButton];
        _playToolbarItems = @[_pauseButton,_flexItem1, self.recordButton,_flexItem2, self.trashButton];
        
        [self setToolbarItems:_recordToolbarItems animated:NO];
        
        self.playButton.enabled = NO;
        self.trashButton.enabled = NO;
    }
    
    // Player Duration View
    {
        _viewPlayerDuration = [[UIView alloc] init];
        _viewPlayerDuration.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _viewPlayerDuration.backgroundColor = [UIColor clearColor];

        _labelCurrentTime = [[UILabel alloc] init];
        _labelCurrentTime.text = [self.class timeStringForTimeInterval:0];
        _labelCurrentTime.font = [UIFont boldSystemFontOfSize:14.0];
        _labelCurrentTime.textColor = self.normalTintColor;
        _labelCurrentTime.translatesAutoresizingMaskIntoConstraints = NO;

        _playerSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 64)];
        _playerSlider.minimumTrackTintColor = self.playingTintColor;
        _playerSlider.value = 0;
        [_playerSlider addTarget:self action:@selector(sliderStart:) forControlEvents:UIControlEventTouchDown];
        [_playerSlider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];
        [_playerSlider addTarget:self action:@selector(sliderEnd:) forControlEvents:UIControlEventTouchUpInside];
        [_playerSlider addTarget:self action:@selector(sliderEnd:) forControlEvents:UIControlEventTouchUpOutside];
        _playerSlider.translatesAutoresizingMaskIntoConstraints = NO;

        _labelRemainingTime = [[UILabel alloc] init];
        _labelCurrentTime.text = [self.class timeStringForTimeInterval:0];
        _labelRemainingTime.userInteractionEnabled = YES;
        [_labelRemainingTime addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognizer:)]];
        _labelRemainingTime.font = _labelCurrentTime.font;
        _labelRemainingTime.textColor = _labelCurrentTime.textColor;
        _labelRemainingTime.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_viewPlayerDuration addSubview:_labelCurrentTime];
        [_viewPlayerDuration addSubview:_playerSlider];
        [_viewPlayerDuration addSubview:_labelRemainingTime];
        
        NSLayoutConstraint *constraintCurrentTimeLeading = [NSLayoutConstraint constraintWithItem:_labelCurrentTime attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_viewPlayerDuration attribute:NSLayoutAttributeLeading multiplier:1 constant:10];
        NSLayoutConstraint *constraintCurrentTimeTrailing = [NSLayoutConstraint constraintWithItem:_playerSlider attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_labelCurrentTime attribute:NSLayoutAttributeTrailing multiplier:1 constant:10];
        NSLayoutConstraint *constraintRemainingTimeLeading = [NSLayoutConstraint constraintWithItem:_labelRemainingTime attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_playerSlider attribute:NSLayoutAttributeTrailing multiplier:1 constant:10];
        NSLayoutConstraint *constraintRemainingTimeTrailing = [NSLayoutConstraint constraintWithItem:_viewPlayerDuration attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_labelRemainingTime attribute:NSLayoutAttributeTrailing multiplier:1 constant:10];
        
        NSLayoutConstraint *constraintCurrentTimeCenter = [NSLayoutConstraint constraintWithItem:_labelCurrentTime attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_viewPlayerDuration attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        NSLayoutConstraint *constraintSliderCenter = [NSLayoutConstraint constraintWithItem:_playerSlider attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_viewPlayerDuration attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        NSLayoutConstraint *constraintRemainingTimeCenter = [NSLayoutConstraint constraintWithItem:_labelRemainingTime attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_viewPlayerDuration attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        
        [_viewPlayerDuration addConstraints:@[constraintCurrentTimeLeading,constraintCurrentTimeTrailing,constraintRemainingTimeLeading,constraintRemainingTimeTrailing,constraintCurrentTimeCenter,constraintSliderCenter,constraintRemainingTimeCenter]];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _originalNavigationBarTintColor = self.navigationController.navigationBar.tintColor;
    _originalToolbarTintColor = self.navigationController.toolbar.tintColor;
    [self spreadTintColor:self.normalTintColor];
    
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    [self startUpdatingMeter];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.tintColor = _originalNavigationBarTintColor;
    self.navigationController.toolbar.tintColor = _originalToolbarTintColor;
    
    [self stopUpdatingMeter];
}

- (void)spreadTintColor:(UIColor *)color
{
    self.view.tintColor = color;
    musicFlowView.tintColor = color;
    self.navigationController.toolbar.tintColor = color;
}

#pragma mark - Update Meters

- (void)updateMeters
{
    if (recorder.isRecording || recorder.isPlaying)
    {
        [musicFlowView updateWithLevel:[recorder updateMeters]];
    
        musicFlowView.waveColor = recorder.isRecording ? self.recordingTintColor : self.playingTintColor;
        
        if (recorder.isRecording) {
            self.navigationItem.title = [self.class timeStringForTimeInterval:recorder.currentTime];
        }
    }
    else
    {
        [musicFlowView setWaveColor:self.normalTintColor];
        [musicFlowView updateWithLevel:0];
    }
}

-(void)startUpdatingMeter
{
    [meterUpdateDisplayLink invalidate];
    meterUpdateDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMeters)];
    [meterUpdateDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

-(void)stopUpdatingMeter
{
    [meterUpdateDisplayLink invalidate];
    meterUpdateDisplayLink = nil;
}

#pragma mark - Update Play Progress

-(void)updatePlayProgress
{
    _labelCurrentTime.text = [self.class timeStringForTimeInterval:recorder.currentTime];
    _labelRemainingTime.text = [self.class timeStringForTimeInterval:(_shouldShowRemainingTime)?(recorder.playbackDuration-recorder.currentTime):recorder.playbackDuration];
    [_playerSlider setValue:recorder.currentTime animated:YES];
}

-(void)sliderStart:(UISlider*)slider
{
    _wasPlaying = recorder.isPlaying;
    
    if (recorder.isPlaying)
    {
        [recorder pausePlayback];
    }
}

-(void)sliderMoved:(UISlider*)slider
{
    recorder.currentTime = slider.value;
}

-(void)sliderEnd:(UISlider*)slider
{
    recorder.currentTime = slider.value;
    
    if (_wasPlaying)
    {
        [recorder resumePlayback];
    }
}

-(void)tapRecognizer:(UITapGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        _shouldShowRemainingTime = !_shouldShowRemainingTime;
    }
}

-(void)cancelAction:(UIBarButtonItem*)item
{
    if ([self.delegate respondsToSelector:@selector(audioRecorderControllerDidCancel:)])
    {
        [self.delegate audioRecorderControllerDidCancel:self];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)doneAction:(UIBarButtonItem*)item
{
    if ([self.delegate respondsToSelector:@selector(audioRecorderController:didFinishWithAudioAtPath:)])
    {
        [self.delegate audioRecorderController:self didFinishWithAudioAtPath:recorder.filePath];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)recordingButtonAction:(UIBarButtonItem *)item
{
    if (!recorder.isRecording)
    {
        //UI Update
        {
            [self showNavigationButton:NO];
            [self spreadTintColor:self.recordingTintColor];
            self.playButton.enabled = NO;
            self.trashButton.enabled = NO;
        }
        
        [recorder startRecording];
    }
    else
    {
        //UI Update
        {
            [self showNavigationButton:YES];
            [self spreadTintColor:self.normalTintColor];
            self.playButton.enabled = YES;
            self.trashButton.enabled = YES;
        }

        [recorder stopRecording];
    }
}

- (void)playAction:(UIBarButtonItem *)item
{
    [recorder startPlayback];
    
    //UI Update
    {
        [self setToolbarItems:_playToolbarItems animated:YES];
        [self showNavigationButton:NO];
        self.recordButton.enabled = NO;
        self.trashButton.enabled = NO;
    }
    
    //Start regular update
    {
        _playerSlider.value = recorder.currentTime;
        _playerSlider.maximumValue = recorder.playbackDuration;
        _viewPlayerDuration.frame = self.navigationController.navigationBar.bounds;
        
        _labelCurrentTime.text = [self.class timeStringForTimeInterval:recorder.currentTime];
        _labelRemainingTime.text = [self.class timeStringForTimeInterval:(_shouldShowRemainingTime)?(recorder.playbackDuration-recorder.currentTime):recorder.playbackDuration];

        [_viewPlayerDuration setNeedsLayout];
        [_viewPlayerDuration layoutIfNeeded];
        self.navigationItem.titleView = _viewPlayerDuration;

        [playProgressDisplayLink invalidate];
        playProgressDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updatePlayProgress)];
        [playProgressDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}

-(void)pauseAction:(UIBarButtonItem*)item
{
    //UI Update
    {
        [self setToolbarItems:_recordToolbarItems animated:YES];
        [self showNavigationButton:YES];
        self.recordButton.enabled = YES;
        self.trashButton.enabled = YES;
    }
    
    {
        [playProgressDisplayLink invalidate];
        playProgressDisplayLink = nil;
        self.navigationItem.titleView = nil;
    }

    [recorder stopPlayback];    // TODO: no reason to stop - pause shoud do the trick (+rewind)
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
            [recorder discardRecording];
            
            self.playButton.enabled = NO;
            self.trashButton.enabled = NO;
            [self.navigationItem setRightBarButtonItem:nil animated:YES];
            self.navigationItem.title = self.title;
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

#pragma mark - IQAudioRecorderDelegate

- (void)audioRecorder:(IQAudioRecorder *)recorder didFinishPlaybackSuccessfully:(BOOL)successfully
{
    //To update UI on stop playing
    [self pauseAction:nil];
}

@end

