//
//  NumberAreaViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 11/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <objc/runtime.h>
#import "NumberAreaViewController.h"
#import "NumberAreaZipsViewController.h"
#import "NumberAreaCitiesViewController.h"
#import "CommonStrings.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Common.h"
#import "CountryNames.h"
#import "NumberAreaActionCell.h"
#import "PurchaseManager.h"


typedef enum
{
    TableSectionArea    = 1UL << 0, // Type, area code, area name, state, country.
    TableSectionNaming  = 1UL << 1, // Name given by user.
    TableSectionName    = 1UL << 2, // Salutation, irst, last, company.
    TableSectionAddress = 1UL << 3, // Street, number, city, zipcode.
    TableSectionAction  = 1UL << 4, // Check info, or Buy.
} TableSections;

typedef enum
{
    AreaRowType     = 1UL << 0,
    AreaRowAreaCode = 1UL << 1,
    AreaRowAreaName = 1UL << 2,
    AreaRowState    = 1UL << 3,
    AreaRowCountry  = 1UL << 4,
} AreaRows;


static const int    TextFieldCellTag = 1234;
static const int    CountryCellTag   = 4321;


@interface NumberAreaViewController ()
{
    NSDictionary*           country;
    NSDictionary*           state;
    NSDictionary*           area;
    NumberTypeMask          numberTypeMask;

    NSArray*                citiesArray;
    NSMutableDictionary*    purchaseInfo;
    BOOL                    requireInfo;
    BOOL                    isChecked;
    TableSections           sections;
    AreaRows                areaRows;

    UITextField*            zipCodeTextField;
    UITextField*            cityTextField;

    NSIndexPath*            nameIndexPath;
    NSIndexPath*            salutationIndexPath;
    NSIndexPath*            firstNameIndexPath;
    NSIndexPath*            lastNameIndexPath;
    NSIndexPath*            companyIndexPath;
    NSIndexPath*            streetIndexPath;
    NSIndexPath*            buildingIndexPath;
    NSIndexPath*            zipCodeIndexPath;
    NSIndexPath*            cityIndexPath;

    NSIndexPath*            nextIndexPath;      // Index-path of cell to show after Next button is tapped.

    // Keyboard stuff.
    BOOL                    keyboardShown;
    CGFloat                 keyboardOverlap;
    NSIndexPath*            activeCellIndexPath;
}

@end


@implementation NumberAreaViewController

- (id)initWithCountry:(NSDictionary*)theCountry
                state:(NSDictionary*)theState
                 area:(NSDictionary*)theArea
       numberTypeMask:(NumberTypeMask)theNumberTypeMask
{    
    if (self = [super initWithNibName:@"NumberAreaView" bundle:nil])
    {
        country        = theCountry;
        state          = theState;
        area           = theArea;
        numberTypeMask = theNumberTypeMask;
        purchaseInfo   = [NSMutableDictionary dictionary];
        requireInfo    = [area[@"requireInfo"] boolValue];

        // Mandatory sections.
        sections |= TableSectionArea;
        sections |= TableSectionNaming;
        sections |= TableSectionAction;

        // Optional Sections.
        sections |= requireInfo ? TableSectionName    : 0;
        sections |= requireInfo ? TableSectionAddress : 0;

        // Always there Area section rows.
        areaRows |= AreaRowType;
        areaRows |= AreaRowCountry;
        
        // Conditionally there Area section rows.
        BOOL    allCities = [[area objectForKey:@"areaName"] caseInsensitiveCompare:@"All cities"] == NSOrderedSame;
        areaRows |= ([area[@"areaCode"] length] > 0) ?                           AreaRowAreaCode : 0;
        areaRows |= (numberTypeMask == NumberTypeGeographicMask && !allCities) ? AreaRowAreaName : 0;
        areaRows |= (state != nil) ?                                             AreaRowState    : 0;

        [self initializeIndexPaths];
   }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem*    cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    // Let keyboard be hidden when user taps outside text fields.
    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:gestureRecognizer];
    
    [self addKeyboardNotifications];

    if (requireInfo)
    {
        self.navigationItem.title = [CommonStrings loadingString];
        [self loadData];
    }
    else
    {
        self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberArea ScreenTitle", nil,
                                                                      [NSBundle mainBundle], @"Area",
                                                                      @"Title of app screen with one area.\n"
                                                                      @"[1 line larger font].");
    }

    [self.tableView registerNib:[UINib nibWithNibName:@"NumberAreaActionCell" bundle:nil]
         forCellReuseIdentifier:@"NumberAreaActionCell"];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    zipCodeTextField.text = purchaseInfo[@"zipCode"];
    cityTextField.text    = purchaseInfo[@"city"];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    NSString*   areaCode = [area[@"areaCode"] length] > 0 ? area[@"areaCode"] : @"0";

    [[WebClient sharedClient] cancelAllRetrieveAreaInfoForIsoCountryCode:country[@"isoCountryCode"]
                                                                areaCode:areaCode];
}


