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




@interface IQAudioRecorderViewController () <UIActionSheetDelegate, IQAudioRecorderControllerDelegate>

@end

/************************************/

@implementation IQAudioRecorderViewController
{
    IQTimeIntervalFormatter *_timeIntervalFormatter;
    
    IQAudioRecorderController *_controller;
    
    // Toolbar
    NSArray *_recordToolbarItems;
    NSArray *_playToolbarItems;
    
    UIBarButtonItem *_playButton;
    UIBarButtonItem *_pauseButton;
    UIBarButtonItem *_recordButton;
    UIBarButtonItem *_trashButton;
    
    //Playing
    IQPlaybackDurationView *_viewPlayerDuration;
    
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
    self.title = self.title ?: @"Audio Recorder";
    
    _timeIntervalFormatter = [[IQTimeIntervalFormatter alloc] init];
    
    _controller = [[IQAudioRecorderController alloc] init];
    _controller.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor darkGrayColor];
    
    SCSiriWaveformView *musicFlowView = [[SCSiriWaveformView alloc] initWithFrame:self.view.bounds];
    musicFlowView.backgroundColor = [self.view backgroundColor];
    //    musicFlowView.idleAmplitude = 0;
    musicFlowView.primaryWaveLineWidth = 3.0f;
    musicFlowView.secondaryWaveLineWidth = 1.0;
    musicFlowView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:musicFlowView];
    _controller.waveformView = musicFlowView;
    
    NSLayoutConstraint *constraintCenterX = [NSLayoutConstraint constraintWithItem:musicFlowView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    NSLayoutConstraint *constraintCenterY = [NSLayoutConstraint constraintWithItem:musicFlowView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
    NSLayoutConstraint *constraintWidth = [NSLayoutConstraint constraintWithItem:musicFlowView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0];
    NSLayoutConstraint *constraintHeight = [NSLayoutConstraint constraintWithItem:musicFlowView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0];
    [self.view addConstraints:@[constraintCenterX, constraintCenterY, constraintWidth, constraintHeight]];
    
    // Navigation Bar Settings
    {
        self.navigationItem.hidesBackButton = YES;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
        self.navigationController.navigationBar.tintColor = _controller.normalTintColor;
    }
    
    // Toolbar
    {
        _recordButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"audio_record"] style:UIBarButtonItemStylePlain target:self action:@selector(recordingButtonAction:)];
        _playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playAction:)];
        _pauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pauseAction:)];
        _trashButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteAction:)];
        
        UIBarButtonItem *_flexItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *_flexItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        _recordToolbarItems = @[_playButton, _flexItem1, _recordButton, _flexItem2, _trashButton];
        _playToolbarItems = @[_pauseButton, _flexItem1, _recordButton, _flexItem2, _trashButton];
        
        [self setToolbarItems:_recordToolbarItems animated:NO];
    }
    
    // Controller
    {
        _viewPlayerDuration = [[IQPlaybackDurationView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
        _viewPlayerDuration.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _controller.playbackDurationView = _viewPlayerDuration;
        
        _controller.recordButton = _recordButton;
        _controller.playButton = _playButton;
        _controller.pauseButton = _pauseButton;
        _controller.trashButton = _trashButton;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _originalNavigationBarTintColor = self.navigationController.navigationBar.tintColor;
    _originalToolbarTintColor = self.navigationController.toolbar.tintColor;
    [self spreadTintColor:_controller.normalTintColor];
    
    _shouldHideBackButton = self.navigationItem.hidesBackButton;
    _leftBarButtonItems = self.navigationItem.leftBarButtonItems;
    _rightBarButtonItems = self.navigationItem.rightBarButtonItems;
    self.navigationItem.rightBarButtonItems = nil;
    
    _navigationControllerToolbarWasHidden = self.navigationController.toolbarHidden;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    [_controller startUpdatingWaveformView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.tintColor = _originalNavigationBarTintColor;
    self.navigationController.toolbar.tintColor = _originalToolbarTintColor;
    [self.navigationController setToolbarHidden:_navigationControllerToolbarWasHidden animated:YES];
    
    
    [_controller stopUpdatingWaveformView];
}

- (void)spreadTintColor:(UIColor *)color
{
    self.view.tintColor = color;
    self.navigationController.toolbar.tintColor = color;
}

- (void)showNavigationButtons:(BOOL)show
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

#pragma mark - Button actions

-(void)cancelAction:(UIBarButtonItem*)item
{
    if ([self.delegate respondsToSelector:@selector(audioRecorderViewControllerDidCancel:)]) {
        [self.delegate audioRecorderViewControllerDidCancel:self];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)doneAction:(UIBarButtonItem*)item
{
    if ([self.delegate respondsToSelector:@selector(audioRecorderViewController:didFinishWithAudioAtPath:)]) {
        [self.delegate audioRecorderViewController:self didFinishWithAudioAtPath:_controller.recordedFilePath];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)recordingButtonAction:(UIBarButtonItem *)item
{
    if (_controller.isRecording) {
        [_controller stopRecording];
        [self spreadTintColor:_controller.normalTintColor];
    } else {
        [_controller startRecording];
        [self spreadTintColor:_controller.recordingTintColor];
    }
    
    //UI Update
    {
        [self showNavigationButtons:!_controller.isRecording];
    }
}

- (void)playAction:(UIBarButtonItem *)item
{
    [_controller startPlayback];
    
    //UI Update
    [self setToolbarItems:_playToolbarItems animated:YES];
    [self showNavigationButtons:NO];

    _viewPlayerDuration.frame = self.navigationController.navigationBar.bounds;
    [_viewPlayerDuration setNeedsLayout];
    [_viewPlayerDuration layoutIfNeeded];
    self.navigationItem.titleView = _viewPlayerDuration;
}

-(void)pauseAction:(UIBarButtonItem*)item
{
    //UI Update
    {
        [self showNavigationButtons:YES];
        self.navigationItem.titleView = nil;
        
        [self setToolbarItems:_recordToolbarItems animated:YES];
    }
    
    [_controller stopPlayback];
}

-(void)deleteAction:(UIBarButtonItem*)item
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Recording" otherButtonTitles:nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    {
        [_controller discardRecording];
        
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        self.navigationItem.title = self.title;
    }
}

#pragma mark - IQAudioRecorderControllerDelegate

- (void)audioRecorderControllerDidFinishPlayback:(IQAudioRecorderController *)controller
{
    //To update UI on stop playing
    [self pauseAction:nil];
}

- (void)audioRecorderController:(IQAudioRecorderController *)controller didRecordTimeInterval:(NSTimeInterval)time
{
    self.navigationItem.title = [_timeIntervalFormatter stringFromTimeInterval:time];
}

@end

