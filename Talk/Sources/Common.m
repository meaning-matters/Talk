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
#import "AFNetworkActivityIndicatorManager.h"
#import "Skinning.h"
#import "GetStartedViewController.h"


@interface Common ()

@property (nonatomic, copy) void (^emailCompletion)(BOOL success);

@end


@implementation Common

static Common* sharedCommon;

+ (Common*)sharedCommon
{
    static Common*         sharedInstance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[Common alloc] init];
    });
    
    return sharedInstance;
}


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


+ (UIViewController*)topViewController
{
    UIViewController* viewController;

    viewController = [AppDelegate appDelegate].window.rootViewController;

    if (viewController.presentedViewController != nil)
    {
        viewController = viewController.presentedViewController;
    }

    // viewController = [[[[UIApplication sharedApplication] keyWindow] subviews][0] nextResponder];

    return viewController;
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


+ (BOOL)object:(id)object isEqualToJsonString:(NSString*)string
{
    NSString* objectJson       = [self jsonStringWithObject:object];
    id        stringObject     = [self objectWithJsonString:string];
    NSString* stringObjectJson = [self jsonStringWithObject:stringObject];

    return [objectJson isEqualToString:stringObjectJson];
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


+ (void)addShadowToView:(UIView*)view
{
    view.layer.shadowColor   = [[UIColor blackColor] CGColor];
    view.layer.shadowOpacity = 0.5f;
    view.layer.shadowOffset  = CGSizeMake(0.0f, 1.0f);
    view.layer.shadowRadius  = 1.0f;
}


+ (void)styleButton:(UIButton*)button withColor:(UIColor*)color highlightTextColor:(UIColor*)highlightTextColor
{
    [Common setBorderWidth:1  ofView:button];
    [Common setCornerRadius:5 ofView:button];

    [Common setBorderColor:color             ofView:button];
    [button setTitleColor:color              forState:UIControlStateNormal];
    [button setTitleColor:highlightTextColor forState:UIControlStateHighlighted];

    UIGraphicsBeginImageContextWithOptions(button.frame.size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [color setFill];
    CGContextFillRect(context, CGRectMake(0, 0, button.frame.size.width, button.frame.size.height));
    UIImage*     image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [button setBackgroundImage:image forState:UIControlStateHighlighted];
}


+ (void)styleButton:(UIButton*)button
{
    [self styleButton:button withColor:[Skinning tintColor] highlightTextColor:[UIColor whiteColor]];
}


// Returns hidden iOS font with nice * # +.
// List of fonts: http://www.prepressure.com/fonts/basics/ios-6-typefaces
+ (UIFont*)phoneFontOfSize:(CGFloat)size
{
    // Obscure ".PhonepadTwo".
    return [UIFont fontWithName:[NSString stringWithFormat:@".%@%@Two", @"Phone", @"pad"] size:size];
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
        NSString* button;

        title   = NSLocalizedStringWithDefaultValue(@"General NoMailAccountTitle", nil,
                                                    [NSBundle mainBundle], @"No Email Account",
                                                    @"Alert title that no text message (SMS) can be send\n"
                                                    @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"General NoEmailAccountMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"There is no email account configured.\n\nSet up your email "
                                                    @"account now in iOS Settings > Mail, Contacts, Calendars > "
                                                    @"Add Account, or cancel.",
                                                    @"Alert message that no email can be send\n"
                                                    @"[iOS alert message size]");

        button  = NSLocalizedStringWithDefaultValue(@"General GoToiOSSettingButtonTitle", nil,
                                                    [NSBundle mainBundle], @"Settings",
                                                    @"...\n"
                                                    @"[iOS alert title size].");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            if (cancelled == NO)
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:info@numberbay.com"]];
            }
        }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:button, nil];

        return NO;
    }
}


+ (void)sendEmailTo:(NSString*)emailAddress
            subject:(NSString*)subject
               body:(NSString*)body
         completion:(void (^)(BOOL success))completion;
{
    if ([self checkSendingEmail] == YES)
    {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = [self sharedCommon];
        [controller setSubject:subject];
        [controller setMessageBody:body isHTML:NO];
        [controller setToRecipients:@[emailAddress]];

        [self sharedCommon].emailCompletion = completion;

        [[self topViewController] presentViewController:controller animated:YES completion:nil];
    }
}