#pragma mark - Helper Methods

- (void)hideKeyboard:(UIGestureRecognizer*)gestureRecognizer
{
    [[self.tableView superview] endEditing:YES];
}


- (void)loadData
{
    NSString*   areaCode = [area[@"areaCode"] length] > 0 ? area[@"areaCode"] : @"0";

    [[WebClient sharedClient] retrieveNumberAreaInfoForIsoCountryCode:country[@"isoCountryCode"]
                                                             areaCode:areaCode
                                                                reply:^(WebClientStatus status, id content)
    {
        if (status == WebClientStatusOk)
        {
            self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberArea ScreenTitle", nil,
                                                                          [NSBundle mainBundle], @"Area",
                                                                          @"Title of app screen with one area.\n"
                                                                          @"[1 line larger font].");
            citiesArray = [NSArray arrayWithArray:content];
            purchaseInfo[@"zipCode"] = @"";     // Resets what user may have typed while loading (on slow internet).
            purchaseInfo[@"city"]    = @"";     // Resets what user may have typed while loading (on slow internet).

            [self.tableView reloadData];
        }
        else if (status == WebClientStatusFailServiceUnavailable)
        {
            NSString*   title;
            NSString*   message;

            title = NSLocalizedStringWithDefaultValue(@"NumberArea UnavailableAlertTitle", nil,
                                                      [NSBundle mainBundle], @"Service Unavailable",
                                                      @"Alert title telling that an online service is not available.\n"
                                                      @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"NumberArea UnavailableAlertMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"The service for buying numbers is temporarily offline."
                                                        @"\n\nPlease try again later.",
                                                        @"Alert message telling that an online service is not available.\n"
                                                        @"[iOS alert message size]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[CommonStrings cancelString]
                                 otherButtonTitles:nil];
        }
        else
        {
            NSString*   title;
            NSString*   message;

            title = NSLocalizedStringWithDefaultValue(@"NumberArea LoadFailAlertTitle", nil,
                                                      [NSBundle mainBundle], @"Loading Failed",
                                                      @"Alert title telling that loading information over internet failed.\n"
                                                      @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"NumberArea LoadFailAlertMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Loading the list of cities and ZIP codes failed.\n\nPlease try again later.",
                                                        @"Alert message telling that loading information over internet failed.\n"
                                                        @"[iOS alert message size - use correct term for ZIP code]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[CommonStrings cancelString]
                                 otherButtonTitles:nil];
        }
    }];
}


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (UITextField*)addTextFieldToCell:(UITableViewCell*)cell
{
    UITextField*    textField;
    CGRect          frame = CGRectMake(83, 6, 198, 30);

    textField = [[UITextField alloc] initWithFrame:frame];
    [textField setFont:[UIFont boldSystemFontOfSize:15]];

    textField.adjustsFontSizeToFitWidth = NO;
    textField.autocapitalizationType    = UITextAutocapitalizationTypeWords;
    textField.clearButtonMode           = UITextFieldViewModeWhileEditing;
    textField.contentVerticalAlignment  = UIControlContentVerticalAlignmentCenter;

    textField.delegate                  = self;

    [cell.contentView addSubview:textField];

    return textField;
}


