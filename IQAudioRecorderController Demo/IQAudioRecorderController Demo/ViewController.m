//
//  ViewController.m
//  IQAudioRecorderController Demo


#import "ViewController.h"
#import "IQAudioRecorderViewController.h"

#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()<IQAudioRecorderViewControllerDelegate,UITextFieldDelegate>
{
    IBOutlet UIBarButtonItem *buttonPlayAudio;
    NSString *audioFilePath;

    IBOutlet UITextField *textFieldTitle;
    IBOutlet UISwitch *switchDarkUserInterface;
    IBOutlet UISwitch *switchAllowsCropping;
    IBOutlet UISwitch *switchBlurEnabled;
    
    IBOutlet UILabel *labelMaxDuration;
    IBOutlet UIStepper *stepperMaxDuration;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    buttonPlayAudio.enabled = NO;
}

- (IBAction)switchThemeAction:(UISwitch *)sender
{
    if (sender.on)
    {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    }
    else
    {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        self.navigationController.toolbar.barStyle = UIBarStyleDefault;
    }
}

- (IBAction)stepperDurationChanged:(UIStepper *)sender {
    labelMaxDuration.text = [NSString stringWithFormat:@"%.0f",sender.value];
}

- (IBAction)recordAction:(UIBarButtonItem *)sender
{
    IQAudioRecorderViewController *controller = [[IQAudioRecorderViewController alloc] init];
    controller.delegate = self;
    controller.title = textFieldTitle.text;
    controller.maximumRecordDuration = stepperMaxDuration.value;
    controller.allowCropping = switchAllowsCropping.on;
    
//    controller.normalTintColor = [UIColor magentaColor];
//    controller.highlightedTintColor = [UIColor orangeColor];
    
    if (switchDarkUserInterface.on)
    {
        controller.barStyle = UIBarStyleBlack;
    }
    else
    {
        controller.barStyle = UIBarStyleDefault;
    }

    if (switchBlurEnabled.on)
    {
        [self presentBlurredAudioRecorderViewControllerAnimated:controller];
    }
    else
    {
        [self presentAudioRecorderViewControllerAnimated:controller];
    }
}

-(void)audioRecorderController:(IQAudioRecorderViewController *)controller didFinishWithAudioAtPath:(NSString *)filePath
{
    audioFilePath = filePath;
    buttonPlayAudio.enabled = YES;
    [controller dismissViewControllerAnimated:YES completion:nil];
}

-(void)audioRecorderControllerDidCancel:(IQAudioRecorderViewController *)controller
{
    buttonPlayAudio.enabled = NO;
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)playAction:(UIBarButtonItem *)sender
{
    MPMoviePlayerViewController *controller = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:audioFilePath]];
    [self presentMoviePlayerViewControllerAnimated:controller];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
