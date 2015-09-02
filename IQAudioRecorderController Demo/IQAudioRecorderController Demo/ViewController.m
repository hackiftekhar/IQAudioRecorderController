//
//  ViewController.m
//  IQAudioRecorderController Demo


#import "ViewController.h"
#import "IQAudioRecorderController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()<IQAudioRecorderControllerDelegate>
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
    IQAudioRecorderController *controller = [[IQAudioRecorderController alloc] init];
    controller.delegate = self;
    
    //For overriding default colors:
    /*
    controller.normalTintColor = [UIColor redColor];
    controller.recordingTintColor = [UIColor purpleColor];
    controller.playingTintColor = [UIColor orangeColor];
    */
    
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
