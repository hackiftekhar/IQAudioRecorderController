//
//  CustomRecorderViewController.m
//  IQAudioRecorderController Demo
//
//  Created by Sebastian Ludwig on 05.02.16.
//  Copyright © 2016 Iftekhar. All rights reserved.
//

#import "CustomRecorderViewController.h"
#import "IQAudioRecorderController.h"

@interface CustomRecorderViewController ()

@end

@implementation CustomRecorderViewController
{
    IBOutlet __weak IQAudioRecorderController *controller;
}

- (void)viewWillAppear:(BOOL)animated
{
    [controller startUpdatingWaveformView];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [controller stopUpdatingWaveformView];
}

- (IBAction)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)record
{
    if (controller.isRecording) {
        [controller stopRecording];
    } else {
        [controller startRecording];
    }
}

- (IBAction)play
{
    [controller startPlayback];
}

- (IBAction)pause
{
    [controller stopPlayback];
}

- (IBAction)trash
{
    [controller discardRecording];
}

@end