- (NSIndexPath*)nextEmptyIndexPathForKey:(NSString*)currentKey
{
    unsigned    emptyMask  = 0;
    unsigned    currentBit = 0;

    if (requireInfo)
    {
        emptyMask |= ([purchaseInfo[@"name"]       length] == 0) << 0;
        emptyMask |= ([purchaseInfo[@"salutation"] length] == 0) << 1;
        emptyMask |= ([purchaseInfo[@"firstName"]  length] == 0) << 2;
        emptyMask |= ([purchaseInfo[@"lastName"]   length] == 0) << 3;
        emptyMask |= ([purchaseInfo[@"company"]    length] == 0) << 4;
        emptyMask |= ([purchaseInfo[@"street"]     length] == 0) << 5;
        emptyMask |= ([purchaseInfo[@"building"]   length] == 0) << 6;
        if (citiesArray.count == 0)
        {
            emptyMask |= ([purchaseInfo[@"zipCode"]    length] == 0) << 7;
            emptyMask |= ([purchaseInfo[@"city"]       length] == 0) << 8;
        }
    }
    else
    {
        emptyMask |= ([purchaseInfo[@"name"]       length] == 0) << 0;
    }

    if (emptyMask != 0)
    {
        currentBit |= [currentKey isEqualToString:@"name"]       << 0;
        currentBit |= [currentKey isEqualToString:@"salutation"] << 1;
        currentBit |= [currentKey isEqualToString:@"firstName"]  << 2;
        currentBit |= [currentKey isEqualToString:@"lastName"]   << 3;
        currentBit |= [currentKey isEqualToString:@"company"]    << 4;
        currentBit |= [currentKey isEqualToString:@"street"]     << 5;
        currentBit |= [currentKey isEqualToString:@"building"]   << 6;
        currentBit |= [currentKey isEqualToString:@"zipCode"]    << 7;
        currentBit |= [currentKey isEqualToString:@"city"]       << 8;

        // Find next bit set in emptyMask.
        unsigned    nextBit = currentBit << 1;
        while ((nextBit & emptyMask) == 0 && nextBit != 0)
        {
            nextBit <<= 1;
        }

        // When not found yet, start from begin.
        if (nextBit == 0)
        {
            nextBit = 1;
            while (((nextBit & emptyMask) == 0 || nextBit == currentBit) && nextBit != 0)
            {
                nextBit <<= 1;
            }
        }

        NSIndexPath*    indexPath = nil;
        indexPath = (nextBit == (1 << 0)) ? nameIndexPath       : indexPath;
        indexPath = (nextBit == (1 << 1)) ? salutationIndexPath : indexPath;
        indexPath = (nextBit == (1 << 2)) ? firstNameIndexPath  : indexPath;
        indexPath = (nextBit == (1 << 3)) ? lastNameIndexPath   : indexPath;
        indexPath = (nextBit == (1 << 4)) ? companyIndexPath    : indexPath;
        indexPath = (nextBit == (1 << 5)) ? streetIndexPath     : indexPath;
        indexPath = (nextBit == (1 << 6)) ? buildingIndexPath   : indexPath;
        indexPath = (nextBit == (1 << 7)) ? zipCodeIndexPath    : indexPath;
        indexPath = (nextBit == (1 << 8)) ? cityIndexPath       : indexPath;
        
        return indexPath;
    }
    else
    {
        return nil;
    }
}


- (BOOL)isPurchaseInfoComplete
{
    BOOL    complete;

    if (requireInfo == YES)
    {
        complete = ([purchaseInfo[@"name"] length]       > 0 &&
                    [purchaseInfo[@"salutation"] length] > 0 &&
                    [purchaseInfo[@"firstName"] length]  > 0 &&
                    [purchaseInfo[@"lastName"] length]   > 0 &&
                    [purchaseInfo[@"company"] length]    > 0 &&
                    [purchaseInfo[@"street"] length]     > 0 &&
                    [purchaseInfo[@"building"] length]   > 0 &&
                    [purchaseInfo[@"zipCode"] length]    > 0 &&
                    [purchaseInfo[@"city"] length]       > 0);
    }
    else
    {
        complete = ([purchaseInfo[@"name"] length]       > 0);
    }

    return complete;
}


- (void)initializeIndexPaths
{
    nameIndexPath       = [NSIndexPath indexPathForItem:0 inSection:1];
    salutationIndexPath = [NSIndexPath indexPathForItem:0 inSection:2];
    firstNameIndexPath  = [NSIndexPath indexPathForItem:1 inSection:2];
    lastNameIndexPath   = [NSIndexPath indexPathForItem:2 inSection:2];
    companyIndexPath    = [NSIndexPath indexPathForItem:3 inSection:2];
    streetIndexPath     = [NSIndexPath indexPathForItem:0 inSection:3];
    buildingIndexPath   = [NSIndexPath indexPathForItem:1 inSection:3];
    zipCodeIndexPath    = [NSIndexPath indexPathForItem:2 inSection:3];
    cityIndexPath       = [NSIndexPath indexPathForItem:3 inSection:3];
 }


