//
//  Common.m
//  Talk
//
//  Created by Cornelis van der Bent on 30/09/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import "Common.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "Settings.h"
#import "AppDelegate.h"
#import "CountriesViewController.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "Skinning.h"
#import "GetStartedViewController.h"
#import "WebClient.h"
#import "PurchaseManager.h"


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


+ (void)openAppStoreReviewPage
{
    // 642013221 is the Apple ID for this app.
    NSString* urlString =  @"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?"
                           @"id=642013221&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8";

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}


+ (void)addCompanyToAddressBook:(ABAddressBookRef)addressBook
{
    ABRecordRef person = ABPersonCreate();

    NSString* venueName     = [Settings sharedSettings].companyName;
    NSString* venueUrl      = [Settings sharedSettings].companyWebsite;
    NSString* venueEmail    = [Settings sharedSettings].companyEmail;
    NSString* venuePhone    = [Settings sharedSettings].companyPhone;
    NSString* venueAddress1 = [Settings sharedSettings].companyAddress1;
    NSString* venueAddress2 = [Settings sharedSettings].companyAddress2;
    NSString* venueCity     = [Settings sharedSettings].companyCity;
    NSString* venueState    = nil;
    NSString* venueZip      = [Settings sharedSettings].companyPostcode;
    NSString* venueCountry  = [Settings sharedSettings].companyCountry;
    UIImage*  venueImage    = [UIImage imageNamed:@"Icon-152.png"];

    ABRecordSetValue(person, kABPersonOrganizationProperty, (__bridge CFStringRef)venueName, NULL);

    if (venueUrl)
    {
        ABMutableMultiValueRef urlMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(urlMultiValue, (__bridge CFStringRef) venueUrl, kABPersonHomePageLabel, NULL);
        ABRecordSetValue(person, kABPersonURLProperty, urlMultiValue, nil);
        CFRelease(urlMultiValue);
    }

    if (venueEmail)
    {
        ABMutableMultiValueRef emailMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(emailMultiValue, (__bridge CFStringRef) venueEmail, kABWorkLabel, NULL);
        ABRecordSetValue(person, kABPersonEmailProperty, emailMultiValue, nil);
        CFRelease(emailMultiValue);
    }

    if (venuePhone)
    {
        ABMutableMultiValueRef phoneNumberMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        NSArray*               venuePhoneNumbers     = [venuePhone componentsSeparatedByString:@" or "];

        for (NSString *venuePhoneNumberString in venuePhoneNumbers)
        {
            ABMultiValueAddValueAndLabel(phoneNumberMultiValue, (__bridge CFStringRef) venuePhoneNumberString, kABPersonPhoneMainLabel, NULL);
        }

        ABRecordSetValue(person, kABPersonPhoneProperty, phoneNumberMultiValue, nil);
        CFRelease(phoneNumberMultiValue);
    }

    ABMutableMultiValueRef multiAddress      = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
    NSMutableDictionary*   addressDictionary = [[NSMutableDictionary alloc] init];

    if (venueAddress1)
    {
        if (venueAddress2)
        {
            addressDictionary[(NSString *) kABPersonAddressStreetKey] = [NSString stringWithFormat:@"%@\n%@", venueAddress1, venueAddress2];
        }
        else
        {
            addressDictionary[(NSString *) kABPersonAddressStreetKey] = venueAddress1;
        }
    }

    if (venueCity)
    {
        addressDictionary[(NSString *)kABPersonAddressCityKey] = venueCity;
    }

    if (venueState)
    {
        addressDictionary[(NSString *)kABPersonAddressStateKey] = venueState;
    }

    if (venueZip)
    {
        addressDictionary[(NSString *)kABPersonAddressZIPKey] = venueZip;
    }

    if (venueCountry)
    {
        addressDictionary[(NSString *)kABPersonAddressCountryKey] = venueCountry;
    }

    if (venueImage)
    {
        ABPersonSetImageData(person, (__bridge CFDataRef)UIImagePNGRepresentation(venueImage), nil);
    }

    ABMultiValueAddValueAndLabel(multiAddress, (__bridge CFDictionaryRef) addressDictionary, kABWorkLabel, NULL);
    ABRecordSetValue(person, kABPersonAddressProperty, multiAddress, NULL);
    CFRelease(multiAddress);

    CFErrorRef error = NULL;
    ABAddressBookAddRecord(addressBook, person, &error);
    ABAddressBookSave(addressBook, &error);

    CFRelease(person);
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
        NBLog(@"Error serializing to JSON data: %@", error.localizedDescription);
        
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
        NBLog(@"Error serializing from JSON data: %@", error.localizedDescription);
        
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
        NBLog(@"Error serializing from JSON data: %@", error.localizedDescription);

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
    NSDictionary* userInfo = @{NSLocalizedDescriptionKey : description};
    NSError*      error    = [[NSError alloc] initWithDomain:[Settings sharedSettings].errorDomain
                                                        code:code
                                                    userInfo:userInfo];

    return error;
}


