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
    UINavigationController *controller = [IQAudioRecorderViewController embeddedIQAudioRecorderViewControllerWithDelegate:self];
    controller.topViewController.title = @"Custom";
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (![segue.identifier isEqualToString:@"ShowCustomVC"]) {
        [(IQAudioRecorderViewController *)[segue.destinationViewController topViewController] setDelegate:self];
    }
}

-(void)audioRecorderViewController:(IQAudioRecorderViewController *)controller didFinishWithAudioAtPath:(NSString *)filePath
{
    audioFilePath = filePath;
    buttonPlayAudio.enabled = YES;
}

-(void)audioRecorderViewControllerDidCancel:(IQAudioRecorderViewController *)controller
{
    buttonPlayAudio.enabled = NO;
}

- (IBAction)playAction:(UIButton *)sender
{
    MPMoviePlayerViewController *controller = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:audioFilePath]];
    [self presentMoviePlayerViewControllerAnimated:controller];
}

@end
