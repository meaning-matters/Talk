//
//  HelpsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "HelpsViewController.h"
#import "HelpViewController.h"
#import "Common.h"
#import "CallManager.h"
#import "Settings.h"
#import "ContactUsViewController.h"
#import "BlockAlertView.h"
#import "Strings.h"


typedef enum
{
    TableSectionTexts     = 1UL << 0,
    TableSectionContactUs = 1UL << 1,
    TableSectionTestCall  = 1UL << 2,
} TableSections;


@interface HelpsViewController ()
{
    NSArray*      helpsArray;
    TableSections sections;
}

@end


@implementation HelpsViewController

- (instancetype)init
{
    if (self = [super initWithNibName:@"HelpsView" bundle:nil])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"Helps ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Help",
                                                       @"Title of app screen with list of help items\n"
                                                       @"[1 line larger font].");
        self.tabBarItem.image = [UIImage imageNamed:@"HelpsTab.png"];

        NSData* data = [Common dataForResource:@"Helps" ofType:@"json"];
        helpsArray   = [Common objectWithJsonData:data];

        sections |= TableSectionTexts;
        sections |= TableSectionContactUs;
        sections |= TableSectionTestCall;
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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionTexts:
            numberOfRows = helpsArray.count;
            break;

        case TableSectionContactUs:
            numberOfRows = 3;
            break;

        case TableSectionTestCall:
            numberOfRows = 1;
            break;
    }
    
    return numberOfRows;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionTexts:
            title = NSLocalizedStringWithDefaultValue(@"Helps:Texts SectionHeader", nil, [NSBundle mainBundle],
                                                      @"Help Texts",
                                                      @"Written help.");
            break;

        case TableSectionContactUs:
            title = NSLocalizedStringWithDefaultValue(@"Helps:ContactUs SectionHeader", nil, [NSBundle mainBundle],
                                                      @"Contact Us",
                                                      @"Ways to contact us.");
            break;

        case TableSectionTestCall:
            title = NSLocalizedStringWithDefaultValue(@"Helps:TestCall SectionHeader", nil, [NSBundle mainBundle],
                                                      @"Test",
                                                      @"Ways to test the app.");
            break;
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

    switch (indexPath.section)
    {
        case TableSectionTexts:
            cell.textLabel.text = [helpsArray[indexPath.row] allKeys][0];
            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            break;

        case TableSectionContactUs:
            switch (indexPath.row)
            {
                case 0:
                    text = NSLocalizedStringWithDefaultValue(@"Helps MessageContactUsText", nil, [NSBundle mainBundle],
                                                             @"Send Direct Message",
                                                             @"....\n"
                                                             @"[1 line larger font].");
                    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
                    break;

                case 1:
                    text = NSLocalizedStringWithDefaultValue(@"Helps EmailContactUsText", nil, [NSBundle mainBundle],
                                                             @"Send Email",
                                                             @"....\n"
                                                             @"[1 line larger font].");
                    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
                    break;

                case 2:
                    text = NSLocalizedStringWithDefaultValue(@"Helps CallContactUsText", nil, [NSBundle mainBundle],
                                                             @"Make Mobile Call...",
                                                             @"....\n"
                                                             @"[1 line larger font].");
                    cell.accessoryType  = UITableViewCellAccessoryNone;
                    break;
            }

            cell.textLabel.text = text;
            break;

        case TableSectionTestCall:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Helps TestCallText", nil, [NSBundle mainBundle],
                                                                    @"Make Test Call",
                                                                    @"...\n"
                                                                    @"[1 line larger font].");
            cell.accessoryType  = UITableViewCellAccessoryNone;
            break;
    }

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    HelpViewController*  helpViewController;
    __block PhoneNumber* phoneNumber;
    NSString*            title;
    NSString*            message;

    switch (indexPath.section)
    {
        case TableSectionTexts:
            helpViewController = [[HelpViewController alloc] initWithDictionary:helpsArray[indexPath.row]];
            [self.navigationController pushViewController:helpViewController animated:YES];
            break;

        case TableSectionContactUs:
            switch (indexPath.row)
            {
                case 0:
                    // Open HockeyApp's message screen
                    break;

                case 1:
                    // Open email screen
                    break;

                case 2:
                    title   = NSLocalizedStringWithDefaultValue(@"Helps TestCallText", nil, [NSBundle mainBundle],
                                                                @"Make Test Call",
                                                                @"...\n"
                                                                @"[1 line larger font].");
                    message = NSLocalizedStringWithDefaultValue(@"Helps TestCallText", nil, [NSBundle mainBundle],
                                                                @"You're about to call our United Kingdom number "
                                                                @"using iOS' mobile Phone app.  Normal mobile call "
                                                                @"charges, of your operator, apply.",
                                                                @"...\n"
                                                                @"[1 line larger font].");
                    [BlockAlertView showAlertViewWithTitle:title
                                                   message:message
                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                    {
                        if (buttonIndex == 1)
                        {
                            phoneNumber = [[PhoneNumber alloc] initWithNumber:[Settings sharedSettings].supportNumber];
                            [[CallManager sharedManager] callMobilePhoneNumber:phoneNumber];
                        }
                    }
                                         cancelButtonTitle:[Strings cancelString]
                                         otherButtonTitles:[Strings callString], nil];
                    break;
            }
            break;

        case TableSectionTestCall:
            phoneNumber = [[PhoneNumber alloc] initWithNumber:[Settings sharedSettings].testNumber];
            [[CallManager sharedManager] callPhoneNumber:phoneNumber fromIdentity:[Settings sharedSettings].verifiedE164];
            break;
    }
}

@end
