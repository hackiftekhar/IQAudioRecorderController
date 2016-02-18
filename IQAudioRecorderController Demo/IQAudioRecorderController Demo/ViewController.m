//
//  ViewController.m
//  IQAudioRecorderController Demo


#import "ViewController.h"
#import "IQAudioRecorderViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()<IQAudioRecorderViewControllerDelegate>
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

- (IBAction)recordWhiteAction:(UIButton *)sender
{
    IQAudioRecorderViewController *controller = [[IQAudioRecorderViewController alloc] init];
    controller.delegate = self;
    controller.barStyle = UIBarStyleDefault;
    controller.maximumRecordDuration = 10;
//    controller.normalTintColor = [UIColor magentaColor];
//    controller.highlightedTintColor = [UIColor orangeColor];
    [self presentAudioRecorderViewControllerAnimated:controller];
}

- (IBAction)recordAction:(UIButton *)sender
{
    IQAudioRecorderViewController *controller = [[IQAudioRecorderViewController alloc] init];
    controller.delegate = self;
    controller.barStyle = UIBarStyleBlackTranslucent;
//    controller.normalTintColor = [UIColor cyanColor];
//    controller.highlightedTintColor = [UIColor orangeColor];
    [self presentAudioRecorderViewControllerAnimated:controller];
}

-(void)audioRecorderController:(IQAudioRecorderViewController *)controller didFinishWithAudioAtPath:(NSString *)filePath
{
    audioFilePath = filePath;
    buttonPlayAudio.enabled = YES;
}

-(void)audioRecorderControllerDidCancel:(IQAudioRecorderViewController *)controller
{
    buttonPlayAudio.enabled = NO;
}

- (IBAction)playAction:(UIButton *)sender
{
    MPMoviePlayerViewController *controller = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:audioFilePath]];
    [self presentMoviePlayerViewControllerAnimated:controller];
}

@end