#pragma mark - Mail Compose Delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    if (result == MFMailComposeResultSent)
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"Common EmailSentTitle", nil, [NSBundle mainBundle],
                                                    @"Email Underway",
                                                    @"Alert title that sending an email is in progress\n"
                                                    @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"Common EmailSentMessage", nil, [NSBundle mainBundle],
                                                    @"Thanks for contacting us!  Your email has been placed "
                                                    @"in your outbox, or has already been sent.\n\n"
                                                    @"We do our best to respond within 48 hours.",
                                                    @"Alert message that sending an email is in progress\n"
                                                    @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            self.emailCompletion ? self.emailCompletion(YES) : 0;
            self.emailCompletion = nil;

            [[Common topViewController] dismissViewControllerAnimated:YES completion:nil];
        }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
    else if (result == MFMailComposeResultFailed)
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"Common EmailFailedTitle", nil,
                                                    [NSBundle mainBundle], @"Failed To Send Email",
                                                    @"Alert title that sending an email failed\n"
                                                    @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"Common EmailFailedMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"Sending the email message failed: %@.",
                                                    @"Alert message that sending an email failed\n"
                                                    @"[iOS alert message size]");

        message = [NSString stringWithFormat:message, [error localizedDescription]];

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            self.emailCompletion ? self.emailCompletion(NO) : 0;
            self.emailCompletion = nil;

            [[Common topViewController] dismissViewControllerAnimated:YES completion:nil];
        }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
    else
    {
        self.emailCompletion ? self.emailCompletion(YES) : 0;
        self.emailCompletion = nil;

        [[Common topViewController] dismissViewControllerAnimated:YES completion:nil];
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
                                                        @"The country for this (local) number can't be determined.\n\n"
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

                [[self topViewController] presentViewController:modalViewController animated:YES completion:^
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


+ (NSString*)capitalizedString:(NSString*)string
{
    NSLocale* locale = [NSLocale currentLocale];

    return [string capitalizedStringWithLocale:locale];
}


+ (void)showGetStartedViewController
{
    UINavigationController*   navigationController;
    GetStartedViewController* viewController;

    viewController = [[GetStartedViewController alloc] initShowAsIntro:NO];
    navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];

    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [[self topViewController] presentViewController:navigationController
                                                           animated:YES
                                                         completion:nil];
}


+ (void)dispatchAfterInterval:(NSTimeInterval)interval onMain:(void (^)(void))block
{
    double          delayInSeconds = interval;
    dispatch_time_t when           = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));

    dispatch_after(when, dispatch_get_main_queue(), block);
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


+ (void)addCountryImageToCell:(UITableViewCell*)cell isoCountryCode:(NSString*)isoCountryCode
{
    static const int CountryCellTag = 4321;

    UIImage*     image     = [UIImage imageNamed:isoCountryCode];
    UIImageView* imageView = (UIImageView*)[cell viewWithTag:CountryCellTag];
    CGRect       frame     = CGRectMake(15, 4, image.size.width, image.size.height);

    imageView       = (imageView == nil) ? [[UIImageView alloc] initWithFrame:frame] : imageView;
    imageView.tag   = CountryCellTag;
    imageView.image = image;

    [cell.contentView addSubview:imageView];
}


+ (NumberLabel*)addNumberLabelToCell:(UITableViewCell*)cell
{
    NumberLabel* label;
    CGRect       frame = CGRectMake(80, 7, 225, 30);

    label = [[NumberLabel alloc] initWithFrame:frame];

    label.backgroundColor        = [UIColor clearColor];
    label.userInteractionEnabled = YES;
    label.textAlignment          = NSTextAlignmentRight;
    label.textColor              = [UIColor grayColor];

    label.menuTargetRect = CGRectMake(80, 12, 160, 8);

    [cell.contentView addSubview:label];

    return label;
}


+ (UITextField*)addTextFieldToCell:(UITableViewCell*)cell delegate:(id<UITextFieldDelegate>)delegate
{
    UITextField* textField;
    CGRect       frame = CGRectMake(80, 2, 224, 42);

    textField = [[UITextField alloc] initWithFrame:frame];

    textField.adjustsFontSizeToFitWidth = NO;
    textField.autocapitalizationType    = UITextAutocapitalizationTypeWords;
    textField.autocorrectionType        = UITextAutocorrectionTypeNo;
    textField.clearButtonMode           = UITextFieldViewModeNever;
    textField.contentVerticalAlignment  = UIControlContentVerticalAlignmentCenter;
    textField.textAlignment             = NSTextAlignmentRight;
    textField.textColor                 = [Skinning tintColor];
    textField.returnKeyType             = UIReturnKeyDone;

    textField.delegate                  = delegate;

    [cell.contentView addSubview:textField];

    return textField;
}

@end
