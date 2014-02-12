//
//  Common.m
//  Talk
//
//  Created by Cornelis van der Bent on 30/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <sys/utsname.h>
#import "Common.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "Settings.h"
#import "AppDelegate.h"
#import "CountriesViewController.h"
#import "ProvisioningViewController.h"
#import "AFNetworkActivityIndicatorManager.h"


@implementation Common

+ (NSURL*)documentsDirectoryUrl
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


+ (NSURL*)documentUrl:(NSString*)name
{
    return [[Common documentsDirectoryUrl] URLByAppendingPathComponent:name];
}


+ (NSURL*)audioDirectoryUrl
{
    NSURL*  url = [[Common documentsDirectoryUrl] URLByAppendingPathComponent:@"audio/"];

    [[NSFileManager defaultManager] createDirectoryAtURL:url
                             withIntermediateDirectories:YES
                                                     attributes:nil
                                                   error:nil];

    return url;
}


+ (NSURL*)audioUrl:(NSString*)name
{
    return [[Common audioDirectoryUrl] URLByAppendingPathComponent:name];
}


+ (NSData*)dataForResource:(NSString*)resourse ofType:(NSString*)type
{
    NSString*   path = [[NSBundle mainBundle] pathForResource:resourse ofType:type];
    NSData*     data = [NSData dataWithContentsOfFile:path];
    
    return data;
}


+ (NSString*)bundleVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
}


+ (NSString*)bundleName
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey];
}


+ (NSString*)appStoreUrlString
{
    NSString*   appName = [[Common bundleName] stringByReplacingOccurrencesOfString:@" " withString:@""];

    return [NSString stringWithFormat:@"http://itunes.com/apps/%@", appName];
}


+ (NSData*)jsonDataWithObject:(id)object
{
    NSError*                error = nil;
    NSData*                 data;
    NSJSONWritingOptions    options;
    
#ifdef  DEBUG
    options = NSJSONWritingPrettyPrinted;
#else
    options = 0;
#endif
    
    data = [NSJSONSerialization dataWithJSONObject:object options:options error:&error];
    
    if (error != nil)
    {
        //### Replace.
        NSLog(@"Error serializing to JSON data: %@", error.localizedDescription);
        
        return nil;
    }
    else
    {
        return data;
    }
}


+ (NSString*)jsonStringWithObject:(id)object
{
    NSData*     data;
    NSString*   string;
    
    data   = [Common jsonDataWithObject:object];
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    return string;
}


+ (id)objectWithJsonData:(NSData*)data
{
    NSError*    error = nil;
    id          object;
    
    object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error != nil)
    {
        //### Replace.
        NSLog(@"Error serializing from JSON data: %@", error.localizedDescription);
        
        return nil;
    }
    else
    {
        return object;
    }
}


+ (id)objectWithJsonString:(NSString*)string
{
    id          object;
    NSData*     data;
    
    data   = [string dataUsingEncoding:NSUTF8StringEncoding];
    object = [Common objectWithJsonData:data];
    
    return object;
}


+ (id)mutableObjectWithJsonData:(NSData*)data
{
    NSError*                error = nil;
    id                      object;
    NSJSONReadingOptions    options = NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves;

    object = [NSJSONSerialization JSONObjectWithData:data options:options error:&error];

    if (error != nil)
    {
        //### Replace.
        NSLog(@"Error serializing from JSON data: %@", error.localizedDescription);

        return nil;
    }
    else
    {
        return object;
    }
}


+ (id)mutableObjectWithJsonString:(NSString*)string
{
    id      object;
    NSData* data;

    data   = [string dataUsingEncoding:NSUTF8StringEncoding];
    object = [Common mutableObjectWithJsonData:data];

    return object;
}


+ (NSError*)errorWithCode:(NSInteger)code description:(NSString*)description
{
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
    NSError*      error    = [[NSError alloc] initWithDomain:[Settings sharedSettings].errorDomain
                                                        code:code
                                                    userInfo:userInfo];

    return error;
}


+ (BOOL)deviceHasReceiver
{
    return [[UIDevice currentDevice].model isEqualToString:@"iPhone"];
}


// Add: http://stackoverflow.com/questions/1108859/detect-the-specific-iphone-ipod-touch-model
+ (NSString*)deviceModel
{
    struct utsname  systemInfo;

    uname(&systemInfo);

    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}


+ (void)setCornerRadius:(CGFloat)radius ofView:(UIView*)view
{
    view.layer.cornerRadius = radius;
    view.layer.masksToBounds = YES;
}


+ (void)setBorderWidth:(CGFloat)width ofView:(UIView*)view
{
    view.layer.borderWidth = width;
}


+ (void)setBorderColor:(UIColor*)color ofView:(UIView*)view
{
    view.layer.borderColor = [color CGColor];
}


