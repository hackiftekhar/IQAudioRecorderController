//
//  ViewController.m
//  IQAudioRecorderController Demo


#import "ViewController.h"
#import "IQAudioRecorderController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()<IQAudioRecorderControllerDelegate, UINavigationControllerDelegate>
{
    IBOutlet UIButton *buttonPlayAudio;
    NSString *audioFilePath;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    buttonPlayAudio.enabled = NO;
}

- (IBAction)recordAction:(UIButton *)sender
{
    UINavigationController *controller = [IQAudioRecorderController embeddedIQAudioRecorderControllerWithDelegate:self];
    controller.topViewController.title = @"Custom";
    [self presentViewController:controller animated:YES completion:nil];
}

-(void)audioRecorderController:(IQAudioRecorderController *)controller didFinishWithAudioAtPath:(NSString *)filePath
{
    audioFilePath = filePath;
    buttonPlayAudio.enabled = YES;
}

-(void)audioRecorderControllerDidCancel:(IQAudioRecorderController *)controller
{
    buttonPlayAudio.enabled = NO;
}

- (IBAction)playAction:(UIButton *)sender
{
    MPMoviePlayerViewController *controller = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:audioFilePath]];
    [self presentMoviePlayerViewControllerAnimated:controller];
}

@end
