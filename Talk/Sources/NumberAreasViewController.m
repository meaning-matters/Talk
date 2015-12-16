//
//  NumberAreasViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 09/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//
//  Here are the different Voxbone reply formats we need to deal with:
//      GEOGRAPHIC:
//          Brazil (normal)
//          areaCode = 81
//          areaId   = 23325
//          areaName = "ABREU E LIMA"
//          city     = "ABREU E LIMA"
//
//          Denmark (exception)
//          areaCode = 89
//          areaId   = 20503
//          areaName = "ALL CITIES"
//          city     = "ALL CITIES"
//
//      NATIONAL:
//          Belgium (normal)
//          areaCode = 78;
//          areaId   = 8368;
//          areaName = "<null>"
//          city     = "<null>"
//
//          Bahrain (exception)
//          areaCode = ""
//          areaId   = 7362
//          areaName = "<null>"
//          city     = "<null>"
//
//      TOLL_FREE:
//          Argentina (normal)
//          areaCode = 822
//          areaId   = 6424
//          areaName = "<null>"
//          city     = "<null>"
//
//      MOBILE:
//          Belgium (normal)
//          areaCode = 466
//          areaId   = 20560
//          areaName = "<null>"
//          city     = "<null>"
//
//      SHARED_COST:
//          Australia (normal)
//          areaCode = 1300
//          areaId   = 9486
//          areaName = "<null>"
//          city     = "<null>"
//
//      SPECIAL:
//          China (normal)
//          areaCode = 10
//          areaId   = 23067
//          areaName = BEIJING
//          city     = BEIJING
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

typedef NS_ENUM(NSUInteger, AreaFormat)
{
    AreaFormatGeographic,
    AreaFormatGeographicException,
    AreaFormatNational,
    AreaFormatNationalException,
    AreaFormatTollFree,
    AreaFormatMobile,
    AreaFormatSharedCost,
    AreaFormatSpecial,
    AreaFormatInternational,
};


