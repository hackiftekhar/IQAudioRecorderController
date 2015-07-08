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
    UINavigationController *controller = [IQInternalAudioRecorderController embeddedIQAudioRecorderControllerWithDelegate:self];
    [self presentViewController:controller animated:YES completion:nil];
}

-(void)audioRecorderController:(IQInternalAudioRecorderController *)controller didFinishWithAudioAtPath:(NSString *)filePath
{
    audioFilePath = filePath;
    buttonPlayAudio.enabled = YES;
}

-(void)audioRecorderControllerDidCancel:(IQInternalAudioRecorderController *)controller
{
    buttonPlayAudio.enabled = NO;
}

- (IBAction)playAction:(UIButton *)sender
{
    MPMoviePlayerViewController *controller = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:audioFilePath]];
    [self presentMoviePlayerViewControllerAnimated:controller];
}

@end