+ (void)setX:(CGFloat)x ofView:(UIView*)view
{
    CGRect  frame;

    frame = view.frame;
    frame.origin.x = x;
    view.frame = frame;
}


+ (void)setY:(CGFloat)y ofView:(UIView*)view
{
    CGRect  frame;

    frame = view.frame;
    frame.origin.y = y;
    view.frame = frame;
}


+ (void)setWidth:(CGFloat)width ofView:(UIView*)view;
{
    CGRect  frame;

    frame = view.frame;
    frame.size.width = width;
    view.frame = frame;
}


+ (void)setHeight:(CGFloat)height ofView:(UIView*)view
{
    CGRect  frame;

    frame = view.frame;
    frame.size.height = height;
    view.frame = frame;
}


// Returns hidden iOS font with nice * # +.
// List of fonts: http://www.prepressure.com/fonts/basics/ios-4-fonts
+ (UIFont*)phoneFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:@".PhonepadTwo" size:size];
}


+ (NSString*)stringWithOsStatus:(OSStatus)status
{
    char    error[sizeof(OSStatus) + 1];

    *(OSStatus*)error = status;
    error[sizeof(OSStatus)] = '\0';

    return [NSString stringWithFormat:@"%s", error];
}


+ (BOOL)checkRemoteNotifications
{
    UIRemoteNotificationType notificationTypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    if (!(notificationTypes & UIRemoteNotificationTypeAlert) || !(notificationTypes & UIRemoteNotificationTypeBadge))
    {
        NSString*   title;
        NSString*   message;

        title   = NSLocalizedStringWithDefaultValue(@"General:AppStatus NoNotificationsTitle", nil,
                                                    [NSBundle mainBundle], @"Notications Disabled",
                                                    @"Alert title telling that required notifications are disabled.\n"
                                                    @"[iOS alert title size - abbreviated: 'Can't Pay'].");
        message = NSLocalizedStringWithDefaultValue(@"General:AppStatus NoNotificationsMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"At least Alert and Badge notifications must be enabled.\n"
                                                    @"Go to iOS Settings > Notifications > %@.",
                                                    @"Alert message telling that required notifications are disabled.\n"
                                                    @"[iOS alert message size - use correct iOS terms for: Settings "
                                                    @"and Notifications!]");
        message = [NSString stringWithFormat:message, [Common bundleName]];
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];

        return NO;
    }
    else if ([[AppDelegate appDelegate].deviceToken length] == 0)
    {
        NSString*   title;
        NSString*   message;

        title   = NSLocalizedStringWithDefaultValue(@"General:AppStatus NotificationsUnavailableTitle", nil,
                                                    [NSBundle mainBundle], @"Notifications Unavailable",
                                                    @"Alert title telling that app is not ready yet.\n"
                                                    @"[iOS alert title size - abbreviated: 'Can't Pay'].");
        message = NSLocalizedStringWithDefaultValue(@"General:AppStatus NotificationsUnavailableMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"The app is not ready to receive notifications, "
                                                    @"please try again a little later.",
                                                    @"Alert message telling that app is not ready yet.\n"
                                                    @"[iOS alert message size - use correct iOS term for: Notifications!]");
        message = [NSString stringWithFormat:message, [Common bundleName]];
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];

        return NO;
    }
    else
    {
        return YES;
    }
}


+ (BOOL)checkSendingEmail
{
    if ([MFMailComposeViewController canSendMail] == YES)
    {
        return YES;
    }
    else
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"General NoMailAccountTitle", nil,
                                                    [NSBundle mainBundle], @"No Email Accounts",
                                                    @"Alert title that no text message (SMS) can be send\n"
                                                    @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"General NoEmailAccountMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"There are no email accounts configured. You can add an email "
                                                    @"account in iOS Settings > Mail > Add Account.",
                                                    @"Alert message that no email can be send\n"
                                                    @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];

        return NO;
    }
}


+ (BOOL)checkSendingTextMessage
{
    if ([MFMessageComposeViewController canSendText])
    {
        return YES;
    }
    else
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"General NoTextMessageTitle", nil,
                                                    [NSBundle mainBundle], @"Can't Send Message",
                                                    @"Alert title that no text message (SMS) can be send\n"
                                                    @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"General NoTextMessageMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"You can't send a text message now. You can enable iMessage in "
                                                    @"iOS Settings > Messages.",
                                                    @"Alert message that no text message (SMS) can be send\n"
                                                    @"[iOS alert message size - Settings, iMessage and Message are "
                                                    @"iOS terms]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];

        return NO;
    }
}