@interface NumberAreasViewController ()
{
    NSString*      isoCountryCode;
    NSDictionary*  state;
    NumberTypeMask numberTypeMask;
    AreaFormat     areaFormat;
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

    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberAreas:Done ScreenTitle", nil,
                                                                  [NSBundle mainBundle], @"Areas",
                                                                  @"Title of app screen with list of areas.\n"
                                                                  @"[1 line larger font].");

    [self.tableView registerNib:[UINib nibWithNibName:@"NumberAreasCell" bundle:nil]
         forCellReuseIdentifier:@"NumberAreasCell"];

    UIBarButtonItem* cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    if (state != nil)
    {
        self.isLoading = YES;
        [[WebClient sharedClient] retrieveNumberAreasForIsoCountryCode:isoCountryCode
                                                             stateCode:state[@"stateCode"]
                                                        numberTypeMask:numberTypeMask
                                                          currencyCode:[Settings sharedSettings].storeCurrencyCode
                                                                 reply:^(NSError* error, id content)
        {
            if (error == nil)
            {
                [self processContent:content];

                self.isLoading = NO;    // Placed here, after processing results, to let reload of search results work.
            }
            else
            {
                [self handleError:error];
            }
        }];
    }
    else
    {
        self.isLoading = YES;
        [[WebClient sharedClient] retrieveNumberAreasForIsoCountryCode:isoCountryCode
                                                        numberTypeMask:numberTypeMask
                                                          currencyCode:[Settings sharedSettings].storeCurrencyCode
                                                                 reply:^(NSError* error, id content)
        {
            if (error == nil)
            {
                [self processContent:content];

                self.isLoading = NO;    // Placed here, after processing results, to let reload of search results work.
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
    if ([(NSArray*)content count] > 0)
    {
        // Determine format.
        NSDictionary* area = [content firstObject];
        switch (numberTypeMask)
        {
            case NumberTypeGeographicMask:
            {
                if ([area[@"areaName"] caseInsensitiveCompare:@"All cities"] == NSOrderedSame)
                {
                    areaFormat = AreaFormatGeographicException;
                }
                else
                {
                    areaFormat = AreaFormatGeographic;
                }
                break;
            }
            case NumberTypeNationalMask:
            {
                if ([area[@"areaCode"] length] == 0)
                {
                    areaFormat = AreaFormatNationalException;
                }
                else
                {
                    areaFormat = AreaFormatNational;
                }
                break;
            }
            case NumberTypeTollFreeMask:
            {
                areaFormat = AreaFormatTollFree;
                break;
            }
            case NumberTypeMobileMask:
            {
                areaFormat = AreaFormatMobile;
                break;
            }
            case NumberTypeSharedCostMask:
            {
                areaFormat = AreaFormatSharedCost;
                break;
            }
            case NumberTypeSpecialMask:
            {
                areaFormat = AreaFormatSpecial;
                break;
            }
            case NumberTypeInternationalMask:
            {
                areaFormat = AreaFormatInternational;
                break;
            }
        }
        
        self.objectsArray = content;
        [self createIndexOfWidth:1];
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
    if (error.code == WebStatusFailServiceUnavailable)
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
    NSString* name;
    NSString* allCitiesName = NSLocalizedStringWithDefaultValue(@"NumberAreas:Table AllCities", nil, [NSBundle mainBundle],
                                                                @"All cities",
                                                                @"Indicates that something applies to all "
                                                                @"cities of a country.\n"
                                                                @"[1 line larger font].");

    switch (areaFormat)
    {
        case AreaFormatGeographic:          name = [Common capitalizedString:object[@"areaName"]]; break;
        case AreaFormatGeographicException: name = allCitiesName;                                  break;
        case AreaFormatNational:            name = object[@"areaCode"];                            break;
        case AreaFormatNationalException:   name = @"-";                                           break;
        case AreaFormatTollFree:            name = object[@"areaCode"];                            break;
        case AreaFormatMobile:              name = object[@"areaCode"];                            break;
        case AreaFormatSharedCost:          name = object[@"areaCode"];                            break;
        case AreaFormatSpecial:             name = [Common capitalizedString:object[@"areaName"]]; break;
        case AreaFormatInternational:       name = @"-";                                           break;
    }
    
    return name;
}


#pragma mark - Table View Delegates

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString*     name = [self nameOnTable:tableView atIndexPath:indexPath];
    NSDictionary* area;

    // Look up area.
    for (area in self.objectsArray)
    {
        if ([[self nameForObject:area] isEqualToString:name])
        {
            break;
        }
    }

    NumberAreaViewController* viewController;
    viewController = [[NumberAreaViewController alloc] initWithIsoCountryCode:isoCountryCode
                                                                        state:state
                                                                         area:area
                                                               numberTypeMask:numberTypeMask];
    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberAreasCell* cell;
    NSDictionary*    area;
    NSString*        code;
    NSString*        name;
    NSString*        type = [NumberType localizedStringForNumberTypeMask:numberTypeMask];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumberAreasCell"];
    if (cell == nil)
    {
        cell = [[NumberAreasCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NumberAreasCell"];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    // Look up area.
    name = [self nameOnTable:tableView atIndexPath:indexPath];
    for (area in self.objectsArray)
    {
        if ([[self nameForObject:area] isEqualToString:name])
        {
            break;
        }
    }

    switch (areaFormat)
    {
        case AreaFormatGeographic:          code = area[@"areaCode"]; name = [self nameForObject:area]; break;
        case AreaFormatGeographicException: code = area[@"areaCode"]; name = [self nameForObject:area]; break;
        case AreaFormatNational:            code = area[@"areaCode"]; name = type;                      break;
        case AreaFormatNationalException:   code = @"---";            name = type;                      break;
        case AreaFormatTollFree:            code = area[@"areaCode"]; name = type;                      break;
        case AreaFormatMobile:              code = area[@"areaCode"]; name = type;                      break;
        case AreaFormatSharedCost:          code = area[@"areaCode"]; name = type;                      break;
        case AreaFormatSpecial:             code = area[@"areaCode"]; name = [self nameForObject:area]; break;
        case AreaFormatInternational:       code = @"---";            name = type;                      break;
    }

    cell.areaCode.text = code;
    cell.areaName.text = name;

    return cell;
}

@end
