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
#import "NumberAreaViewController.h"
#import "IncomingChargesViewController.h"
#import "NumberType.h"
#import "WebClient.h"
#import "CountryNames.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "Common.h"
#import "Settings.h"
#import "AddressType.h"
#import "DataManager.h"
#import "PurchaseManager.h"

typedef NS_ENUM(NSUInteger, AreaFormat)
{
    AreaFormatGeographic,
    AreaFormatNational,
    AreaFormatNationalException,
    AreaFormatTollFree,
    AreaFormatMobile,
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
        NSDictionary* area = [content firstObject];

        [self checkAreaForExtranationalAddress:area];

        // Determine format.
        switch (numberTypeMask)
        {
            case NumberTypeGeographicMask:
            {
                areaFormat = AreaFormatGeographic;
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
            case NumberTypeMobileMask:
            {
                areaFormat = AreaFormatMobile;
                break;
            }
            case NumberTypeTollFreeMask:
            {
                areaFormat = AreaFormatTollFree;
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


- (void)checkAreaForExtranationalAddress:(NSDictionary*)area
{
    AddressTypeMask addressType = [AddressType addressTypeMaskForString:area[@"addressType"]];
    if (addressType == AddressTypeExtranational)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"isoCountryCode != %@", isoCountryCode];

        NSArray* addresses = [[DataManager sharedManager] fetchEntitiesWithName:@"Address"
                                                                       sortKeys:nil
                                                                      predicate:predicate
                                                           managedObjectContext:nil];

        if (addresses.count == 0)
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"NumberAreas ...", nil, [NSBundle mainBundle],
                                                        @"Only For Foreigners",
                                                        @"....\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"NumberAreas ...", nil,
                                                        [NSBundle mainBundle],
                                                        @"Legal requirements dictate that %@ Numbers in this country "
                                                        @"can not be purchased by residents nor by local companies.",
                                                        @"....\n"
                                                        @"[iOS alert message size!]");\
            message = [NSString stringWithFormat:message, [NumberType localizedStringForNumberTypeMask:numberTypeMask]];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:nil
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }
}


#pragma mark - Base Class Override

- (NSString*)nameForObject:(id)object
{
    NSString* name;

    switch (areaFormat)
    {
        case AreaFormatGeographic:          name = [Common capitalizedString:object[@"areaName"]]; break;
        case AreaFormatNational:            name = object[@"areaCode"];                            break;
        case AreaFormatNationalException:   name = @"-";                                           break;
        case AreaFormatTollFree:            name = object[@"areaCode"];                            break;
        case AreaFormatMobile:              name = object[@"areaCode"];                            break;
        case AreaFormatInternational:       name = @"-";                                           break;
    }

    // To allow searching for area code, add it behind the name. Before display it will be stripped away again below.
    if (areaFormat == AreaFormatGeographic)
    {
        name = [NSString stringWithFormat:@"%@ %@", name, object[@"areaCode"]];
    }
    
    return name;
}


#pragma mark - Table View Delegates

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary* area = [self objectOnTableView:tableView atIndexPath:indexPath];

    if ([area[@"stock"] intValue] == 0)
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"NumberAreas NoStockTitle", nil,
                                                    [NSBundle mainBundle], @"No Stock",
                                                    @"Alert title telling that loading countries over internet failed.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberAreas NoStockMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"Numbers in this area are currently out of stock.\n\n"
                                                    @"Please check back later.",
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

    NumberAreaViewController* viewController;
    viewController = [[NumberAreaViewController alloc] initWithIsoCountryCode:isoCountryCode
                                                                        state:state
                                                                         area:area
                                                               numberTypeMask:numberTypeMask];
    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSDictionary*    area = [self objectOnTableView:tableView atIndexPath:indexPath];
    NSString*        code;
    NSString*        name;
    NSString*        type = [NumberType localizedStringForNumberTypeMask:numberTypeMask];
    UILabel*         priceLabel;
    const NSInteger  priceLabelTag = 5678;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
        cell.accessoryType = UITableViewCellAccessoryNone;

        priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(82, 25, 224, 17)];
        priceLabel.textAlignment = NSTextAlignmentRight;
        priceLabel.font          = cell.detailTextLabel.font;
        priceLabel.textColor     = [Skinning priceColor];
        priceLabel.tag           = priceLabelTag;

        [cell.contentView addSubview:priceLabel];
    }
    else
    {
        priceLabel = (UILabel*)[cell viewWithTag:priceLabelTag];
    }

    switch (areaFormat)
    {
        case AreaFormatGeographic:        code = area[@"areaCode"]; name = [self nameForObject:area]; break;
        case AreaFormatNational:          code = area[@"areaCode"]; name = type;                      break;
        case AreaFormatNationalException: code = @"---";            name = type;                      break;
        case AreaFormatTollFree:          code = area[@"areaCode"]; name = type;                      break;
        case AreaFormatMobile:            code = area[@"areaCode"]; name = type;                      break;
        case AreaFormatInternational:     code = @"---";            name = type;                      break;
    }

    // Strip away area code that was only added to the names to allow searching for it.
    if (areaFormat == AreaFormatGeographic)
    {
        NSMutableArray* components = [[name componentsSeparatedByString:@" "] mutableCopy];
        [components removeObjectAtIndex:(components.count - 1)];
        name = [components componentsJoinedByString:@" "];
    }

    cell.imageView.image      = [UIImage imageNamed:isoCountryCode];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"+%@ %@", [Common callingCodeForCountry:isoCountryCode], code];

    float     monthPrice       = [area[@"monthFee"] floatValue];
    NSString* monthPriceString = [[PurchaseManager sharedManager] localizedFormattedPrice:monthPrice];
    priceLabel.text = [NSString stringWithFormat:@"%@ / %@", monthPriceString, [Strings monthString]];

    if ([area[@"stock"] intValue] > 0)
    {
        cell.textLabel.text = name;
    }
    else
    {
        cell.textLabel.attributedText = [Common strikethroughAttributedString:name];
    }

    if ([IncomingChargesViewController hasIncomingChargesWithArea:area])
    {
        if (cell.accessoryView == nil)
        {
            UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(0, 0, 44, 44);

            // Shift image a little upwards to prevent overlapping `priceLabel`.
            [button setImageEdgeInsets:UIEdgeInsetsMake(-1, (44 - 30) / 2, (44 - 30) + 1, (44 - 30) / 2)];

            UIColor* highlightColor = [UIColor colorWithRed:0.83 green:0.87 blue:0.98 alpha:1.0];
            [button setImage:[Common maskedImageNamed:@"DollarCents" color:[Skinning tintColor]]
                    forState:UIControlStateNormal];
            [button setImage:[Common maskedImageNamed:@"DollarCents" color:highlightColor]
                    forState:UIControlStateHighlighted];

            [button addTarget:self action:@selector(priceTagAction) forControlEvents:UIControlEventTouchUpInside];
            
            cell.accessoryView = button;
        }
    }
    else
    {
        cell.accessoryView = nil;
    }

    return cell;
}


- (void)priceTagAction
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"NumberAreas CallChargesTitle", nil, [NSBundle mainBundle],
                                                @"Incoming Call Charges",
                                                @"....\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"NumberAreas CallChargesMessage", nil, [NSBundle mainBundle],
                                                @"When someone calls you at such a Number, additional charges apply."
                                                @"\n\nThe exact amounts per minute can be found from the next page.",
                                                @"....\n"
                                                @"[iOS alert message size!]");
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:nil
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}

@end
