//
//  HelpsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import "HelpsViewController.h"
#import "HtmlViewController.h"
#import "Common.h"
#import "CallManager.h"
#import "Settings.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "Skinning.h"
#import "GetStartedViewController.h"


typedef NS_ENUM(NSUInteger, TableSections)
{
    TableSectionContactUs = 1UL << 0,
    TableSectionTexts     = 1UL << 1,
    TableSectionIntro     = 1UL << 2,
} ;

typedef NS_ENUM(NSUInteger, TableRowsContactUs)
{
    TableRowsContactUsEmail    = 1UL << 0,
    TableRowsContactUsAppStore = 1UL << 1,
    TableRowsContactUsCall     = 1UL << 2,  // Not used at the moment.
};


@interface HelpsViewController ()
{
    NSArray*           helpsArray;
    TableSections      sections;
    TableRowsContactUs rowsContactUs;
}

@end


@implementation HelpsViewController

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"Helps ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Help",
                                                       @"Title of app screen with list of help items\n"
                                                       @"[1 line larger font].");
        // The tabBarItem image must be set in my own NavigationController.

        NSData* data   = [Common dataForResource:@"Helps" ofType:@"json"];
        helpsArray     = [Common objectWithJsonData:data];
        NSString* json = [[Common jsonStringWithObject:helpsArray] stringByReplacingOccurrencesOfString:@"<display-name>"
                                                                                             withString:[Settings sharedSettings].appDisplayName];
        helpsArray = [Common objectWithJsonString:json];

        sections      |= TableSectionContactUs;
        sections      |= TableSectionTexts;

        rowsContactUs |= TableRowsContactUsEmail;
        rowsContactUs |= TableRowsContactUsAppStore;

        [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
        {
            if ([Settings sharedSettings].haveAccount != !!(sections & TableSectionIntro))
            {
                if ([Settings sharedSettings].haveAccount)
                {
                    sections |=  TableSectionIntro;
                }
                else
                {
                    sections &= ~TableSectionIntro;
                }

                [self.tableView reloadData];
            }
        }];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    BOOL pushed = [self isMovingToParentViewController];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:!pushed];
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionContactUs: numberOfRows = [Common bitsSetCount:rowsContactUs]; break;
        case TableSectionTexts:     numberOfRows = helpsArray.count;                    break;
        case TableSectionIntro:     numberOfRows = 1;                                   break;
    }
    
    return numberOfRows;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionContactUs:
        {
            title = NSLocalizedStringWithDefaultValue(@"Helps:ContactUs SectionHeader", nil, [NSBundle mainBundle],
                                                      @"Contact Us",
                                                      @"Ways to contact us.");
            break;
        }
        case TableSectionTexts:
        {
            title = NSLocalizedStringWithDefaultValue(@"Helps:Texts SectionHeader", nil, [NSBundle mainBundle],
                                                      @"Texts",
                                                      @"Written help.");
            break;
        }
        case TableSectionIntro:
        {
            title = NSLocalizedStringWithDefaultValue(@"Helps:Intro SectionHeader", nil, [NSBundle mainBundle],
                                                      @"Intro",
                                                      @"Introduction images + text.");
            break;
        }
    }
    
    return title;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    NSString*        text;

    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionContactUs:
        {
            switch ([Common nthBitSet:indexPath.row inValue:rowsContactUs])
            {
                case TableRowsContactUsEmail:
                {
                    text = NSLocalizedStringWithDefaultValue(@"Helps EmailContactUsText", nil, [NSBundle mainBundle],
                                                             @"Send Email",
                                                             @"....\n"
                                                             @"[1 line larger font].");
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.textLabel.textColor = [Skinning tintColor];
                    break;
                }
                case TableRowsContactUsAppStore:
                {
                    text = NSLocalizedStringWithDefaultValue(@"Helps RateTheAppText", nil, [NSBundle mainBundle],
                                                             @"Write an App Store Review...",
                                                             @"....\n"
                                                             @"[1 line larger font].");
                    cell.accessoryType  = UITableViewCellAccessoryNone;
                    cell.textLabel.textColor = [Skinning tintColor];
                    break;
                }
                case TableRowsContactUsCall:
                {
                    text = NSLocalizedStringWithDefaultValue(@"Helps CallContactUsText", nil, [NSBundle mainBundle],
                                                             @"Make Mobile Call",
                                                             @"....\n"
                                                             @"[1 line larger font].");
                    cell.accessoryType  = UITableViewCellAccessoryNone;
                    cell.textLabel.textColor = [Skinning tintColor];
                    break;
                }
            }

            cell.textLabel.text = text;
            break;
        }
        case TableSectionTexts:
        {
            cell.textLabel.text = [helpsArray[indexPath.row] allKeys][0];
            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case TableSectionIntro:
        {
            cell.textLabel.text  =NSLocalizedStringWithDefaultValue(@"Helps IntroText", nil, [NSBundle mainBundle],
                                                                    @"Slideshow",
                                                                    @"...\n"
                                                                    @"[1 line larger font].");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
    }

    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    HtmlViewController*  htmlViewController;
    __block PhoneNumber* phoneNumber;
    NSString*            title;
    NSString*            message;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionContactUs:
        {
            switch ([Common nthBitSet:indexPath.row inValue:rowsContactUs])
            {
                case TableRowsContactUsEmail:
                {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];

                    [Common sendEmailTo:[Settings sharedSettings].companyEmail
                                subject:[Settings sharedSettings].callbackE164
                                   body:nil
                             completion:nil];
                    break;
                }
                case TableRowsContactUsAppStore:
                {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];

                    [Common openAppStoreReviewPage];
                    break;
                }
                case TableRowsContactUsCall:
                {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];

                    title   = NSLocalizedStringWithDefaultValue(@"Helps MobileCallText", nil, [NSBundle mainBundle],
                                                                @"Make Mobile Call",
                                                                @"...\n"
                                                                @"[1 line larger font].");
                    message = NSLocalizedStringWithDefaultValue(@"Helps TestCallText", nil, [NSBundle mainBundle],
                                                                @"You're about to call us on our United Kingdom number "
                                                                @"using iOS' mobile Phone app.\n\n"
                                                                @"Normal (international) call charges, of your mobile "
                                                                @"operator, apply.",
                                                                @"...\n"
                                                                @"[1 line larger font].");
                    [BlockAlertView showAlertViewWithTitle:title
                                                   message:message
                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                    {
                        if (buttonIndex == 1)
                        {
                            phoneNumber = [[PhoneNumber alloc] initWithNumber:[Settings sharedSettings].companyPhone];
                            [[CallManager sharedManager] callMobilePhoneNumber:phoneNumber];
                        }
                    }
                                         cancelButtonTitle:[Strings cancelString]
                                         otherButtonTitles:[Strings callString], nil];
                    break;
                }
            }
            
            break;
        }
        case TableSectionTexts:
        {
            htmlViewController = [[HtmlViewController alloc] initWithDictionary:helpsArray[indexPath.row] modal:NO];
            [self.navigationController pushViewController:htmlViewController animated:YES];
            break;
        }
        case TableSectionIntro:
        {
            GetStartedViewController* viewController = [[GetStartedViewController alloc] initShowAsIntro:YES];
            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
    }
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 45;
}

@end
