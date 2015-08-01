//
//  NumberStatesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberStatesViewController.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "NumberAreasViewController.h"


@interface NumberStatesViewController ()
{
    NSString*      isoCountryCode;
    NumberTypeMask numberTypeMask;          // Not used in this class, just being passed on.
}

@end


@implementation NumberStatesViewController

- (instancetype)initWithIsoCountryCode:(NSString*)theIsoCountryCode
                        numberTypeMask:(NumberTypeMask)theNumberTypeMask
{
    if (self = [super init])
    {
        isoCountryCode = theIsoCountryCode;
        numberTypeMask = theNumberTypeMask;
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
            self.isLoading = NO;
            
            self.objectsArray = content;
            [self createIndexOfWidth:1];
        }
        else if (error.code == WebClientStatusFailServiceUnavailable)
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

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.searchDisplayController setActive:NO animated:YES];

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
    NSString*     name = [self nameOnTable:tableView atIndexPath:indexPath];
    NSDictionary* state;

    // Look up state.
    for (state in self.objectsArray)
    {
        if ([state[@"stateName"] isEqualToString:name])
        {
            break;
        }
    }

    NumberAreasViewController* viewController;
    viewController = [[NumberAreasViewController alloc] initWithIsoCountryCode:isoCountryCode
                                                                         state:state
                                                                numberTypeMask:numberTypeMask];
    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        name = [self nameOnTable:tableView atIndexPath:indexPath];
    NSDictionary*    state;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    // Look up country.
    for (state in self.objectsArray)
    {
        if ([state[@"stateName"] isEqualToString:name])
        {
            break;
        }
    }

    cell.imageView.image = [UIImage imageNamed:isoCountryCode];
    cell.textLabel.text  = name;
    cell.accessoryType   = UITableViewCellAccessoryNone;

    return cell;
}

@end
