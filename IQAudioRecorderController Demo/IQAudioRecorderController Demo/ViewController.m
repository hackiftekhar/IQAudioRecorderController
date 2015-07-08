//
//  ViewController.m
//  IQAudioRecorderController Demo


#import "ViewController.h"

#import <MediaPlayer/MediaPlayer.h>

@implementation ViewController
{
    IBOutlet UIButton *buttonPlayAudio;
    NSString *audioFilePath;
}

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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [(IQAudioRecorderController *)[segue.destinationViewController topViewController] setDelegate:self];
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