- (void)addCountryImageToCell:(UITableViewCell*)cell isoCountryCode:(NSString*)isoCountryCode
{
    UIImage*        image = [UIImage imageNamed:isoCountryCode];
    UIImageView*    imageView = (UIImageView*)[cell viewWithTag:CountryCellTag];
    CGRect          frame = CGRectMake(33, 4, image.size.width, image.size.height);

    imageView = (imageView == nil) ? [[UIImageView alloc] initWithFrame:frame] : imageView;
    imageView.tag = CountryCellTag;
    imageView.image = image;

    [cell.contentView addSubview:imageView];
}


- (NSIndexPath*)findCellIndexPathForSubview:(UIView*)subview
{
    UIView* superview = subview.superview;
    while ([superview class] != [UITableViewCell class])
    {
        superview = superview.superview;
    }

    return [self.tableView indexPathForCell:(UITableViewCell*)superview];
}


- (NSString*)priceString
{
    NSString*   string;
    NSString*   productIdentifier;
    float       tier;

#warning THIS IS A FAKE CALCULATION FOR EURO, MUST BE DONE ON SERVER!!!
#warning Also add setup fee: Probably best as purchased item as well, otherwise the user may need to buy credit which complicates both app and user experience.
    tier = [area[@"renewalFeeTier"] intValue];
    tier = tier * (100.0f / 70.0f) * 1.5 * 1.05;   // 30% Apple margin + 50% our profit margin + currency risk margin.
    tier = tier / 100.0f  / 0.89f;
    NSLog(@"TIER %d", (int)roundf(tier));

    productIdentifier = [[PurchaseManager sharedManager] productIdentifierForNumberSubscriptionTier:(int)roundf(tier)];
 
    if (productIdentifier == nil)
    {
        NSLog(@"//### We have a serious problem here!");
        string = @"----";
    }
    else
    {
        string = [[PurchaseManager sharedManager] localizedPriceForProductIdentifier:productIdentifier];
    }
    
    return string;
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:sections];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionArea:
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Area SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Current Selection",
                                                      @"...");
            break;

        case TableSectionNaming:
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Naming SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Enter a Name...",
                                                      @"...");
            break;

        case TableSectionName:
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Name SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Supply Contact Name...",
                                                      @"Name and company of someone.");
            break;

        case TableSectionAddress:
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Address SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Supply Contact Address...",
                                                      @"Address of someone.");
            break;

        case TableSectionAction:
            break;
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionArea:
            break;

        case TableSectionNaming:
            title = [CommonStrings nameFooterString];
            break;

        case TableSectionName:
            break;

        case TableSectionAddress:
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Address SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"For a phone number in this area, a contact name and address "
                                                      @"are (legally) required.",
                                                      @"Explaining that information must be supplied by user.");
            break;

        case TableSectionAction:
            if (requireInfo == YES && isChecked == NO)
            {
                title = NSLocalizedStringWithDefaultValue(@"NumberArea:Action SectionFooter", nil,
                                                          [NSBundle mainBundle],
                                                          @"The information supplied must first be checked.",
                                                          @"Telephone area (or city).");
            }
            break;
    }

    return title;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger   numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionArea:
            numberOfRows = [Common bitsSetCount:areaRows];
            break;

        case TableSectionNaming:
            numberOfRows = 1;
            break;

        case TableSectionName:
            numberOfRows = requireInfo ? 4 : 0;
            break;

        case TableSectionAddress:
            numberOfRows = requireInfo ? 4 : 0;
            break;

        case TableSectionAction:
            numberOfRows = 1;
            break;
    }

    return numberOfRows;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberAreaZipsViewController*   zipsViewController;
    NumberAreaCitiesViewController* citiesViewController;

    if ([self.tableView cellForRowAtIndexPath:indexPath].selectionStyle == UITableViewCellSelectionStyleNone)
    {
        return;
    }
    else
    {
        switch ([Common nthBitSet:indexPath.section inValue:sections])
        {
            case TableSectionAddress:
                switch (indexPath.row)
                {
                    case 2:
                        zipsViewController = [[NumberAreaZipsViewController alloc] initWithCitiesArray:citiesArray
                                                                                          purchaseInfo:purchaseInfo];
                        [self.navigationController pushViewController:zipsViewController animated:YES];
                        break;
                        
                    case 3:
                        citiesViewController = [[NumberAreaCitiesViewController alloc] initWithCitiesArray:citiesArray
                                                                                              purchaseInfo:purchaseInfo];
                        [self.navigationController pushViewController:citiesViewController animated:YES];
                        break;
                }
                break;

            case TableSectionAction:
                if ([self isPurchaseInfoComplete] == YES)
                {
                    if (requireInfo == YES && isChecked == NO)
                    {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

                        purchaseInfo[@"isoCountryCode"] = country[@"isoCountryCode"];
                        purchaseInfo[@"numberType"]     = area[@"numberType"];
                        purchaseInfo[@"areaCode"]       = area[@"areaCode"];
                        [[WebClient sharedClient] checkPurchaseInfo:purchaseInfo
                                                              reply:^(WebClientStatus status, id content)
                        {
                            if (status == WebClientStatusOk)
                            {
                                isChecked = YES;
                                [self.tableView beginUpdates];
                                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                                              withRowAnimation:UITableViewRowAnimationFade];
                                [self.tableView endUpdates];                                
                            }
                            else
                            {
                                // differentiate between network error, and not validated.

                            }
                        }];
                    }
                    else
                    {
                        //### Buy number subscription + setup fee
                        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                    }
                }
                else
                {
                    NSString*   title;
                    NSString*   message;

                    title = NSLocalizedStringWithDefaultValue(@"NumberArea InfoIncompleteAlertTitle", nil,
                                                              [NSBundle mainBundle], @"Information Missing",
                                                              @"Alert title telling that user did not fill in all information.\n"
                                                              @"[iOS alert title size].");
                    message = NSLocalizedStringWithDefaultValue(@"NumberArea LoadFailAlertMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"Some of the required information has not been supplied yet.",
                                                                @"Alert message telling that user did not fill in all information.\n"
                                                                @"[iOS alert message size]");
                    [BlockAlertView showAlertViewWithTitle:title
                                                   message:message
                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                     {
                         [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                     }
                                         cancelButtonTitle:[CommonStrings closeString]
                                         otherButtonTitles:nil];
                }
                break;
        }
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionArea:
            cell = [self areaCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionNaming:
            cell = [self namingCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionName:
            cell = [self nameCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionAddress:
            cell = [self addressCellForRowAtIndexPath:indexPath];
            break;
            
        case TableSectionAction:
            cell = [self actionCellForRowAtIndexPath:indexPath];
            break;
    }

    return cell;
}


- (UITableViewCell*)areaCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NSString*           identifier;

    identifier  = ([Common nthBitSet:indexPath.row inValue:areaRows] == AreaRowCountry) ? @"CountryCell"
                                                                                           : @"Value2Cell";
    cell        = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:identifier];
    }

    switch ([Common nthBitSet:indexPath.row inValue:areaRows])
    {
        case AreaRowType:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:NumberType Label", nil,
                                                                    [NSBundle mainBundle], @"Type",
                                                                    @"....");
            cell.detailTextLabel.text = [NumberType localizedStringForNumberType:numberTypeMask];
            cell.imageView.image = nil;
            break;

        case AreaRowAreaCode:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:AreaCode Label", nil,
                                                                    [NSBundle mainBundle], @"Area Code",
                                                                    @"....");
            cell.detailTextLabel.text = area[@"areaCode"];
            cell.imageView.image = nil;
            break;

        case AreaRowAreaName:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:AreaName Label", nil,
                                                                    [NSBundle mainBundle], @"Area",
                                                                    @"....");
            cell.detailTextLabel.text = area[@"areaName"];
            cell.imageView.image = nil;
            break;

        case AreaRowState:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:State Label", nil,
                                                                    [NSBundle mainBundle], @"State",
                                                                    @"....");
            cell.detailTextLabel.text = state[@"stateName"];
            cell.imageView.image = nil;
            break;

        case AreaRowCountry:
            cell.textLabel.text = @" ";     // Without this, the detailTextLabel is on the left.
            cell.detailTextLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:country[@"isoCountryCode"]];
            [self addCountryImageToCell:cell isoCountryCode:country[@"isoCountryCode"]];
            break;
    }

    cell.accessoryType  = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)namingCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    UITextField*        textField;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"TextFieldCell"];
        textField = [self addTextFieldToCell:cell];
        textField.tag = TextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
    }

    cell.textLabel.text   = [CommonStrings nameString];
    textField.placeholder = [CommonStrings requiredString];
    textField.text        = purchaseInfo[@"name"];
    objc_setAssociatedObject(textField, @"PurchaseInfoKey", @"name", OBJC_ASSOCIATION_RETAIN);

    cell.detailTextLabel.text = nil;
    cell.imageView.image = nil;
    cell.accessoryType   = UITableViewCellAccessoryNone;
    cell.selectionStyle  = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)nameCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    UITextField*        textField;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"TextFieldCell"];
        textField = [self addTextFieldToCell:cell];
        textField.tag = TextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
    }

    switch (indexPath.row)
    {
        case 0:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:Salutation Label", nil,
                                                                    [NSBundle mainBundle], @"Title",
                                                                    @"....");
            textField.placeholder = NSLocalizedStringWithDefaultValue(@"NumberArea:Salutation Placeholder", nil,
                                                                      [NSBundle mainBundle], @"Required (Mr, Mrs, ...) ",
                                                                      @"....");
            textField.text = purchaseInfo[@"salutation"];
            objc_setAssociatedObject(textField, @"PurchaseInfoKey", @"salutation", OBJC_ASSOCIATION_RETAIN);
            break;

        case 1:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:FirstName Label", nil,
                                                                    [NSBundle mainBundle], @"Firstname",
                                                                    @"....");
            textField.placeholder = [CommonStrings requiredString];
            textField.text = purchaseInfo[@"firstName"];
            objc_setAssociatedObject(textField, @"PurchaseInfoKey", @"firstName", OBJC_ASSOCIATION_RETAIN);
            break;

        case 2:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:LastName Label", nil,
                                                                    [NSBundle mainBundle], @"Lastname",
                                                                    @"....");
            textField.placeholder = [CommonStrings requiredString];
            textField.text = purchaseInfo[@"lastName"];
            objc_setAssociatedObject(textField, @"PurchaseInfoKey", @"lastName", OBJC_ASSOCIATION_RETAIN);
            break;

        case 3:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:Company Label", nil,
                                                                    [NSBundle mainBundle], @"Company",
                                                                    @"....");
            textField.placeholder = [CommonStrings requiredString];
            textField.text = purchaseInfo[@"company"];
            objc_setAssociatedObject(textField, @"PurchaseInfoKey", @"company", OBJC_ASSOCIATION_RETAIN);
            break;
    }

    cell.detailTextLabel.text = nil;
    cell.imageView.image      = nil;
    cell.accessoryType        = UITableViewCellAccessoryNone;
    cell.selectionStyle       = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)addressCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NSString*           identifier = (indexPath.row <= 1 || citiesArray.count == 0) ? @"TextFieldCell" :
                                                                                      @"DisabledTextFieldCell";
    UITextField*        textField;
    BOOL                singleZipCode = NO;
    BOOL                singleCity    = NO;

    if (citiesArray.count == 1)
    {
        singleCity = YES;
        purchaseInfo[@"city"] = citiesArray[0][@"city"];

        NSArray*    zipCodes = citiesArray[0][@"zipCodes"];
        if ([zipCodes count] == 1)
        {
            singleZipCode = YES;
            purchaseInfo[@"zipCode"] = citiesArray[0][@"zipCodes"][0];
        }
    }

    cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:identifier];
        cell.accessoryType  = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        textField = [self addTextFieldToCell:cell];
        textField.tag = TextFieldCellTag;
    }
    else
    {
        cell.accessoryType  = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        textField = (UITextField*)[cell.contentView viewWithTag:TextFieldCellTag];
    }

    switch (indexPath.row)
    {
        case 0:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:Street Label", nil,
                                                                    [NSBundle mainBundle], @"Street",
                                                                    @"....");
            textField.placeholder = [CommonStrings requiredString];
            textField.text = purchaseInfo[@"street"];
            objc_setAssociatedObject(textField, @"PurchaseInfoKey", @"street", OBJC_ASSOCIATION_RETAIN);
            break;

        case 1:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:Building Label", nil,
                                                                    [NSBundle mainBundle], @"Building",
                                                                    @"....");
            textField.placeholder = [CommonStrings requiredString];
            textField.text = purchaseInfo[@"building"];
            objc_setAssociatedObject(textField, @"PurchaseInfoKey", @"building", OBJC_ASSOCIATION_RETAIN);
            break;

        case 2:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:ZipCode Label", nil,
                                                                    [NSBundle mainBundle], @"ZIP Code",
                                                                    @"Postalcode, Post Code, ...");
            if (citiesArray.count == 0)
            {
                textField.placeholder = [CommonStrings requiredString];
            }
            else
            {
                if (singleZipCode == NO)
                {
                    textField.placeholder = NSLocalizedStringWithDefaultValue(@"NumberArea:ZipCode Placeholder B", nil,
                                                                              [NSBundle mainBundle],
                                                                              @"Required, select from list",
                                                                              @"....");
                    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    textField.text = nil;
                }
                
                textField.userInteractionEnabled = NO;
            }
            
            zipCodeTextField = textField;
            zipCodeTextField.text = purchaseInfo[@"zipCode"];
            objc_setAssociatedObject(zipCodeTextField, @"PurchaseInfoKey", @"zipCode", OBJC_ASSOCIATION_RETAIN);
            break;

        case 3:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:City Label", nil,
                                                                    [NSBundle mainBundle], @"City",
                                                                    @"....");
            if (citiesArray.count == 0)
            {
                textField.placeholder = [CommonStrings requiredString];
            }
            else
            {
                if (singleCity == NO)
                {
                    textField.placeholder = NSLocalizedStringWithDefaultValue(@"NumberArea:ZipCode Placeholder", nil,
                                                                              [NSBundle mainBundle],
                                                                              @"Required, select from list",
                                                                              @"....");
                    textField.text = nil;
                    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    textField.text = nil;
                }

                textField.userInteractionEnabled = NO;
            }
            
            cityTextField = textField;
            cityTextField.text = [Common capitalizedString:purchaseInfo[@"city"]];
            objc_setAssociatedObject(cityTextField, @"PurchaseInfoKey", @"city", OBJC_ASSOCIATION_RETAIN);
            break;
    }

    cell.detailTextLabel.text = nil;
    cell.imageView.image      = nil;

    return cell;
}


