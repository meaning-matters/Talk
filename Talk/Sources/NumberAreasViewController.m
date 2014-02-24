//
//  NumberAreasViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 09/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberAreasViewController.h"
#import "NumberType.h"
#import "WebClient.h"
#import "CountryNames.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "Common.h"
#import "NumberAreaViewController.h"
#import "NumberAreasCell.h"
#import "Settings.h"


@interface NumberAreasViewController ()
{
    NSString*      isoCountryCode;
    NSDictionary*  state;
    NumberTypeMask numberTypeMask;
}

@end


@implementation NumberAreasViewController

- (instancetype)initWithIsoCountryCode:(NSString*)theIsoCountryCode
                                 state:(NSDictionary*)theState
                        numberTypeMask:(NumberTypeMask)theNumberTypeMask
{
    if (self = [super init])
    {
        isoCountryCode = theIsoCountryCode;
        state          = theState;      // Is nil for country without states.
        numberTypeMask = theNumberTypeMask;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = [Strings loadingString];

    [self.tableView registerNib:[UINib nibWithNibName:@"NumberAreasCell" bundle:nil]
         forCellReuseIdentifier:@"NumberAreasCell"];

    UIBarButtonItem* cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    if (state != nil)
    {
        [[WebClient sharedClient] retrieveNumberAreasForIsoCountryCode:isoCountryCode
                                                             stateCode:state[@"stateCode"]
                                                        numberTypeMask:numberTypeMask
                                                          currencyCode:[Settings sharedSettings].currencyCode
                                                                 reply:^(NSError* error, id content)
        {
            if (error == nil)
            {
                [self processContent:content];
            }
            else
            {
                [self handleError:error];
            }
        }];
    }
    else
    {
        [[WebClient sharedClient] retrieveNumberAreasForIsoCountryCode:isoCountryCode
                                                        numberTypeMask:numberTypeMask
                                                          currencyCode:[Settings sharedSettings].currencyCode
                                                                 reply:^(NSError* error, id content)
        {
            if (error == nil)
            {
                [self processContent:content];
            }
            else
            {
                [self handleError:error];
            }
        }];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (state != nil)
    {
        [[WebClient sharedClient] cancelAllRetrieveNumberAreasForIsoCountryCode:isoCountryCode
                                                                      stateCode:state[@"stateCode"]];
    }
    else
    {
        [[WebClient sharedClient] cancelAllRetrieveNumberAreasForIsoCountryCode:isoCountryCode];
    }
}


#pragma mark - Helper Methods

- (void)processContent:(id)content
{
    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberAreas:Done ScreenTitle", nil,
                                                                  [NSBundle mainBundle], @"Areas",
                                                                  @"Title of app screen with list of areas.\n"
                                                                  @"[1 line larger font].");

    if ([(NSArray*)content count] > 0)
    {
        NSMutableArray* areasArray = [NSMutableArray array];

        for (NSDictionary* area in content)
        {
            NSMutableDictionary* mutableArea = [NSMutableDictionary dictionaryWithDictionary:area];

            if ([mutableArea objectForKey:@"areaName"] != [NSNull null])
            {
                if ([[mutableArea objectForKey:@"areaName"] caseInsensitiveCompare:@"All cities"] == NSOrderedSame)
                {
                    // Handle special case seen with Denmark: One area for all cities.  We only localize at the moment.
                    mutableArea[@"areaName"] = NSLocalizedStringWithDefaultValue(@"NumberAreas:Table AllC", nil,
                                                                                 [NSBundle mainBundle], @"All cities",
                                                                                 @"Indicates that something applies to all "
                                                                                 @"cities of a country.\n"
                                                                                 @"[1 line larger font].");
                }
                else
                {
                    mutableArea[@"areaName"] = [Common capitalizedString:mutableArea[@"areaName"]];
                }
            }
            else if ([[mutableArea objectForKey:@"areaCode"] isEqualToString:@"0"] == NO)
            {
                // To support non-geographic numbers with little code change.
                mutableArea[@"areaName"] = mutableArea[@"areaCode"];
            }
            else
            {
                // Both areaName, areaCode and city are null.
                mutableArea[@"areaName"] = NSLocalizedStringWithDefaultValue(@"NumberAreas:Table NoAreaCode", nil,
                                                                             [NSBundle mainBundle], @"Unknown area code",
                                                                             @"Explains that area code is not available.\n"
                                                                             @"[1 line larger font].");
                mutableArea[@"areaCode"] = @"";
            }

            [areasArray addObject:mutableArea];
        }

        self.objectsArray = areasArray;
        [self createIndex];
    }
    else
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"NumberAreas NoNumbersAlertTitle", nil,
                                                    [NSBundle mainBundle], @"Numbers Unavailable",
                                                    @"Alert title telling that phone numbers are not available.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberAreas NoNumbersAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"These numbers are not available for purchase at the moment."
                                                    @"\n\nPlease try again later.",
                                                    @"Alert message telling that phone numbers are not available.\n"
                                                    @"[iOS alert message size!]");
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
}


- (void)handleError:(NSError*)error
{
    if (error.code == WebClientStatusFailServiceUnavailable)
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"NumberAreas UnavailableAlertTitle", nil,
                                                    [NSBundle mainBundle], @"Service Unavailable",
                                                    @"Alert title telling that loading areas over internet failed.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberAreas UnavailableAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"The service for buying numbers is temporarily offline."
                                                    @"\n\nPlease try again later.",
                                                    @"Alert message telling that loading areas over internet failed.\n"
                                                    @"[iOS alert message size!]");
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

        title   = NSLocalizedStringWithDefaultValue(@"NumberAreas LoadFailAlertTitle", nil,
                                                    [NSBundle mainBundle], @"Loading Failed",
                                                    @"Alert title telling that loading countries over internet failed.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberAreas LoadFailAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"Loading the list of areas failed: %@\n\nPlease try again later.",
                                                    @"Alert message telling that loading areas over internet failed.\n"
                                                    @"[iOS alert message size!]");
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
}


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Base Class Override

- (NSString*)nameForObject:(id)object
{
    NSDictionary* area = object;

    return area[@"areaName"];
}


#pragma mark - Table View Delegates

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString*     name = [self nameOnTable:tableView atIndexPath:indexPath];
    NSDictionary* area;

    // Look up area.
    for (area in self.objectsArray)
    {
        if ([area[@"areaName"] isEqualToString:name])
        {
            break;
        }
    }

    NumberAreaViewController*   viewController;
    viewController = [[NumberAreaViewController alloc] initWithIsoCountryCode:isoCountryCode
                                                                        state:state
                                                                         area:area
                                                               numberTypeMask:numberTypeMask];
    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberAreasCell* cell;
    NSString*        name = [self nameOnTable:tableView atIndexPath:indexPath];
    NSDictionary*    area;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumberAreasCell"];
    if (cell == nil)
    {
        cell = [[NumberAreasCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NumberAreasCell"];
    }

    // Look up area.
    for (area in self.objectsArray)
    {
        if ([area[@"areaName"] isEqualToString:name])
        {
            break;
        }
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([area[@"areaCode"] length] > 0)
    {
        if ([area[@"areaCode"] isEqualToString:name] == NO)
        {
            cell.areaCode.text = area[@"areaCode"];
            cell.areaName.text = name;
        }
        else
        {
            cell.areaCode.text = area[@"areaCode"];
            cell.areaName.text = [NumberType localizedStringForNumberType:numberTypeMask];
        }
    }
    else
    {
        cell.areaCode.text = @"---";
        cell.areaName.text = name;
    }

    return cell;
}

@end
