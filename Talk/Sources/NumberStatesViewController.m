//
//  NumberStatesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberStatesViewController.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "NumberAreasViewController.h"
#import "Common.h"


@interface NumberStatesViewController ()
{
    NSString*       isoCountryCode;
    NumberTypeMask  numberTypeMask; // Not used in this class, just being passed on.
    AddressTypeMask addressTypeMask;// Not used in this class, just being passed on.
}

@property (nonatomic, assign) BOOL isFilteringEnabled;

@end


@implementation NumberStatesViewController

- (instancetype)initWithIsoCountryCode:(NSString*)theIsoCountryCode
                        numberTypeMask:(NumberTypeMask)theNumberTypeMask
                       addressTypeMask:(AddressTypeMask)theAddressTypeMask
                    isFilteringEnabled:(BOOL)isFilteringEnabled
{
    if (self = [super init])
    {
        isoCountryCode          = theIsoCountryCode;
        numberTypeMask          = theNumberTypeMask;
        addressTypeMask         = theAddressTypeMask;
        self.isFilteringEnabled = isFilteringEnabled;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberStates:Done ScreenTitle", nil,
                                                                  [NSBundle mainBundle], @"States",
                                                                  @"Title of app screen with list of states.\n"
                                                                  @"[1 line larger font].");

    UIBarButtonItem* cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    self.isLoading = YES;
    [[WebClient sharedClient] retrieveNumberStatesForIsoCountryCode:isoCountryCode
                                                              reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            self.objectsArray = content;
            [self createIndexOfWidth:1];

            self.isLoading = NO;    // Placed here, after processing results, to let reload of search results work.
        }
        else if (error.code == WebStatusFailServiceUnavailable)
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"NumberStates UnavailableAlertTitle", nil,
                                                        [NSBundle mainBundle], @"Service Unavailable",
                                                        @"Alert title telling that loading states over internet failed.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"NumberStates UnavailableAlertMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"The service for buying numbers is temporarily offline."
                                                        @"\n\nPlease try again later.",
                                                        @"Alert message telling that loading states over internet failed.\n"
                                                        @"[iOS alert message size]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[Strings cancelString]
                                 otherButtonTitles:nil];
        }
        else
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"NumberStates LoadFailAlertTitle", nil,
                                                        [NSBundle mainBundle], @"Loading Failed",
                                                        @"Alert title telling that loading states over internet failed.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"NumberStates LoadFailAlertMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Loading the list of states failed: %@\n\nPlease try again later.",
                                                        @"Alert message telling that loading states over internet failed.\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, error.localizedDescription];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[Strings cancelString]
                                 otherButtonTitles:nil];
        }
    }];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[WebClient sharedClient] cancelAllRetrieveNumberStatesForIsoCountryCode:isoCountryCode];
}


#pragma mark - Base Class Override

- (NSString*)nameForObject:(id)object
{
    NSMutableDictionary* state = object;

    return state[@"stateName"];
}


#pragma mark - Helper Methods

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table View Delegates

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary* state = [self objectOnTableView:tableView atIndexPath:indexPath];

    if ([state[@"areaCount"] intValue] == 0)
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"NumberStates UnavailableTitle", nil,
                                                    [NSBundle mainBundle], @"Not Available",
                                                    @".\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberStates UnavailableMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"There are no geographic numbers available in this state.\n\n"
                                                    @"This may change in the future.",
                                                    @"....\n"
                                                    @"[iOS alert message size!]");
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
         {
             [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
         }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];

        return;
    }

    NumberAreasViewController* viewController;
    viewController = [[NumberAreasViewController alloc] initWithIsoCountryCode:isoCountryCode
                                                                         state:state
                                                                numberTypeMask:numberTypeMask
                                                               addressTypeMask:addressTypeMask
                                                            isFilteringEnabled:self.isFilteringEnabled];
    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        name  = [self nameOnTableView:tableView atIndexPath:indexPath];
    NSDictionary*    state = [self objectOnTableView:tableView atIndexPath:indexPath];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    cell.imageView.image      = [UIImage imageNamed:isoCountryCode];
    cell.detailTextLabel.text = [@"+" stringByAppendingString:[Common callingCodeForCountry:isoCountryCode]];
    if ([state[@"areaCount"] intValue] > 0)
    {
        cell.textLabel.text = name;
    }
    else
    {
        cell.textLabel.attributedText = [Common strikethroughAttributedString:name];
    }

    return cell;
}

@end