- (UITableViewCell*)actionCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberAreaActionCell*   cell;
    NSString*               text;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumberAreaActionCell"];
    if (cell == nil)
    {
        cell = [[NumberAreaActionCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:@"NumberAreaActionCell"];
    }

    if (requireInfo == YES && isChecked == NO)
    {
        text = NSLocalizedStringWithDefaultValue(@"NumberArea:Action CheckInfoLabel", nil,
                                                 [NSBundle mainBundle],
                                                 @"Validate",
                                                 @"....");
    }
    else
    {
        text = NSLocalizedStringWithDefaultValue(@"NumberArea:Action BuyLabel", nil,
                                                 [NSBundle mainBundle],
                                                 @"Buy %@",
                                                 @"Parameter is price (with currency sign).");
        text = [NSString stringWithFormat:text, [self priceString]];
    }

    cell.label.text = text;

    return cell;
}


#pragma mark - TextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
    NSString*   key = objc_getAssociatedObject(textField, @"PurchaseInfoKey");

    textField.returnKeyType = [self nextEmptyIndexPathForKey:key] ? UIReturnKeyNext : UIReturnKeyDone;
#warning The method reloadInputViews messes up two-byte keyboards (e.g. Kanji).
    [textField reloadInputViews];

    activeCellIndexPath = [self findCellIndexPathForSubview:textField];
    return YES;
}