+ (BOOL)deviceHasReceiver
{
    return [[UIDevice currentDevice].model isEqualToString:@"iPhone"];
}


// Idea:      https://github.com/erichoracek/UIDevice-Hardware/blob/master/UIDevice-Hardware.m
// iPhone:    http://theiphonewiki.com/wiki/IPhone
// iPad:      http://theiphonewiki.com/wiki/IPad
// iPad Mini: http://theiphonewiki.com/wiki/IPad_mini
// iPod:      http://theiphonewiki.com/wiki/IPod
// Apple TV:  https://www.theiphonewiki.com/wiki/Apple_TV
//
+ (NSString*)deviceModel
{
    static dispatch_once_t onceToken;
    static NSDictionary*   table;
    
    dispatch_once(&onceToken, ^
    {
        table =
        @{
            @"iPhone1,1"  : @"iPhone 1G",
            @"iPhone1,2"  : @"iPhone 3G",
            @"iPhone2,1"  : @"iPhone 3GS",
            @"iPhone3,1"  : @"iPhone 4 (GSM)",
            @"iPhone3,2"  : @"iPhone 4 (GSM Rev A)",
            @"iPhone3,3"  : @"iPhone 4 (CDMA)",
            @"iPhone4,1"  : @"iPhone 4S",
            @"iPhone5,1"  : @"iPhone 5 (GSM)",
            @"iPhone5,2"  : @"iPhone 5 (Global)",
            @"iPhone5,3"  : @"iPhone 5c (GSM)",
            @"iPhone5,4"  : @"iPhone 5c (Global)",
            @"iPhone6,1"  : @"iPhone 5s (GSM)",
            @"iPhone6,2"  : @"iPhone 5s (Global)",
            @"iPhone7,1"  : @"iPhone 6 Plus",
            @"iPhone7,2"  : @"iPhone 6",
            @"iPhone8,1"  : @"iPhone 6s",
            @"iPhone8,2"  : @"iPhone 6s Plus",

            @"iPad1,1"    : @"iPad 1G",
            @"iPad2,1"    : @"iPad 2 (Wi-Fi)",
            @"iPad2,2"    : @"iPad 2 (GSM)",
            @"iPad2,3"    : @"iPad 2 (CDMA)",
            @"iPad2,4"    : @"iPad 2 (Rev A)",
            @"iPad3,1"    : @"iPad 3 (Wi-Fi)",
            @"iPad3,2"    : @"iPad 3 (GSM)",
            @"iPad3,3"    : @"iPad 3 (Global)",
            @"iPad3,4"    : @"iPad 4 (Wi-Fi)",
            @"iPad3,5"    : @"iPad 4 (GSM)",
            @"iPad3,6"    : @"iPad 4 (Global)",

            @"iPad4,1"    : @"iPad Air (Wi-Fi)",
            @"iPad4,2"    : @"iPad Air (Cellular)",
            @"iPad5,3"    : @"iPad Air 2 (Wi-Fi)",
            @"iPad5,4"    : @"iPad Air 2 (Cellular)",

            @"iPad2,5"    : @"iPad mini 1G (Wi-Fi)",
            @"iPad2,6"    : @"iPad mini 1G (GSM)",
            @"iPad2,7"    : @"iPad mini 1G (Global)",
            @"iPad4,4"    : @"iPad mini 2G (Wi-Fi)",
            @"iPad4,5"    : @"iPad mini 2G (Cellular)",
            @"iPad4,6"    : @"iPad mini 2G (Cellular)", // TD-LTE model see https://support.apple.com/en-us/HT201471#iPad-mini2
            @"iPad4,7"    : @"iPad mini 3G (Wi-Fi)",
            @"iPad4,8"    : @"iPad mini 3G (Cellular)",
            @"iPad4,9"    : @"iPad mini 3G (Cellular)",

            @"iPod1,1"    : @"iPod touch 1G",
            @"iPod2,1"    : @"iPod touch 2G",
            @"iPod3,1"    : @"iPod touch 3G",
            @"iPod4,1"    : @"iPod touch 4G",
            @"iPod5,1"    : @"iPod touch 5G",
            @"iPod7,1"    : @"iPod touch 6G",           // as 6,1 was never released 7,1 is actually 6th generation

            @"AppleTV1,1" : @"Apple TV 1G",
            @"AppleTV2,1" : @"Apple TV 2G",
            @"AppleTV3,1" : @"Apple TV 3G",
            @"AppleTV3,2" : @"Apple TV 3G",             // small, incremental update over 3,1
            @"AppleTV5,3" : @"Apple TV 4G",             // as 4,1 was never released, 5,1 is actually 4th generation
        };
    });

    struct    utsname systemInfo;
    uname(&systemInfo);
    NSString* machine = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSString* model   = table[machine];
    
    if (model == nil && ([machine hasSuffix:@"86"] || [machine isEqual:@"x86_64"]))
    {
        model = ([[UIScreen mainScreen] bounds].size.width < 768.0) ? @"iPhone Simulator" : @"iPad Simulator";
    }
    
    if (model == nil)
    {
        model = machine;
    }

    return model;
}

 
+ (NSString*)deviceOs
{
    NSOperatingSystemVersion osVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    
    return [NSString stringWithFormat:@"%d.%d.%d", (int)osVersion.majorVersion, (int)osVersion.minorVersion, (int)osVersion.patchVersion];
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
                                                    [NSBundle mainBundle], @"Notifications Disabled",
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
    else if ([AppDelegate appDelegate].deviceToken.length == 0)
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
                                                        @"Select the home country, or enter an international number.",
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
                CountriesViewController* countriesViewController;
                UINavigationController*  modalViewController;
                NSString*                homeCountry = [Settings sharedSettings].homeCountry;

                countriesViewController = [[CountriesViewController alloc] initWithIsoCountryCode:homeCountry
                                                                                            title:[Strings homeCountryString]
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


// This will redirect NBLog() output to a log file.  Switch on 'Application supports iTunes file sharing'
// in the app's .plist file to allow accessing the logs from iTunes.  Don't forget to set this .plist
// parameter to NO before distributing the app (unless it's on intentionally)!
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
+ (unsigned long)nthBitSet:(NSUInteger)n inValue:(unsigned long)value
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


+ (unsigned)bitIndexOfMask:(unsigned long)mask
{
    unsigned index = 0;
    
    if (mask == 0)
    {
        NBLog(@"Trying to get bit-index of mask 0.");
    }
    else
    {
        while ((mask & 1) == 0)
        {
            mask >>= 1;
            index++;
        }
    }
    
    return index;
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


+ (void)getCostForCallbackE164:(NSString*)callbackE164
                  callthruE164:(NSString*)callthruE164
                    completion:(void (^)(NSString* costString))completion
{
    __block float totalCost = 0.0f;

    [[WebClient sharedClient] retrieveCallRateForE164:callbackE164
                                                reply:^(NSError *error, float ratePerMinute)
    {
        if (error == nil)
        {
            totalCost = ratePerMinute;

            [[WebClient sharedClient] retrieveCallRateForE164:callthruE164
                                                         reply:^(NSError *error, float ratePerMinute)
            {
                if (error == nil)
                {
                    totalCost += ratePerMinute;
                    completion([[PurchaseManager sharedManager] localizedFormattedPrice2ExtraDigits:totalCost]);
                }
                else
                {
                    completion(nil);
                }
            }];
        }
        else
        {
            completion(nil);
        }
    }];
}


+ (void)aksForCallbackPhoneNumber:(PhoneNumber*)phoneNumber
                       completion:(void (^)(BOOL cancelled, PhoneNumber* phoneNumber))completion
{
    __block BlockAlertView* alert;
    NSString*               title;
    NSString*               message;

    title   = NSLocalizedStringWithDefaultValue(@"Credit EnterNumberTitle", nil, [NSBundle mainBundle],
                                                @"Enter Callback Number",
                                                @"Title asking user to enter their phone number.\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyCancelMessage", nil, [NSBundle mainBundle],
                                                @"To show correct rates, enter a number you'd be called "
                                                @"back on.\n\n"
                                                @"(This popup won't show up when you're a user, and the Callback Number "
                                                @"on Settings is selected.)",
                                                @"Message explaining about the phone number they need to enter.\n"
                                                @"[iOS alert message size]");
    alert   = [BlockAlertView showPhoneNumberAlertViewWithTitle:title
                                                        message:message
                                                    phoneNumber:phoneNumber
                                                     completion:^(BOOL cancelled, PhoneNumber* phoneNumber)
    {
        if (cancelled == NO)
        {
            if (phoneNumber.isValid)
            {
                completion(cancelled, phoneNumber);
            }
            else
            {
                NSString* title;
                NSString* message;

                title   = NSLocalizedStringWithDefaultValue(@"Credit VerifyInvalidTitle", nil,
                                                            [NSBundle mainBundle], @"Invalid Number",
                                                            @"Phone number is not correct.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Credit VerifyInvalidMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"The number you entered seems invalid.\n\nPlease correct, "
                                                            @"enter an international number (starting with '+'), "
                                                            @"or check/choose the Home Country on the Settings tab.",
                                                            @"Alert message that entered phone number is invalid.\n"
                                                            @"[iOS alert message size]");
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:nil
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:nil];

                completion(NO, phoneNumber);
            }
        }
        else
        {
            completion(NO, phoneNumber);
        }
    }
                                              cancelButtonTitle:[Strings cancelString]
                                              otherButtonTitles:[Strings okString], nil];
}


+ (NSString*)callingCodeForCountry:(NSString*)isoCountryCode
{
    static NSDictionary*   callingCodes;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
    {
        NSData* data = [Common dataForResource:@"CountryCallingCodes" ofType:@"json"];
        callingCodes = [Common objectWithJsonData:data];
    });
                  
    return callingCodes[isoCountryCode];
}

@end