// Checks only non-emergency number.
+ (BOOL)checkCountryOfPhoneNumber:(PhoneNumber*)phoneNumber
                       completion:(void (^)(BOOL cancelled, PhoneNumber* phoneNumber))completion
{
    static UIAlertView* alertView;
    BOOL                result;
    NSString*           title;
    NSString*           message;
    NSString*           buttonTitle;

    if ([[Settings sharedSettings].homeCountry length] == 0 && [phoneNumber isInternational] == NO)
    {
        // Prevent alert being shown more than once.
        if (alertView != nil)
        {
            return NO;
        }
        
        title       = NSLocalizedStringWithDefaultValue(@"General:AppStatus CountryUnknownTitle", nil,
                                                        [NSBundle mainBundle], @"Country Unknown",
                                                        @"Alert title informing about home country being unknown\n"
                                                        @"[iOS alert title size].");

        message     = NSLocalizedStringWithDefaultValue(@"General:AppStatus CountryUnknownMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"The country for this (local) number can't be determined. "
                                                        @"Select the default country, or enter an international number.",
                                                        @"Alert message informing about home country being unknown\n"
                                                        @"[iOS alert message size]");

        buttonTitle = NSLocalizedStringWithDefaultValue(@"General:AppStatus CountryUnknownButton", nil,
                                                        [NSBundle mainBundle], @"Select",
                                                        @"Alert button title for selecting home country\n"
                                                        @"[iOS small alert button size]");

        alertView = [BlockAlertView showAlertViewWithTitle:title
                                                   message:message
                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            if (buttonIndex == 1)
            {
                CountriesViewController*    countriesViewController;
                UINavigationController*     modalViewController;
                UIViewController*           topViewController;
                NSString*                   homeCountry = [Settings sharedSettings].homeCountry;

                countriesViewController = [[CountriesViewController alloc] initWithIsoCountryCode:homeCountry
                                                                                       completion:^(BOOL      cancelled,
                                                                                                    NSString* isoCountryCode)
                {
                    if (cancelled == NO)
                    {
                        [Settings sharedSettings].homeCountry = isoCountryCode;
                    }

                    completion ? completion(cancelled, phoneNumber) : 0;
                }];

                countriesViewController.isModal = YES;

                modalViewController = [[UINavigationController alloc] initWithRootViewController:countriesViewController];
                modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

                topViewController = [AppDelegate appDelegate].window.rootViewController;

                if (topViewController.presentedViewController != nil)
                {
                    topViewController = topViewController.presentedViewController;
                }
            
                // topViewController = [[[[UIApplication sharedApplication] keyWindow] subviews][0] nextResponder];

                [topViewController presentViewController:modalViewController animated:YES completion:^
                {
                    alertView = nil;
                }];
            }
            else
            {
                alertView = nil;
                
                completion ? completion(YES, phoneNumber) : 0;
            }
        }
                                         cancelButtonTitle:[Strings cancelString]
                                         otherButtonTitles:buttonTitle, nil];

        result = NO;
    }
    else
    {
        result = YES;
    }
    
    return result;
}


+ (void)enableNetworkActivityIndicator:(BOOL)enable
{
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;

    if (enable == YES)
    {
        [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    }
    else
    {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }
}


// This will redirect NSLog() output to a log file.  Switch on 'Application supports iTunes file sharing'
// in the app's .plist file to allow accessing the logs from iTunes.  Don't forget to set this .plist
// parameter to NO before distributing the app (unless it's on intentionally)!
#warning //### Automate this, switch on for DEBUG only for example: http://stackoverflow.com/questions/13689934/is-there-a-way-of-automatically-writing-custom-values-to-the-bundles-plist-dur
+ (void)redirectStderrToFile
{
    NSArray*    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString*   documentsDirectory = [paths objectAtIndex:0];
    NSString*   fileName =[NSString stringWithFormat:@"%@.log", [NSDate date]];
    NSString*   logFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];

    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
}


+ (unsigned)bitsSetCount:(unsigned long)value
{
    unsigned count = 0;
    
    while (value)
    {
        count += value & 1;
        value >>= 1;
    }

    return count;
}


// Returns the bit-mask of the N-th bit that is set in `value`.
+ (unsigned long)nthBitSet:(unsigned)n inValue:(unsigned long)value
{
    unsigned long   bit = 1;

    while (value)
    {
        if ((value & 1) && (n-- == 0))
        {
            break;
        }

        bit   <<= 1;
        value >>= 1;
    }

    return bit;
}


// Returns the set-bits index (so only counting the bits that are set) of `bit` in `value`.
+ (unsigned)nOfBit:(unsigned long)bit inValue:(unsigned long)value
{
    unsigned n = [Common bitsSetCount:value];

    while ([Common nthBitSet:n inValue:value] != bit && n > 0)
    {
        n--;
    }

    return n;
}


+ (unsigned long)bitIndex:(unsigned long)value
{
    unsigned long   index = 0;

    while (value >> 1)
    {
        index++;
        value >>= 1;
    }

    return index;
}