- (BOOL)textFieldShouldClear:(UITextField*)textField
{
    NSString*   key  = objc_getAssociatedObject(textField, @"PurchaseInfoKey");
    purchaseInfo[key] = @"";

    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    NSString*   key = objc_getAssociatedObject(textField, @"PurchaseInfoKey");

    if ((nextIndexPath = [self nextEmptyIndexPathForKey:key]) != nil)
    {
        UITableViewCell*    cell = [self.tableView cellForRowAtIndexPath:nextIndexPath];

        if (cell != nil)
        {
            UITextField*    nextTextField;

            nextTextField = (UITextField*)[cell.contentView viewWithTag:TextFieldCellTag];
            [nextTextField becomeFirstResponder];
        }
        
        [self.tableView scrollToRowAtIndexPath:nextIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        
        return NO;
    }
    else
    {
        [textField resignFirstResponder];
        
        return YES;
    }
}


- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    NSString*   key  = objc_getAssociatedObject(textField, @"PurchaseInfoKey");

    purchaseInfo[key] = [textField.text stringByReplacingCharactersInRange:range withString:string];

    return YES;
}


#pragma mark - Scrollview Delegate

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView
{
    if (nextIndexPath != nil)
    {
        UITextField*    nextTextField;

        UITableViewCell*    cell = [self.tableView cellForRowAtIndexPath:nextIndexPath];
        nextIndexPath = nil;
        
        nextTextField = (UITextField*)[cell.contentView viewWithTag:TextFieldCellTag];
        [nextTextField becomeFirstResponder];
    }
}


