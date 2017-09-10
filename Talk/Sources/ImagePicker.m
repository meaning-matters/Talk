//
//  ImagePicker.m
//  Talk
//
//  Created by Cornelis van der Bent on 02/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <Photos/Photos.h>
#import "ImagePicker.h"
#import "Common.h"
#import "Strings.h"
#import "Settings.h"
#import "BlockActionSheet.h"
#import "BlockAlertView.h"


@interface ImagePicker () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, weak) UIViewController* presentingViewController;
@property (nonatomic, copy) void (^completion)(NSData* imageData);

@end


@implementation ImagePicker

- (instancetype)initWithPresentingViewController:(UIViewController*)presentingViewController
{
    if (self = [super init])
    {
        self.presentingViewController = presentingViewController;
    }

    return self;
}


- (void)pickImageWithTitle:(NSString*)title completion:(void (^)(NSData* imageData))completion
{
    self.completion = completion;

    NSString* takePhotoTitle    = NSLocalizedStringWithDefaultValue(@"....", nil, [NSBundle mainBundle],
                                                                    @"Take Photo",
                                                                    @"...\n"
                                                                    @"[1/3 line small font].");
    NSString* photoLibraryTitle = NSLocalizedStringWithDefaultValue(@"....", nil, [NSBundle mainBundle],
                                                                    @"Photo Library",
                                                                    @"...\n"
                                                                    @"[1/3 line small font].");

    [BlockActionSheet showActionSheetWithTitle:title
                                    completion:^(BOOL cancelled, BOOL destruct, NSInteger buttonIndex)
    {
        switch (buttonIndex)
        {
            case 0:
            {
                [self checkCameraAccessWithCompletion:^(BOOL success)
                {
                    if (success)
                    {
                        UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];

                        imagePickerController.sourceType    = UIImagePickerControllerSourceTypeCamera;
                        imagePickerController.delegate      = self;
                        imagePickerController.allowsEditing = NO;
                        [self.presentingViewController presentViewController:imagePickerController
                                                                    animated:YES
                                                                  completion:nil];
                    }
                }];
                break;
            }
            case 1:
            {
                [self checkPhotosAccessWithCompletion:^(BOOL success)
                {
                    if (success)
                    {
                        UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];

                        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                        imagePickerController.delegate   = self;
                        [self.presentingViewController presentViewController:imagePickerController
                                                                    animated:YES
                                                                  completion:nil];
                      }
                }];
                break;
            }
            case 2:
            {
                // Cancelled.
                self.completion(nil);
                break;
            }
         }
     }
                             cancelButtonTitle:[Strings cancelString]
                        destructiveButtonTitle:nil
                             otherButtonTitles:takePhotoTitle, photoLibraryTitle, nil];
}


#pragma Helpers

- (UIImage*)scaledImageWithImage:(UIImage*)image
{
    CGFloat maximumPixelCount = 1440 * 1080;
    CGFloat pixelCount        = image.size.width * image.size.height;
    CGFloat scaleFactor       = MIN(sqrt(maximumPixelCount / pixelCount), 1.0);
    CGSize  scaledSize        = CGSizeMake(image.size.width * scaleFactor, image.size.height * scaleFactor);

    UIGraphicsBeginImageContext(scaledSize);
    [image drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}


#pragma mark - Image Picker Delegate

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    UIImage* image = info[UIImagePickerControllerOriginalImage];

    image = [self scaledImageWithImage:image];

    NSData* data = UIImageJPEGRepresentation(image, 0.5);

    self.completion(data);

    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
    self.completion(nil);

    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Image Source Access Checking

- (void)checkCameraAccessWithCompletion:(void (^)(BOOL success))completion
{
    NSString* title;
    NSString* message;

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];

        switch (status)
        {
            case AVAuthorizationStatusAuthorized:
            {
                completion ? completion(YES) : 0;
                break;
            }
            case AVAuthorizationStatusDenied:
            {
                title   = NSLocalizedStringWithDefaultValue(@"", nil, [NSBundle mainBundle],
                                                            @"No Camera Access",
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                            @"%@ does not have access to the camera.\n\n"
                                                            @"To enable access, tap Settings and switch on Camera.",
                                                            @"");
                message = [NSString stringWithFormat:message, [Settings sharedSettings].appDisplayName];
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                {
                    if (!cancelled)
                    {
                        [Common openApplicationSettings];
                    }
                }
                                     cancelButtonTitle:[Strings cancelString]
                                     otherButtonTitles:[Strings iOsSettingsString], nil];
                break;
            }
            case AVAuthorizationStatusRestricted:
            {
                // Won't happen, because UIImagePickerControllerSourceTypeCamera won't be available first (see above).
                break;
            }
            case AVAuthorizationStatusNotDetermined:
            {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
                {
                    completion ? completion(granted) : 0;
                }];
                break;
            }
        }
    }
    else
    {
        title   = NSLocalizedStringWithDefaultValue(@"", nil, [NSBundle mainBundle],
                                                    @"Camera Restriction",
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                    @"The use of the camera is restricted on this device\n\n"
                                                    @"To enable access, go to iOS Settings > General > "
                                                    @"Restrictions and switch on Camera.",
                                                    @"");
        message = [NSString stringWithFormat:message, [Settings sharedSettings].appDisplayName];
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            completion ? completion(NO) : 0;
        }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:nil];
    }
}


- (void)checkPhotosAccessWithCompletion:(void (^)(BOOL success))completion
{
    NSString* title;
    NSString* message;

    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];

    switch (status)
    {
        case PHAuthorizationStatusAuthorized:
        {
            completion ? completion(YES) : 0;
            break;
        }
        case PHAuthorizationStatusDenied:
        {
            title   = NSLocalizedStringWithDefaultValue(@"", nil, [NSBundle mainBundle],
                                                        @"No Photos Access",
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                        @"%@ does not have access to your photos.\n\n"
                                                        @"To enable access, tap Settings and switch on Photos.",
                                                        @"");
            message = [NSString stringWithFormat:message, [Settings sharedSettings].appDisplayName];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                if (!cancelled)
                {
                    [Common openApplicationSettings];
                }
            }
                                 cancelButtonTitle:[Strings cancelString]
                                 otherButtonTitles:[Strings iOsSettingsString], nil];
            break;
        }
        case PHAuthorizationStatusRestricted:
        {
            title   = NSLocalizedStringWithDefaultValue(@"", nil, [NSBundle mainBundle],
                                                        @"Photos Restriction",
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                        @"Access to the photo library is restricted on this device\n\n"
                                                        @"To enable access, go to iOS Settings > General > "
                                                        @"Restrictions > Photos and switch on Camera.",
                                                        @"");
            message = [NSString stringWithFormat:message, [Settings sharedSettings].appDisplayName];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                completion ? completion(NO) : 0;
            }
                                 cancelButtonTitle:[Strings cancelString]
                                 otherButtonTitles:nil];
            break;
        }
        case PHAuthorizationStatusNotDetermined:
        {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
            {
                 completion ? completion(status == PHAuthorizationStatusAuthorized) : 0;
            }];
            break;
        }
    }
}

@end
