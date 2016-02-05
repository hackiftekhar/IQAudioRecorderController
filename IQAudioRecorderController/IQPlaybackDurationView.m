//
//  IQPlaybackDurationView.m
//  IQAudioRecorderController Demo
//
//  Created by Sebastian Ludwig on 03.02.16.
//  Copyright © 2016 Iftekhar. All rights reserved.
//

#import "IQPlaybackDurationView.h"
#import "IQTimeIntervalFormatter.h"

IB_DESIGNABLE
@implementation IQPlaybackDurationView
{
    IQTimeIntervalFormatter *_timeIntervalFormatter;
    
    UISlider *_slider;
    UILabel *_currentTimeLabel;
    UILabel *_remainingTimeLabel;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _timeIntervalFormatter = [[IQTimeIntervalFormatter alloc] init];
    
    self.backgroundColor = [UIColor clearColor];
    
    _currentTimeLabel = [[UILabel alloc] init];
    _currentTimeLabel.text = [_timeIntervalFormatter stringFromTimeInterval:0];
    _currentTimeLabel.font = [UIFont boldSystemFontOfSize:14.0];
    _currentTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    _slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 64)];
    _slider.value = 0;
    [_slider addTarget:self action:@selector(sliderStart) forControlEvents:UIControlEventTouchDown];
    [_slider addTarget:self action:@selector(sliderMoved) forControlEvents:UIControlEventValueChanged];
    [_slider addTarget:self action:@selector(sliderEnd) forControlEvents:UIControlEventTouchUpInside];
    [_slider addTarget:self action:@selector(sliderEnd) forControlEvents:UIControlEventTouchUpOutside];
    _slider.translatesAutoresizingMaskIntoConstraints = NO;
    
    _remainingTimeLabel = [[UILabel alloc] init];
    _currentTimeLabel.text = [_timeIntervalFormatter stringFromTimeInterval:0];
    _remainingTimeLabel.userInteractionEnabled = YES;
    [_remainingTimeLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleRemainingTimeDisplay:)]];
    _remainingTimeLabel.font = _currentTimeLabel.font;
    _remainingTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:_currentTimeLabel];
    [self addSubview:_slider];
    [self addSubview:_remainingTimeLabel];

    NSDictionary *views = @{@"currentTime": _currentTimeLabel, @"slider": _slider, @"remainingTime": _remainingTimeLabel};
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-[currentTime]-[slider]-[remainingTime]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views];
    [self addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[slider]|" options:0 metrics:nil views:views];
    [self addConstraints:constraints];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_slider attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
}

- (void)prepareForInterfaceBuilder
{
    [self setDuration:1337];
    [self setCurrentTime:500];
    [self updateRemainingTimeLabel];
}

- (void)setShowRemainingTime:(BOOL)showRemainingTime
{
    _showRemainingTime = showRemainingTime;
    
    [self updateRemainingTimeLabel];
}

- (UIColor *)textColor
{
    return _currentTimeLabel.textColor;
}

- (void)setTextColor:(UIColor *)textColor
{
    _currentTimeLabel.textColor = textColor;
    _remainingTimeLabel.textColor = textColor;
}

- (UIColor *)sliderTintColor
{
    return _slider.minimumTrackTintColor;
}

- (void)setSliderTintColor:(UIColor *)sliderTintColor
{
    _slider.minimumTrackTintColor = sliderTintColor;
}

- (void)setDuration:(NSTimeInterval)duration
{
    _slider.maximumValue = duration;
    
    [self updateRemainingTimeLabel];
}

- (void)setCurrentTime:(NSTimeInterval)time
{
    [self setCurrentTime:time animated:NO];
}

- (void)setCurrentTime:(NSTimeInterval)time animated:(BOOL)animated
{
    [_slider setValue:time animated:animated];
    _currentTimeLabel.text = [_timeIntervalFormatter stringFromTimeInterval:time];
    [self updateRemainingTimeLabel];
}

#pragma mark Private methods

- (void)updateRemainingTimeLabel
{
    if (self.showRemainingTime) {
        _remainingTimeLabel.text = [_timeIntervalFormatter stringFromTimeInterval:(_slider.maximumValue-_slider.value)];
    } else {
        _remainingTimeLabel.text = [_timeIntervalFormatter stringFromTimeInterval:_slider.maximumValue];
    }
}

- (void)toggleRemainingTimeDisplay:(UITapGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        self.showRemainingTime = !self.showRemainingTime;
    }
}

-(void)sliderStart
{
    [self.delegate playbackDurationView:self didStartScrubbingAtTime:_slider.value];
}

-(void)sliderMoved
{
    [self.delegate playbackDurationView:self didScrubToTime:_slider.value];
}

-(void)sliderEnd
{
    [self.delegate playbackDurationView:self didEndScrubbingAtTime:_slider.value];
}

@end