#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch
{
    if ([touch.view isKindOfClass:[UITextField class]] ||
        [touch.view isKindOfClass:[UIButton class]])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}


#pragma mark - Keyboard Handling
// http://stackoverflow.com/questions/13845426/generic-uitableview-keyboard-resizing-algorithm

- (void)addKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}


- (void)keyboardWillShow:(NSNotification*)notification
{
    if (keyboardShown == YES)
    {
        return;
    }
    else
    {
        keyboardShown = YES;
    }

    // Get keyboard size.
    NSDictionary*   userInfo = [notification userInfo];
    NSValue*        value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect          keyboardRect = [self.tableView.superview convertRect:[value CGRectValue] fromView:nil];

    // Get the keyboard's animation details.
    NSTimeInterval  animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];

    // Determine how much overlap exists between tableView and the keyboard
    CGRect tableFrame = self.tableView.frame;
    CGFloat tableLowerYCoord = tableFrame.origin.y + tableFrame.size.height;
    keyboardOverlap = tableLowerYCoord - keyboardRect.origin.y;
    if (self.inputAccessoryView && keyboardOverlap > 0)
    {
        CGFloat accessoryHeight = self.inputAccessoryView.frame.size.height;
        keyboardOverlap -= accessoryHeight;

        self.tableView.contentInset          = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
    }

    if (keyboardOverlap < 0)
    {
        keyboardOverlap = 0;
    }

    if (keyboardOverlap != 0)
    {
        tableFrame.size.height -= keyboardOverlap;

        NSTimeInterval delay = 0;
        if (keyboardRect.size.height)
        {
            delay = (1 - keyboardOverlap/keyboardRect.size.height)*animationDuration;
            animationDuration = animationDuration * keyboardOverlap/keyboardRect.size.height;
        }

        [UIView animateWithDuration:animationDuration delay:delay
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^
        {
            self.tableView.frame = tableFrame;
        }
                         completion:^(BOOL finished)
        {
            [self tableAnimationEnded:nil finished:nil contextInfo:nil];
        }];
    }
}


