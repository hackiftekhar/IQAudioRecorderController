//
//  ViewController.m
//  IQAudioRecorderController Demo


#import "ViewController.h"
#import <IQAudioRecorderController/IQAudioRecorderViewController.h>
#import <IQAudioRecorderController/IQAudioCropperViewController.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ColorPickerTextField.h"

@interface ViewController ()<IQAudioRecorderViewControllerDelegate,IQAudioCropperViewControllerDelegate,ColorPickerTextFieldDelegate,UITextFieldDelegate>
{
    IBOutlet UIBarButtonItem *buttonPlayAudio;
    IBOutlet UIBarButtonItem *barButtonCrop;
    NSString *audioFilePath;

    IBOutlet ColorPickerTextField *normalTintColorTextField;
    IBOutlet ColorPickerTextField *highlightedTintColorTextField;

    UIColor *normalTintColor;
    UIColor *highlightedTintColor;

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
    barButtonCrop.enabled = NO;
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar sizeToFit];
    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    toolbar.items = @[flexItem,doneItem];
    normalTintColorTextField.inputAccessoryView = highlightedTintColorTextField.inputAccessoryView = toolbar;
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

#pragma Record

- (IBAction)recordAction:(UIBarButtonItem *)sender
{
    IQAudioRecorderViewController *controller = [[IQAudioRecorderViewController alloc] init];
    controller.delegate = self;
    controller.title = textFieldTitle.text;
    controller.maximumRecordDuration = stepperMaxDuration.value;
    controller.allowCropping = switchAllowsCropping.on;
    controller.normalTintColor = normalTintColor;
    controller.highlightedTintColor = highlightedTintColor;
    
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
    barButtonCrop.enabled = YES;

    [controller dismissViewControllerAnimated:YES completion:nil];
}

-(void)audioRecorderControllerDidCancel:(IQAudioRecorderViewController *)controller
{
    buttonPlayAudio.enabled = NO;
    barButtonCrop.enabled = NO;
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma Play

- (IBAction)playAction:(UIBarButtonItem *)sender
{
    MPMoviePlayerViewController *controller = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:audioFilePath]];
    [self presentMoviePlayerViewControllerAnimated:controller];
}

#pragma Crop

- (IBAction)cropAction:(UIBarButtonItem *)sender {

    IQAudioCropperViewController *controller = [[IQAudioCropperViewController alloc] initWithFilePath:audioFilePath];
    controller.delegate = self;
    controller.title = @"Crop";
    controller.normalTintColor = normalTintColor;
    controller.highlightedTintColor = highlightedTintColor;

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
        [self presentBlurredAudioCropperViewControllerAnimated:controller];
    }
    else
    {
        [self presentAudioCropperViewControllerAnimated:controller];
    }
}

-(void)audioCropperController:(IQAudioCropperViewController *)controller didFinishWithAudioAtPath:(NSString *)filePath
{
    audioFilePath = filePath;
    [controller dismissViewControllerAnimated:YES completion:nil];
}

-(void)audioCropperControllerDidCancel:(IQAudioCropperViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma Color Picker

-(void)colorPickerTextField:(nonnull ColorPickerTextField*)textField selectedColorAttributes:(nonnull NSDictionary<NSString*,id>*)colorAttributes
{
    if (textField.tag == 4)
    {
        normalTintColor = textField.selectedColor;
    }
    else if (textField.tag == 5)
    {
        highlightedTintColor = textField.selectedColor;
    }
}

#pragma TextField

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)doneAction:(UIBarButtonItem*)item
{
    [self.view endEditing:YES];
}

@end