+ (NSString*)capitalizedString:(NSString*)string
{
    NSLocale* locale = [NSLocale currentLocale];

    return [string capitalizedStringWithLocale:locale];
}


+ (void)showProvisioningViewController
{
    ProvisioningViewController* provisioningViewController;

    provisioningViewController = [[ProvisioningViewController alloc] init];
    provisioningViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [AppDelegate.appDelegate.tabBarController presentViewController:provisioningViewController
                                                           animated:YES
                                                         completion:nil];
}


+ (void)dispatchAfterInterval:(NSTimeInterval)interval onMain:(void (^)(void))block
{
    double          delayInSeconds = interval;
    dispatch_time_t when           = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));

    dispatch_after(when, dispatch_get_main_queue(), block);
}


+ (void)addCountryImageToCell:(UITableViewCell*)cell isoCountryCode:(NSString*)isoCountryCode
{
    static const int CountryCellTag = 4321;

    UIImage*     image     = [UIImage imageNamed:isoCountryCode];
    UIImageView* imageView = (UIImageView*)[cell viewWithTag:CountryCellTag];
    CGRect       frame     = CGRectMake(33, 4, image.size.width, image.size.height);

    imageView       = (imageView == nil) ? [[UIImageView alloc] initWithFrame:frame] : imageView;
    imageView.tag   = CountryCellTag;
    imageView.image = image;

    [cell.contentView addSubview:imageView];
}


+ (BOOL)indexPath:(NSIndexPath*)indexPathA isEqual:(NSIndexPath*)indexPathB
{
    return (indexPathA.section == indexPathB.section) && (indexPathA.row == indexPathB.row);
}


+ (UIImage*)invertImage:(UIImage*)image
{
    // Get width and height as integers, since we'll be using them as
    // array subscripts, etc, and this'll save a whole lot of casting.
    CGSize size = image.size;
    int width   = size.width  * image.scale;
    int height  = size.height * image.scale;

    // Create a suitable RGB+alpha bitmap context in BGRA colour space.
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char*  memoryPool  = (unsigned char*)calloc(width * height * 4, 1);
    CGContextRef    context = CGBitmapContextCreate(memoryPool, width, height, 8, width * 4, colourSpace,
                                                    kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colourSpace);

    // Draw the current image to the newly created context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);

    // Run through every pixel, a scan line at a time...
    for (int y = 0; y < height; y++)
    {
        // Get a pointer to the start of this scan line.
        unsigned char* linePointer = &memoryPool[y * width * 4];

        // Step through the pixels one by one...
        for (int x = 0; x < width; x++)
        {
            // Get RGB values.  We're dealing with premultiplied alpha here, so we need
            // to divide by the alpha channel (if it isn't zero, of course) to get
            // uninflected RGB.  We multiply by 255 to keep precision while still using
            // integers
            int r, g, b;
            if(linePointer[3])
            {
                r = linePointer[0] * 255 / linePointer[3];
                g = linePointer[1] * 255 / linePointer[3];
                b = linePointer[2] * 255 / linePointer[3];
            }
            else
            {
                r = g = b = 0;
            }

            // perform the colour inversion
            r = 255 - r;
            g = 255 - g;
            b = 255 - b;

            // Multiply by alpha again, divide by 255 to undo the scaling before, store
            // the new values and advance the pointer we're reading pixel data from.
            linePointer[0] = r * linePointer[3] / 255;
            linePointer[1] = g * linePointer[3] / 255;
            linePointer[2] = b * linePointer[3] / 255;
            linePointer += 4;
        }
    }

    // Get a CG image from the context, wrap that into a UIImage.
    CGImageRef cgImage     = CGBitmapContextCreateImage(context);
    UIImage*   returnImage = [UIImage imageWithCGImage:cgImage];

    // Clean up.
    CGImageRelease(cgImage);
    CGContextRelease(context);
    free(memoryPool);
    
    return returnImage;
}


+ (UITextField*)addTextFieldToCell:(UITableViewCell*)cell delegate:(id<UITextFieldDelegate>)delegate
{
    UITextField*    textField;
    CGRect          frame = CGRectMake(83, 6, 210, 30);

    textField = [[UITextField alloc] initWithFrame:frame];
    [textField setFont:[UIFont boldSystemFontOfSize:15]];

    textField.adjustsFontSizeToFitWidth = NO;
    textField.autocapitalizationType    = UITextAutocapitalizationTypeWords;
    textField.autocorrectionType        = UITextAutocorrectionTypeNo;
    textField.clearButtonMode           = UITextFieldViewModeWhileEditing;
    textField.contentVerticalAlignment  = UIControlContentVerticalAlignmentCenter;
    textField.returnKeyType             = UIReturnKeyDone;

    textField.delegate                  = delegate;

    [cell.contentView addSubview:textField];

    return textField;
}

@end
