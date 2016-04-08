<p align="center">
  <img src="https://raw.githubusercontent.com/hackiftekhar/IQAudioRecorderController/master/Screenshot/iconScreenshot.png" alt="Icon"/>
</p>
<H1 align="center">IQAudioRecorderController</H1>

`IQAudioRecorderController` is a drop-in universal library allows to record and crop audio within the app with a nice User Interface. There are also optional callback delegate methods to return recorded file path.

## Screenshot
![Idle](./Screenshot/Screenshot_Idle.jpeg)
![Recording](./Screenshot/Screenshot_Recording.jpg)
![Playing](./Screenshot/Screenshot_Playing.jpeg)
![No Access](./Screenshot/Screenshot_Cropping.jpg)

## Cocoapod:-

pod 'IQAudioRecorderController'

## Supported format
Currently `IQAudioRecorderController` library only support **.m4a** file format.

## Customisation
There are optional properties to customise the appearance according to your app theme.

***UIBarStyle barStyle***
Library support light and dark style UI for user interface. If you would like to present light style UI then you need to set barStyle to UIBarStyleDefault, otherwise dark style UI is the default.

***UIColor *normalTintColor***
This tintColor is used for showing wave tintColor while not recording, it is also used for top navigationBar and bottom toolbar tintColor.

***UIColor *highlightedTintColor***
Highlighted tintColor is used when playing recorded audio file or when recording audio file.


## How to use

There are two seprate classes to Record and Crop Audio files.

To Record audio file, try something like this:-

```objc
#import "IQAudioRecorderViewController.h"

@interface ViewController ()<IQAudioRecorderViewControllerDelegate>
@end

@implementation ViewController

- (void)recordAction:(id)sender
{
    IQAudioRecorderViewController *controller = [[IQAudioRecorderViewController alloc] init];
    controller.delegate = self;
    controller.title = "Recorder";
    controller.maximumRecordDuration = 10;
    controller.allowCropping = YES;
//    controller.barStyle = UIBarStyleDefault;
//    controller.normalTintColor = [UIColor magentaColor];
//    controller.highlightedTintColor = [UIColor orangeColor];
    [self presentBlurredAudioRecorderViewControllerAnimated:controller];
}

-(void)audioRecorderController:(IQAudioRecorderViewController *)controller didFinishWithAudioAtPath:(NSString *)filePath
{
    //Do your custom work with file at filePath.
    [controller dismissViewControllerAnimated:YES completion:nil];
}

-(void)audioRecorderControllerDidCancel:(IQAudioRecorderViewController *)controller
{
    //Notifying that user has clicked cancel.
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
```

To Crop audio file, try something like this:-

```objc
#import "IQAudioCropperViewController.h"

@interface ViewController ()<IQAudioCropperViewControllerDelegate>
@end

@implementation ViewController

-(void)cropAction:(id)item
{
    IQAudioCropperViewController *controller = [[IQAudioCropperViewController alloc] initWithFilePath:filePath];
    controller.delegate = self;
    controller.title = "Edit";
//    controller.barStyle = UIBarStyleDefault;
//    controller.normalTintColor = [UIColor magentaColor];
//    controller.highlightedTintColor = [UIColor orangeColor];
    [self presentBlurredAudioCropperViewControllerAnimated:controller];
}

-(void)audioCropperController:(IQAudioCropperViewController *)controller didFinishWithAudioAtPath:(NSString *)filePath
{
    //Do your custom work with file at filePath.
    [controller dismissViewControllerAnimated:YES completion:nil];
}

-(void)audioCropperControllerDidCancel:(IQAudioCropperViewController *)controller
{
    //Notifying that user has clicked cancel.
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
```



## Attributions

Thanks to [Stefan Ceriu](https://github.com/stefanceriu) for his brilliant [SCSiriWaveformView](https://github.com/stefanceriu/SCSiriWaveformView) library.

Thanks to [William Entriken](https://github.com/fulldecent) for his [FDWaveformView](https://github.com/fulldecent/FDWaveformView) library.

## LICENSE

Distributed under the MIT License.

## Contributions

Any contribution is more than welcome! You can contribute through pull requests and issues on GitHub.

## Author

If you wish to contact me, email at: hack.iftekhar@gmail.com