- (void)keyboardWillHide:(NSNotification*)notification
{
    if (keyboardShown == NO)
    {
        return;
    }
    else
    {
        keyboardShown = NO;
    }

    if (keyboardOverlap == 0)
    {
        return;
    }

    // Get the size & animation details of the keyboard
    NSDictionary*   userInfo = [notification userInfo];
    NSValue*        value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect          keyboardRect = [self.tableView.superview convertRect:[value CGRectValue] fromView:nil];

    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];

    CGRect tableFrame = self.tableView.frame;
    tableFrame.size.height += keyboardOverlap;

    if(keyboardRect.size.height)
    {
        animationDuration = animationDuration * keyboardOverlap/keyboardRect.size.height;
    }

    [UIView animateWithDuration:animationDuration delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^
    {
        self.tableView.frame = tableFrame;
    }
                     completion:nil];
}


- (void)tableAnimationEnded:(NSString*)animationID finished:(NSNumber*)finished contextInfo:(void*)context
{
    // Scroll to the active cell
    if (activeCellIndexPath)
    {
        [self.tableView scrollToRowAtIndexPath:activeCellIndexPath
                              atScrollPosition:UITableViewScrollPositionNone
                                      animated:YES];
        [self.tableView selectRowAtIndexPath:activeCellIndexPath
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionNone];
    }
}

@end
