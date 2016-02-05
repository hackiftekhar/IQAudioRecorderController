//
//  IQAudioRecorderViewController.m
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


#import "IQAudioRecorderViewController.h"

#import "IQAudioRecorder.h"
#import "IQTimeIntervalFormatter.h"
#import "IQPlaybackDurationView.h"

@interface IQAudioRecorderViewController () <IQAudioRecorderDelegate, IQPlaybackDurationViewDelegate, UIActionSheetDelegate>

@end

/************************************/

@implementation IQAudioRecorderViewController
{
    IQTimeIntervalFormatter *_timeIntervalFormatter;
    
    //Recording...
    IQAudioRecorder *recorder;
    SCSiriWaveformView *musicFlowView;
    CADisplayLink *meterUpdateDisplayLink;
    
    //Playing
    BOOL _wasPlaying;
    IQPlaybackDurationView *_viewPlayerDuration;
    CADisplayLink *playProgressDisplayLink;
    
    //Navigation Bar
    NSArray *_leftBarButtonItems;
    NSArray *_rightBarButtonItems;
    BOOL _shouldHideBackButton;
    
    //Private variables
    UIColor *_originalToolbarTintColor;
    UIColor *_originalNavigationBarTintColor;
    BOOL _navigationControllerToolbarWasHidden;
}


+ (UINavigationController *)embeddedIQAudioRecorderViewControllerWithDelegate:(id<IQAudioRecorderViewControllerDelegate, UINavigationControllerDelegate>)delegate
{
    IQAudioRecorderViewController *viewController = [IQAudioRecorderViewController new];
    viewController.delegate = delegate;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
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
    _timeIntervalFormatter = [[IQTimeIntervalFormatter alloc] init];
    
    self.title = self.title ?: @"Audio Recorder";
    
    self.recordButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"audio_record"] style:UIBarButtonItemStylePlain target:self action:@selector(recordingButtonAction:)];
    self.playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playAction:)];
    self.pauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pauseAction:)];
    self.trashButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteAction:)];
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
        self.navigationItem.hidesBackButton = YES;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
        self.navigationController.navigationBar.tintColor = self.normalTintColor;
    }
    
    // Toolbar
    {
        UIBarButtonItem *_flexItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *_flexItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        self.recordToolbarItems = @[self.playButton,_flexItem1, self.recordButton,_flexItem2, self.trashButton];
        self.playToolbarItems = @[self.pauseButton,_flexItem1, self.recordButton,_flexItem2, self.trashButton];
        
        [self setToolbarItems:self.recordToolbarItems animated:NO];
        
        self.playButton.enabled = NO;
        self.trashButton.enabled = NO;
    }
    
    // Player Duration View
    {
        _viewPlayerDuration = [[IQPlaybackDurationView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
        _viewPlayerDuration.delegate = self;
        _viewPlayerDuration.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _viewPlayerDuration.textColor = self.normalTintColor;
        _viewPlayerDuration.sliderTintColor = self.playingTintColor;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _originalNavigationBarTintColor = self.navigationController.navigationBar.tintColor;
    _originalToolbarTintColor = self.navigationController.toolbar.tintColor;
    [self spreadTintColor:self.normalTintColor];
    
    _shouldHideBackButton = self.navigationItem.hidesBackButton;
    _leftBarButtonItems = self.navigationItem.leftBarButtonItems;
    _rightBarButtonItems = self.navigationItem.rightBarButtonItems;
    self.navigationItem.rightBarButtonItems = nil;
    
    _navigationControllerToolbarWasHidden = self.navigationController.toolbarHidden;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    recorder = [[IQAudioRecorder alloc] init];
    recorder.delegate = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [recorder prepareForRecording];
    });
    
    [self startUpdatingMeter];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.tintColor = _originalNavigationBarTintColor;
    self.navigationController.toolbar.tintColor = _originalToolbarTintColor;
    [self.navigationController setToolbarHidden:_navigationControllerToolbarWasHidden animated:YES];
    
    
    [self stopUpdatingMeter];
    
    recorder = nil;
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
    
        if (recorder.isRecording) {
            self.navigationItem.title = [_timeIntervalFormatter stringFromTimeInterval:recorder.currentTime];;
            musicFlowView.waveColor = self.recordingTintColor;
        }
        else
        {
            musicFlowView.waveColor = self.playingTintColor;
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
}

#pragma mark - Update Play Progress

-(void)updatePlayProgress
{
    [_viewPlayerDuration setCurrentTime:recorder.currentTime animated:YES];
}

-(void)cancelAction:(UIBarButtonItem*)item
{
    if ([self.delegate respondsToSelector:@selector(audioRecorderViewControllerDidCancel:)])
    {
        [self.delegate audioRecorderViewControllerDidCancel:self];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)doneAction:(UIBarButtonItem*)item
{
    if ([self.delegate respondsToSelector:@selector(audioRecorderViewController:didFinishWithAudioAtPath:)])
    {
        [self.delegate audioRecorderViewController:self didFinishWithAudioAtPath:recorder.filePath];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)recordingButtonAction:(UIBarButtonItem *)item
{
    if (!recorder.isRecording)
    {
        [recorder startRecording];
    }
    else
    {
        [recorder stopRecording];
    }
    
    //UI Update
    {
        [self spreadTintColor:recorder.isRecording ? self.recordingTintColor : self.normalTintColor];
        
        [self showNavigationButtons:!recorder.isRecording];
        self.playButton.enabled = !recorder.isRecording;
        self.trashButton.enabled = !recorder.isRecording;
    }
}

- (void)playAction:(UIBarButtonItem *)item
{
    [recorder startPlayback];
    
    //UI Update
    {
        [self setToolbarItems:self.playToolbarItems animated:YES];
        [self showNavigationButtons:NO];
        self.recordButton.enabled = NO;
        self.trashButton.enabled = NO;
    }
    
    //Start regular update
    {
        [_viewPlayerDuration setDuration:recorder.playbackDuration];
        [_viewPlayerDuration setCurrentTime:recorder.currentTime];
        _viewPlayerDuration.frame = self.navigationController.navigationBar.bounds;

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
        [self showNavigationButtons:YES];
        self.navigationItem.titleView = nil;
        
        [self setToolbarItems:self.recordToolbarItems animated:YES];
        self.recordButton.enabled = YES;
        self.trashButton.enabled = YES;
    }
    
    {
        [playProgressDisplayLink invalidate];
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

-(void)showNavigationButtons:(BOOL)show
{
    if (show)
    {
        [self.navigationItem setHidesBackButton:_shouldHideBackButton animated:YES];
        [self.navigationItem setLeftBarButtonItems:_leftBarButtonItems animated:YES];
        [self.navigationItem setRightBarButtonItems:_rightBarButtonItems animated:YES];
    }
    else
    {
        [self.navigationItem setHidesBackButton:YES animated:YES];
        [self.navigationItem setLeftBarButtonItems:nil animated:YES];
        [self.navigationItem setRightBarButtonItems:nil animated:YES];
    }
}

#pragma mark - IQAudioRecorderDelegate

- (void)audioRecorder:(IQAudioRecorder *)recorder didFinishPlaybackSuccessfully:(BOOL)successfully
{
    //To update UI on stop playing
    [self pauseAction:nil];
}

#pragma mark - IQPlaybackDurationViewDelegate

- (void)playbackDurationView:(IQPlaybackDurationView *)playbackView didStartScrubbingAtTime:(NSTimeInterval)time
{
    _wasPlaying = recorder.isPlaying;
    
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
    
    if (_wasPlaying) {
        [recorder resumePlayback];
    }
}

@end

