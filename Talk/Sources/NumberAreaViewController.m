//
//  NumberAreaViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 11/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <objc/runtime.h>
#import "NumberAreaViewController.h"
#import "NumberAreaPostcodesViewController.h"
#import "NumberAreaCitiesViewController.h"
#import "NumberAreaTitlesViewController.h"
#import "BuyNumberViewController.h"
#import "CountriesViewController.h"
#import "AddressViewController.h"
#import "Strings.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Common.h"
#import "CountryNames.h"
#import "NumberAreaActionCell.h"
#import "PurchaseManager.h"
#import "Base64.h"
#import "Skinning.h"
#import "DataManager.h"


// Update reloadSections calls when adding/removing sections.
typedef enum
{
    TableSectionArea           = 1UL << 0, // Type, area code, area name, state, country.
    TableSectionName           = 1UL << 1, // Name given by user.
    TableSectionAddress        = 1UL << 2,
    TableSectionContactName    = 1UL << 3, // Salutation, company, first, last.
    TableSectionContactAddress = 1UL << 4, // Street, number, city, zipcode.
    TableSectionAction         = 1UL << 5, // Check info, or Buy.
} TableSections;

typedef enum
{
    AreaRowType     = 1UL << 0,
    AreaRowAreaCode = 1UL << 1,
    AreaRowAreaName = 1UL << 2,
    AreaRowState    = 1UL << 3,
    AreaRowCountry  = 1UL << 4,
} AreaRows;

typedef enum
{
    InfoTypeNone,
    InfoTypeLocal,
    InfoTypeNational,
    InfoTypeWorldwide,
} InfoType;


@interface NumberAreaViewController ()
{
    NSString*               numberIsoCountryCode;
    NSDictionary*           state;
    NSDictionary*           area;
    NumberTypeMask          numberTypeMask;

    NSArray*                citiesArray;
    NSString*               name;
    NSMutableDictionary*    purchaseInfo;
    InfoType                infoType;
    BOOL                    requireProof;
    BOOL                    isChecked;
    TableSections           sections;
    AreaRows                areaRows;

    UITextField*            salutationTextField;
    UITextField*            companyTextField;
    UITextField*            firstNameTextField;
    UITextField*            lastNameTextField;
    UITextField*            zipCodeTextField;
    UITextField*            cityTextField;
    UITextField*            countryTextField;

    NSIndexPath*            nameIndexPath;
    NSIndexPath*            salutationIndexPath;
    NSIndexPath*            companyIndexPath;
    NSIndexPath*            firstNameIndexPath;
    NSIndexPath*            lastNameIndexPath;
    NSIndexPath*            streetIndexPath;
    NSIndexPath*            buildingIndexPath;
    NSIndexPath*            zipCodeIndexPath;
    NSIndexPath*            cityIndexPath;
    NSIndexPath*            countryIndexPath;
    NSIndexPath*            actionIndexPath;

    NSIndexPath*            nextIndexPath;      // Index-path of cell to show after Next button is tapped.

    // Keyboard stuff.
    BOOL                    keyboardShown;
    CGFloat                 keyboardOverlap;
    NSIndexPath*            activeCellIndexPath;
}

@property (nonatomic, assign) BOOL                     isLoading;
@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;

@end


@implementation NumberAreaViewController

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                                 state:(NSDictionary*)theState
                                  area:(NSDictionary*)theArea
                        numberTypeMask:(NumberTypeMask)theNumberTypeMask
{    
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        numberIsoCountryCode = isoCountryCode;
        state                = theState;
        area                 = theArea;
        numberTypeMask       = theNumberTypeMask;
        requireProof         = [area[@"requireProof"] boolValue];

        if ([area[@"infoType"] isEqualToString:@"NONE"])
        {
            infoType = InfoTypeNone;
        }
        else if ([area[@"infoType"] isEqualToString:@"LOCAL"])
        {
            infoType = InfoTypeLocal;
        }
        else if ([area[@"infoType"] isEqualToString:@"NATIONAL"])
        {
            infoType = InfoTypeNational;
        }
        else if ([area[@"infoType"] isEqualToString:@"WORLDWIDE"])
        {
            infoType = InfoTypeWorldwide;
        }
        else
        {
            infoType = InfoTypeNone;
        }

        if (infoType != InfoTypeNone)
        {
            purchaseInfo = [NSMutableDictionary dictionary];
            purchaseInfo[@"salutation"] = @"MR";
        }

        if (infoType == InfoTypeLocal || infoType == InfoTypeNational)
        {
            purchaseInfo[@"isoCountryCode"] = numberIsoCountryCode;
        }

        // Mandatory sections.
        sections |= TableSectionArea;
        sections |= TableSectionName;
        sections |= TableSectionAddress;
        sections |= TableSectionAction;

        // Optional Sections.
        sections |= (infoType == InfoTypeNone) ? 0 : TableSectionContactName;
        sections |= (infoType == InfoTypeNone) ? 0 : TableSectionContactAddress;

        // Always there Area section rows.
        areaRows |= AreaRowType;
        areaRows |= AreaRowCountry;
        
        // Conditionally there Area section rows.
        BOOL allCities = (area[@"areaName"] != [NSNull null] &&
                          [area[@"areaName"] caseInsensitiveCompare:@"All cities"] == NSOrderedSame);
        areaRows |= ([area[@"areaCode"] length] > 0)                           ? AreaRowAreaCode : 0;
        areaRows |= (numberTypeMask == NumberTypeGeographicMask && !allCities) ? AreaRowAreaName : 0;
        areaRows |= (numberTypeMask == NumberTypeSpecialMask)                  ? AreaRowAreaName : 0;
        areaRows |= (state != nil)                                             ? AreaRowState    : 0;

        // Default naming.
        NSString* city;
        NSString* countryName = [[CountryNames sharedNames] nameForIsoCountryCode:numberIsoCountryCode];
        switch (numberTypeMask)
        {
            case NumberTypeGeographicMask:
            {
                city = [Common capitalizedString:area[@"city"]];
                name = [NSString stringWithFormat:@"%@ (%@)", city, numberIsoCountryCode];
                break;
            }
            case NumberTypeNationalMask:
            {
                name = [NSString stringWithFormat:@"%@ (paid)", countryName];
                break;
            }
            case NumberTypeTollFreeMask:
            {
                name = [NSString stringWithFormat:@"%@ (free)", countryName];
                break;
            }
            case NumberTypeMobileMask:
            {
                name = [NSString stringWithFormat:@"%@ (mobile)", countryName];
                break;
            }
            case NumberTypeSharedCostMask:
            {
                name = [NSString stringWithFormat:@"%@ (shared)", countryName];
                break;
            }
            case NumberTypeSpecialMask:
            {
                name = [NSString stringWithFormat:@"%@ (special)", countryName];
                break;
            }
            case NumberTypeInternationalMask:
            {
                name = [NSString stringWithFormat:@"International (%@)", area[@"areaCode"]];
                break;
            }
        }

        [self initializeIndexPaths];
   }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberArea ScreenTitle", nil,
                                                                  [NSBundle mainBundle], @"Area",
                                                                  @"Title of app screen with one area.\n"
                                                                  @"[1 line larger font].");

    UIBarButtonItem* cancelButton;
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

    if (infoType != InfoTypeNone)
    {
        [self loadData];
    }

    [self.tableView registerNib:[UINib nibWithNibName:@"NumberAreaActionCell" bundle:nil]
         forCellReuseIdentifier:@"NumberAreaActionCell"];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    salutationTextField.text = [Strings localizedSalutation:purchaseInfo[@"salutation"]];
    zipCodeTextField.text    = purchaseInfo[@"postcode"];
    cityTextField.text       = purchaseInfo[@"city"];

    companyTextField.placeholder   = [self placeHolderForTextField:companyTextField];
    firstNameTextField.placeholder = [self placeHolderForTextField:firstNameTextField];
    lastNameTextField.placeholder  = [self placeHolderForTextField:lastNameTextField];

    NumberAreaActionCell* cell = (NumberAreaActionCell*)[self.tableView cellForRowAtIndexPath:actionIndexPath];
    cell.label.text            = [self actionCellText];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    UIView* topView = [[[[UIApplication sharedApplication] keyWindow] subviews] lastObject];
    CGPoint center = topView.center;
    center = [topView convertPoint:center toView:self.view];
    self.activityIndicator.center = center;
}


#pragma mark Property Setter

- (void)setIsLoading:(BOOL)isLoading
{
    _isLoading = isLoading;

    if (isLoading == YES && self.activityIndicator == nil)
    {
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.activityIndicator.color = [UIColor blackColor];

        [self.activityIndicator startAnimating];
        [self.view addSubview:self.activityIndicator];
    }
    else if (self.isLoading == NO && self.activityIndicator != nil)
    {
        [self.activityIndicator stopAnimating];
        [self.activityIndicator removeFromSuperview];
        self.activityIndicator = nil;
    }
}


#pragma mark - Helper Methods

- (void)hideKeyboard:(UIGestureRecognizer*)gestureRecognizer
{
    [[self.tableView superview] endEditing:YES];
}


- (void)loadData
{
    NSString* areaCode = [area[@"areaCode"] length] > 0 ? area[@"areaCode"] : @"0";

    self.isLoading = YES;
    [[WebClient sharedClient] retrieveNumberAreaInfoForIsoCountryCode:numberIsoCountryCode
                                                             areaCode:areaCode
                                                                reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberArea ScreenTitle", nil,
                                                                          [NSBundle mainBundle], @"Area",
                                                                          @"Title of app screen with one area.\n"
                                                                          @"[1 line larger font].");
            citiesArray = [NSArray arrayWithArray:content];
            purchaseInfo[@"postcode"] = @"";     // Resets what user may have typed while loading (on slow internet).
            purchaseInfo[@"city"]     = @"";     // Resets what user may have typed while loading (on slow internet).

            [self.tableView reloadData];
            self.isLoading = NO;    // Placed here, after processing results, to let reload of search results work.
        }
        else if (error.code == WebStatusFailServiceUnavailable)
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"NumberArea UnavailableAlertTitle", nil,
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
                                 cancelButtonTitle:[Strings cancelString]
                                 otherButtonTitles:nil];
        }
        else
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"NumberArea LoadFailAlertTitle", nil,
                                                        [NSBundle mainBundle], @"Loading Failed",
                                                        @"Alert title telling that loading information over internet failed.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"NumberArea LoadFailAlertMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Loading the list of cities and ZIP codes failed: %@\n\nPlease try again later.",
                                                        @"Alert message telling that loading information over internet failed.\n"
                                                        @"[iOS alert message size - use correct term for ZIP code]");
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


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (NSIndexPath*)nextEmptyIndexPathForKey:(NSString*)currentKey
{
    unsigned emptyMask  = 0;
    unsigned currentBit = 0;

    if (infoType == InfoTypeNone)
    {
        emptyMask |= ([name length] == 0) << 0;
    }
    else
    {
        emptyMask |= ([name                       length] == 0) << 0;
        emptyMask |= ([purchaseInfo[@"company"]   length] == 0) << 1;
        emptyMask |= ([purchaseInfo[@"firstName"] length] == 0) << 2;
        emptyMask |= ([purchaseInfo[@"lastName"]  length] == 0) << 3;
        emptyMask |= ([purchaseInfo[@"street"]    length] == 0) << 4;
        emptyMask |= ([purchaseInfo[@"building"]  length] == 0) << 5;
        if (citiesArray.count == 0)
        {
            emptyMask |= ([purchaseInfo[@"postcode"] length] == 0) << 6;
            emptyMask |= ([purchaseInfo[@"city"]     length] == 0) << 7;
        }
    }

    if (emptyMask != 0)
    {
        currentBit |= [currentKey isEqualToString:@"name"]      << 0;
        currentBit |= [currentKey isEqualToString:@"company"]   << 1;
        currentBit |= [currentKey isEqualToString:@"firstName"] << 2;
        currentBit |= [currentKey isEqualToString:@"lastName"]  << 3;
        currentBit |= [currentKey isEqualToString:@"street"]    << 4;
        currentBit |= [currentKey isEqualToString:@"building"]  << 5;
        currentBit |= [currentKey isEqualToString:@"postcode"]  << 6;
        currentBit |= [currentKey isEqualToString:@"city"]      << 7;

        // Find next bit set in emptyMask.
        unsigned nextBit = currentBit << 1;
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

        NSIndexPath* indexPath = nil;
        indexPath = (nextBit == (1 << 0)) ? nameIndexPath      : indexPath;
        indexPath = (nextBit == (1 << 1)) ? companyIndexPath   : indexPath;
        indexPath = (nextBit == (1 << 2)) ? firstNameIndexPath : indexPath;
        indexPath = (nextBit == (1 << 3)) ? lastNameIndexPath  : indexPath;
        indexPath = (nextBit == (1 << 4)) ? streetIndexPath    : indexPath;
        indexPath = (nextBit == (1 << 5)) ? buildingIndexPath  : indexPath;
        indexPath = (nextBit == (1 << 6)) ? zipCodeIndexPath   : indexPath;
        indexPath = (nextBit == (1 << 7)) ? cityIndexPath      : indexPath;
        
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

    if (infoType == InfoTypeNone)
    {
        complete = ([name length] > 0);
    }
    else
    {
        if ([purchaseInfo[@"salutation"] isEqualToString:@"COMPANY"] == YES)
        {
            complete = ([name                            length] > 0 &&
                        [purchaseInfo[@"salutation"]     length] > 0 &&
                        [purchaseInfo[@"company"]        length] > 0 &&
                        [purchaseInfo[@"street"]         length] > 0 &&
                        [purchaseInfo[@"building"]       length] > 0 &&
                        [purchaseInfo[@"city"]           length] > 0 &&
                        [purchaseInfo[@"isoCountryCode"] length] > 0);
        }
        else
        {
            complete = ([name                            length] > 0 &&
                        [purchaseInfo[@"salutation"]     length] > 0 &&
                        [purchaseInfo[@"firstName"]      length] > 0 &&
                        [purchaseInfo[@"lastName"]       length] > 0 &&
                        [purchaseInfo[@"street"]         length] > 0 &&
                        [purchaseInfo[@"building"]       length] > 0 &&
                        [purchaseInfo[@"postcode"]        length] > 0 &&
                        [purchaseInfo[@"city"]           length] > 0 &&
                        [purchaseInfo[@"isoCountryCode"] length] > 0);
        }
    }

    return complete;
}


- (void)initializeIndexPaths
{
    nameIndexPath       = [NSIndexPath indexPathForRow:0 inSection:1];
    salutationIndexPath = [NSIndexPath indexPathForRow:0 inSection:2];
    companyIndexPath    = [NSIndexPath indexPathForRow:1 inSection:2];
    firstNameIndexPath  = [NSIndexPath indexPathForRow:2 inSection:2];
    lastNameIndexPath   = [NSIndexPath indexPathForRow:3 inSection:2];
    streetIndexPath     = [NSIndexPath indexPathForRow:0 inSection:3];
    buildingIndexPath   = [NSIndexPath indexPathForRow:1 inSection:3];
    zipCodeIndexPath    = [NSIndexPath indexPathForRow:2 inSection:3];
    cityIndexPath       = [NSIndexPath indexPathForRow:3 inSection:3];
    countryIndexPath    = [NSIndexPath indexPathForRow:4 inSection:3];
    actionIndexPath     = [NSIndexPath indexPathForRow:0 inSection:4];
}


- (NSString*)placeHolderForTextField:(UITextField*)textField
{
    NSString* placeHolder;

    // The default is "Required".
    if ([purchaseInfo[@"salutation"] isEqualToString:@"MR"] || [purchaseInfo[@"salutation"] isEqualToString:@"MS"])
    {
        if (textField == companyTextField)
        {
            placeHolder = [Strings optionalString];
        }
        else if (textField == firstNameTextField || textField == lastNameTextField)
        {
            placeHolder = [Strings requiredString];
        }
        else
        {
            placeHolder = [Strings requiredString];
        }
    }
    else if ([purchaseInfo[@"salutation"] isEqualToString:@"COMPANY"])
    {
        if (textField == companyTextField)
        {
            placeHolder = [Strings requiredString];
        }
        else if (textField == firstNameTextField || textField == lastNameTextField)
        {
            placeHolder = [Strings optionalString];
        }
        else
        {
            placeHolder = [Strings requiredString];
        }
    }
    else
    {
        placeHolder = [Strings requiredString];
    }

    return placeHolder;
}


- (IBAction)takePicture

{
    UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
    }

    imagePickerController.delegate      = self;
    imagePickerController.allowsEditing = YES;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}


- (NSString*)actionCellText
{
    NSString* text;

    if (requireProof == YES && purchaseInfo[@"proofImage"] == nil)
    {
        text = NSLocalizedStringWithDefaultValue(@"NumberArea:Action TakePictureLabel", nil,
                                                 [NSBundle mainBundle],
                                                 @"Take Picture",
                                                 @"....");
    }
    else if (infoType != InfoTypeNone && isChecked == NO)
    {
        text = NSLocalizedStringWithDefaultValue(@"NumberArea:Action ValidateLabel", nil,
                                                 [NSBundle mainBundle],
                                                 @"Validate",
                                                 @"....");
    }
    else
    {
        text = NSLocalizedStringWithDefaultValue(@"NumberArea:Action BuyLabel", nil,
                                                 [NSBundle mainBundle],
                                                 @"Buy",
                                                 @"....");
    }

    return text;
}


- (void)updateReturnKeyTypeOfTextField:(UITextField*)textField
{
    UIReturnKeyType returnKeyType = [self isPurchaseInfoComplete] ? UIReturnKeyDone : UIReturnKeyNext;

    if (textField.returnKeyType != returnKeyType)
    {
        textField.returnKeyType = returnKeyType;
        if ([textField isFirstResponder])
        {
            #warning The method reloadInputViews messes up two-byte keyboards (e.g. Kanji).
            [textField reloadInputViews];
        }
    }
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
        {
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Area SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Current Selection",
                                                      @"...");
            break;
        }
        case TableSectionName:
        {
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Naming SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Number's Name In App",
                                                      @"...");
            break;
        }
        case TableSectionContactName:
        {
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Name SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Contact Name",
                                                      @"Name and company of someone.");
            break;
        }
        case TableSectionContactAddress:
        {
            switch (infoType)
            {
                case InfoTypeNone:
                {
                    break;
                }
                case InfoTypeLocal:
                {
                    title = NSLocalizedStringWithDefaultValue(@"NumberArea:AddressLocal SectionHeader", nil,
                                                              [NSBundle mainBundle], @"Local Contact Address",
                                                              @"Address of someone.");
                    break;
                }
                case InfoTypeNational:
                {
                    title = NSLocalizedStringWithDefaultValue(@"NumberArea:AddressNational SectionHeader", nil,
                                                              [NSBundle mainBundle], @"National Contact Address",
                                                              @"Address of someone.");
                    break;
                }
                case InfoTypeWorldwide:
                {
                    title = NSLocalizedStringWithDefaultValue(@"NumberArea:AddressWorldwide SectionHeader", nil,
                                                              [NSBundle mainBundle], @"Worldwide Contact Address",
                                                              @"Address of someone.");
                    break;
                }
            }
            
            break;
        }
        case TableSectionAction:
        {
            break;
        }
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionArea:
        {
            break;
        }
        case TableSectionName:
        {
            title = [Strings nameFooterString];
            break;
        }
        case TableSectionContactName:
        {
            break;
        }
        case TableSectionContactAddress:
        {
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Address SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"For a phone number in this area, a contact name and address "
                                                      @"are (legally) required.",
                                                      @"Explaining that information must be supplied by user.");
            break;
        }
        case TableSectionAction:
        {
            if (requireProof == YES && purchaseInfo[@"proofImage"] == nil)
            {
                title = NSLocalizedStringWithDefaultValue(@"NumberArea:Action SectionFooterTakePicture", nil,
                                                          [NSBundle mainBundle],
                                                          @"For this area a proof of address is (legally) required.\n\n"
                                                          @"Take a picture of a recent utility bill, or bank statement. "
                                                          @"Make sure the date, your name & address, and the name of "
                                                          @"the company/bank are clearly visible.",
                                                          @"Telephone area (or city).");
            }
            else if (infoType != InfoTypeNone && isChecked == NO)
            {
                title = NSLocalizedStringWithDefaultValue(@"NumberArea:Action SectionFooterCheck", nil,
                                                          [NSBundle mainBundle],
                                                          @"The information supplied must first be checked.",
                                                          @"Telephone area (or city).");
            }
            else
            {
                title = NSLocalizedStringWithDefaultValue(@"NumberArea:Action SectionFooterBuy", nil,
                                                          [NSBundle mainBundle],
                                                          @"You can always buy extra months to use "
                                                          @"this phone number.",
                                                          @"Explaining that user can buy more months.");
            }
            
            break;
        }
    }

    return title;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionArea:
        {
            numberOfRows = [Common bitsSetCount:areaRows];
            break;
        }
        case TableSectionName:
        {
            numberOfRows = 1;
            break;
        }
        case TableSectionAddress:
        {
            numberOfRows = 1;
            break;
        }
        case TableSectionContactName:
        {
            numberOfRows = (infoType == InfoTypeNone) ? 0 : 4;
            break;
        }
        case TableSectionContactAddress:
        {
            numberOfRows = (infoType == InfoTypeNone) ? 0 : 5;
            break;
        }
        case TableSectionAction:
        {
            numberOfRows = 1;
            break;
        }
    }

    return numberOfRows;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberAreaPostcodesViewController*   zipsViewController;
    NumberAreaCitiesViewController* citiesViewController;
    NumberAreaTitlesViewController* titlesViewController;
    CountriesViewController*        countriesViewController;
    NSString*                       isoCountryCode;
    void (^completion)(BOOL cancelled, NSString* isoCountryCode);

    if ([self.tableView cellForRowAtIndexPath:indexPath].selectionStyle == UITableViewCellSelectionStyleNone)
    {
        return;
    }
    else
    {
        switch ([Common nthBitSet:indexPath.section inValue:sections])
        {
            case TableSectionContactName:
            {
                /*
                titlesViewController = [[NumberAreaTitlesViewController alloc] initWithPurchaseInfo:purchaseInfo];
                [self.navigationController pushViewController:titlesViewController animated:YES];
                break;
                 */
            }
            case TableSectionAddress:
            {
                AddressViewController* viewController;
                
                viewController = [[AddressViewController alloc] initWithAddress:nil
                                                           managedObjectContext:[DataManager sharedManager].managedObjectContext
                                                                 isoCountryCode:numberIsoCountryCode
                                                                           area:area
                                                                 numberTypeMask:numberTypeMask
                                                                      proofType:nil];
                
                [self.navigationController pushViewController:viewController animated:YES];
                break;
            }
            case TableSectionContactAddress:
            {
                /*
                switch (indexPath.row)
                {
                    case 2:
                    {
                        zipsViewController = [[NumberAreaPostcodesViewController alloc] initWithCitiesArray:citiesArray
                                                                                          purchaseInfo:purchaseInfo];
                        [self.navigationController pushViewController:zipsViewController animated:YES];
                        break;
                    }
                    case 3:
                    {
                        citiesViewController = [[NumberAreaCitiesViewController alloc] initWithCitiesArray:citiesArray
                                                                                              purchaseInfo:purchaseInfo];
                        [self.navigationController pushViewController:citiesViewController animated:YES];
                        break;
                    }
                    case 4:
                    {
                        isoCountryCode = purchaseInfo[@"isoCountryCode"];
                        completion = ^(BOOL cancelled, NSString* isoCountryCode)
                        {
                            if (cancelled == NO)
                            {
                                purchaseInfo[@"isoCountryCode"] = isoCountryCode;

                                // Update the cell.
                                UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
                                cell.textLabel.text   = nil;
                                countryTextField.text = [[CountryNames sharedNames] nameForIsoCountryCode:isoCountryCode];
                            }
                        };
                        
                        countriesViewController = [[CountriesViewController alloc] initWithIsoCountryCode:isoCountryCode
                                                                                                    title:[Strings countryString]
                                                                                               completion:completion];
                        [self.navigationController pushViewController:countriesViewController animated:YES];
                        break;
                    }
                }
                
                break;
                 */
            }
            case TableSectionAction:
            {
                if (requireProof == YES && purchaseInfo[@"proofImage"] == nil)
                {
                    [self takePicture];
                }
                else if ([self isPurchaseInfoComplete] == YES)
                {
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

                    if (infoType != InfoTypeNone && isChecked == NO)
                    {
                        NumberAreaActionCell* cell;
                        cell = (NumberAreaActionCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                        cell.userInteractionEnabled = NO;
                        cell.label.alpha = 0.5f;
                        [cell.activityIndicator startAnimating];

                        purchaseInfo[@"numberType"] = [NumberType localizedStringForNumberType:numberTypeMask];
                        purchaseInfo[@"areaCode"]   = area[@"areaCode"];
                        [[WebClient sharedClient] checkPurchaseInfo:purchaseInfo
                                                              reply:^(NSError* error, BOOL isValid)
                        {
                            NumberAreaActionCell* cell;
                            cell = (NumberAreaActionCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                            cell.userInteractionEnabled = YES;
                            cell.label.alpha = 1.0f;
                            [cell.activityIndicator stopAnimating];

                            if (error == nil)
                            {
                                NBLog(@"########################### do something with isValid");
                                isChecked = YES;
                                [self.tableView beginUpdates];
                                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                                              withRowAnimation:UITableViewRowAnimationFade];
                                [self.tableView endUpdates];
                            }
                            else if (error.code == NSURLErrorNotConnectedToInternet)
                            {
                                NSString* title;
                                NSString* message;

                                title   = NSLocalizedStringWithDefaultValue(@"NumberArea CouldNotValidateAlertTitle", nil,
                                                                            [NSBundle mainBundle], @"Could Not Validate",
                                                                            @"Alert title telling that there's a "
                                                                            @"problem with internet connection.\n"
                                                                            @"[iOS alert title size].");
                                message = NSLocalizedStringWithDefaultValue(@"NumberArea CouldNotValidateAlertMessage", nil,
                                                                            [NSBundle mainBundle],
                                                                            @"There seems to be a problem with the "
                                                                            @"internet connection.\n\nPlease try again "
                                                                            @"later.",
                                                                            @"Alert message telling that there's a "
                                                                            @"problem with internet connection.\n"
                                                                            @"[iOS alert message size]");
                                [BlockAlertView showAlertViewWithTitle:title
                                                               message:message
                                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                                 {
                                     [self dismissViewControllerAnimated:YES completion:nil];
                                 }
                                                     cancelButtonTitle:[Strings closeString]
                                                     otherButtonTitles:nil];
                            }
                            else //TODO Check with WebStatusFailInvalidInfo, check if server generates this.
                            {
                                NSString* title;
                                NSString* message;
                                NSString* description;

                                title   = NSLocalizedStringWithDefaultValue(@"NumberArea ValidationFailedAlertTitle", nil,
                                                                            [NSBundle mainBundle], @"Validation Failed",
                                                                            @"Alert title telling that validating "
                                                                            @"name & address of user failed.\n"
                                                                            @"[iOS alert title size].");
                                message = NSLocalizedStringWithDefaultValue(@"NumberArea ValidationFailedAlertMessage", nil,
                                                                            [NSBundle mainBundle],
                                                                            @"Validating your name and address failed: %@",
                                                                            @"Alert message telling that validating "
                                                                            @"name & address of user failed.\n"
                                                                            @"[iOS alert message size]");
                                description = error.localizedDescription;
                                message = [NSString stringWithFormat:message, description];
                                [BlockAlertView showAlertViewWithTitle:title
                                                               message:message
                                                            completion:nil
                                                     cancelButtonTitle:[Strings closeString]
                                                     otherButtonTitles:nil];
                            }
                        }];
                    }
                    else
                    {
                        BuyNumberViewController* viewController;
                        viewController = [[BuyNumberViewController alloc] initWithName:name
                                                                        isoCountryCode:numberIsoCountryCode
                                                                                  area:area
                                                                        numberTypeMask:numberTypeMask
                                                                                  info:purchaseInfo];
                        [self.navigationController pushViewController:viewController animated:YES];
                    }
                }
                else
                {
                    NSString*   title;
                    NSString*   message;

                    title   = NSLocalizedStringWithDefaultValue(@"NumberArea InfoIncompleteAlertTitle", nil,
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
                                         cancelButtonTitle:[Strings closeString]
                                         otherButtonTitles:nil];
                }
                
                break;
            }
        }
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionArea:
        {
            cell = [self areaCellForRowAtIndexPath:indexPath];
            break;
        }
        case TableSectionName:
        {
            cell = [self nameCellForRowAtIndexPath:indexPath];
            break;
        }
        case TableSectionAddress:
        {
            cell = [self addressCellForRowAtIndexPath:indexPath];
            break;
        }
        case TableSectionContactName:
        {
            cell = [self contactNameCellForRowAtIndexPath:indexPath];
            break;
        }
        case TableSectionContactAddress:
        {
            cell = [self contactAddressCellForRowAtIndexPath:indexPath];
            break;
        }
        case TableSectionAction:
        {
            cell = [self actionCellForRowAtIndexPath:indexPath];
            break;
        }
    }

    return cell;
}


#pragma mark - Cell Methods

- (UITableViewCell*)areaCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        identifier;

    identifier  = ([Common nthBitSet:indexPath.row inValue:areaRows] == AreaRowCountry) ? @"CountryCell"
                                                                                        : @"Value1Cell";
    cell        = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }

    switch ([Common nthBitSet:indexPath.row inValue:areaRows])
    {
        case AreaRowType:
        {
            cell.textLabel.text       = [Strings typeString];
            cell.detailTextLabel.text = [NumberType localizedStringForNumberType:numberTypeMask];
            cell.imageView.image      = nil;
            break;
        }
        case AreaRowAreaCode:
        {
            cell.textLabel.text       = [Strings areaCodeString];
            cell.detailTextLabel.text = area[@"areaCode"];
            cell.imageView.image      = nil;
            break;
        }
        case AreaRowAreaName:
        {
            cell.textLabel.text       = [Strings areaString];
            cell.detailTextLabel.text = [Common capitalizedString:area[@"areaName"]];
            cell.imageView.image      = nil;
            break;
        }
        case AreaRowState:
        {
            cell.textLabel.text       = [Strings stateString];
            cell.detailTextLabel.text = state[@"stateName"];
            cell.imageView.image      = nil;
            break;
        }
        case AreaRowCountry:
        {
            cell.textLabel.text       = @" ";     // Without this, the detailTextLabel is on the left.
            cell.detailTextLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:numberIsoCountryCode];
            [Common addCountryImageToCell:cell isoCountryCode:numberIsoCountryCode];
            break;
        }
    }

    cell.accessoryType  = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)nameCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    UITextField*     textField;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"TextFieldCell"];
        textField = [Common addTextFieldToCell:cell delegate:self];
        textField.tag = TextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
    }

    cell.textLabel.text              = [Strings nameString];
    textField.placeholder            = [Strings requiredString];
    textField.text                   = [name stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
    textField.userInteractionEnabled = YES;
    objc_setAssociatedObject(textField, @"TextFieldKey", @"name", OBJC_ASSOCIATION_RETAIN);

    cell.detailTextLabel.text = nil;
    cell.imageView.image      = nil;
    cell.accessoryType        = UITableViewCellAccessoryNone;
    cell.selectionStyle       = UITableViewCellSelectionStyleNone;

    [self updateTextField:textField onCell:cell];

    return cell;
}


- (UITableViewCell*)addressCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"AddressCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"AddressCell"];
    }
    
    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = NSLocalizedString(@"Address", @"Address cell title");

    return cell;
}


- (UITableViewCell*)contactNameCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    UITextField*        textField;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"TextFieldCell"];
        textField = [Common addTextFieldToCell:cell delegate:self];
        textField.tag = TextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
    }

    textField.userInteractionEnabled = YES;
    switch (indexPath.row)
    {
        case 0:
        {
            salutationTextField = textField;
            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = [Strings salutationString];
            
            textField.placeholder = [Strings requiredString];
            textField.text = [Strings localizedSalutation:purchaseInfo[@"salutation"]];
            textField.userInteractionEnabled = NO;
            objc_setAssociatedObject(textField, @"TextFieldKey", @"salutation", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 1:
        {
            companyTextField    = textField;
            cell.accessoryType  = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = [Strings companyString];

            textField.text = [purchaseInfo[@"company"] stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
            objc_setAssociatedObject(textField, @"TextFieldKey", @"company", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 2:
        {
            firstNameTextField  = textField;
            cell.accessoryType  = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = [Strings firstNameString];
            
            textField.text = [purchaseInfo[@"firstName"] stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
            objc_setAssociatedObject(textField, @"TextFieldKey", @"firstName", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 3:
        {
            lastNameTextField   = textField;
            cell.accessoryType  = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = [Strings lastNameString];
            
            textField.text = [purchaseInfo[@"lastName"] stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
            objc_setAssociatedObject(textField, @"TextFieldKey", @"lastName", OBJC_ASSOCIATION_RETAIN);
            break;
        }
    }

    textField.placeholder     = [self placeHolderForTextField:textField];

    [self updateTextField:textField onCell:cell];

    return cell;
}


- (UITableViewCell*)contactAddressCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    UITextField*     textField;
    BOOL             singleZipCode = NO;
    BOOL             singleCity    = NO;
    NSString*        identifier;

    switch (indexPath.row)
    {
        case 1:  identifier = @"BuildingCell";         break;
        case 2:  identifier = @"ZipCodeCell";          break;
        case 4:  identifier = @"CountryTextFieldCell"; break;
        default: identifier = @"TextFieldCell";        break;
    }

    if (citiesArray.count == 1)
    {
        singleCity = YES;
        purchaseInfo[@"city"] = citiesArray[0][@"city"];

        NSArray*    zipCodes = citiesArray[0][@"postcodes"];
        if ([zipCodes count] == 1)
        {
            singleZipCode = YES;
            purchaseInfo[@"postcode"] = citiesArray[0][@"postcodes"][0];
        }
    }

    cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        cell.accessoryType  = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        textField = [Common addTextFieldToCell:cell delegate:self];
        textField.tag = TextFieldCellTag;
    }
    else
    {
        cell.accessoryType  = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        textField = (UITextField*)[cell.contentView viewWithTag:TextFieldCellTag];
    }

    textField.userInteractionEnabled = YES;
    switch (indexPath.row)
    {
        case 0:
        {
            cell.textLabel.text = [Strings streetString];
            textField.placeholder = [Strings requiredString];
            textField.text = [purchaseInfo[@"street"] stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
            objc_setAssociatedObject(textField, @"TextFieldKey", @"street", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 1:
        {
           // cell.textLabel.text = [Strings buildingString];
            textField.placeholder = [Strings requiredString];
            textField.text = [purchaseInfo[@"building"] stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
            textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            objc_setAssociatedObject(textField, @"TextFieldKey", @"building", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 2:
        {
            cell.textLabel.text = [Strings postcodeString];
            if (citiesArray.count == 0)
            {
                textField.placeholder  = [Strings requiredString];
                textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            }
            else
            {
                if (singleZipCode == NO)
                {
                    textField.placeholder = [Strings requiredString];
                    cell.accessoryType    = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle   = UITableViewCellSelectionStyleDefault;
                    textField.text        = nil;
                }
                
                textField.userInteractionEnabled = NO;
            }
            
            zipCodeTextField = textField;
            zipCodeTextField.text = [purchaseInfo[@"postcode"] stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
            objc_setAssociatedObject(zipCodeTextField, @"TextFieldKey", @"postcode", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 3:
        {
            cell.textLabel.text = [Strings cityString];
            if (citiesArray.count == 0)
            {
                textField.placeholder = [Strings requiredString];
            }
            else
            {
                if (singleCity == NO)
                {
                    textField.placeholder = [Strings requiredString];
                    textField.text        = nil;
                    cell.accessoryType    = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle   = UITableViewCellSelectionStyleDefault;
                    textField.text        = nil;
                }

                textField.userInteractionEnabled = NO;
            }
            
            cityTextField = textField;
            cityTextField.text = [Common capitalizedString:purchaseInfo[@"city"]];
            [cityTextField.text stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
            objc_setAssociatedObject(cityTextField, @"TextFieldKey", @"city", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 4:
        {
            textField.placeholder            = [Strings requiredString];
            textField.userInteractionEnabled = NO;

            if (infoType == InfoTypeLocal || infoType == InfoTypeNational)
            {
                cell.accessoryType  = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            else
            {
                cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            }

            countryTextField    = textField;
            cell.textLabel.text = [Strings countryString];
            if (purchaseInfo[@"isoCountryCode"] == nil)
            {
                countryTextField.text = nil;
            }
            else
            {
                countryTextField.text = [[CountryNames sharedNames] nameForIsoCountryCode:purchaseInfo[@"isoCountryCode"]];
            }
            
            break;
        }
    }

    [self updateTextField:textField onCell:cell];

    return cell;
}


- (UITableViewCell*)actionCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberAreaActionCell*   cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumberAreaActionCell"];
    if (cell == nil)
    {
        cell = [[NumberAreaActionCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:@"NumberAreaActionCell"];
    }

    cell.label.text      = [self actionCellText];
    cell.label.textColor = [Skinning tintColor];

    actionIndexPath = indexPath;

    return cell;
}


- (void)updateTextField:(UITextField*)textField onCell:(UITableViewCell*)cell
{
    cell.detailTextLabel.text = nil;
    cell.imageView.image      = nil;

    if (cell.accessoryType == UITableViewCellAccessoryDisclosureIndicator)
    {
        [Common setX:60 ofView:textField];
        textField.textColor = [UIColor grayColor];
    }
    else
    {
        [Common setX:80 ofView:textField];
        if (textField.userInteractionEnabled == YES)
        {
            textField.textColor = [Skinning tintColor];
        }
        else
        {
            textField.textColor = [UIColor grayColor];
        }
    }
}


#pragma mark - TextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
    if (self.isLoading == YES)
    {
        return NO;
    }
    else
    {
        [self updateReturnKeyTypeOfTextField:textField];

        activeCellIndexPath = [self findCellIndexPathForSubview:textField];

        return YES;
    }
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


// Not used at the moment, because there are no clear buttons.
- (BOOL)textFieldShouldClear:(UITextField*)textField
{
    NSString* key = objc_getAssociatedObject(textField, @"TextFieldKey");
    
    if ([key isEqualToString:@"name"])
    {
        name = @"";
    }
    else
    {
        purchaseInfo[key] = @"";
    }

    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if ([self isPurchaseInfoComplete] == YES)
    {
        [textField resignFirstResponder];

        return YES;
    }
    else
    {
        NSString* key = objc_getAssociatedObject(textField, @"TextFieldKey");
        nextIndexPath = [self nextEmptyIndexPathForKey:key];

        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:nextIndexPath];

        if (cell != nil)
        {
            UITextField* nextTextField;

            nextTextField = (UITextField*)[cell.contentView viewWithTag:TextFieldCellTag];
            [nextTextField becomeFirstResponder];
        }

        return NO;
    }
}


- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    NSString* key = objc_getAssociatedObject(textField, @"TextFieldKey");

    // See http://stackoverflow.com/a/22211018/1971013 why we're using non-breaking spaces @"\u00a0".
    textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    textField.text = [textField.text stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];

    if ([key isEqualToString:@"name"])
    {
        name = [textField.text stringByReplacingOccurrencesOfString:@"\u00a0" withString:@" "];
    }
    else
    {
        purchaseInfo[key] = [textField.text stringByReplacingOccurrencesOfString:@"\u00a0" withString:@" "];
    }

    [self updateReturnKeyTypeOfTextField:textField];

    [self.tableView scrollToRowAtIndexPath:activeCellIndexPath
                          atScrollPosition:UITableViewScrollPositionNone
                                  animated:YES];

    return NO;  // Need to return NO, because we've already changed textField.text.
}


#pragma mark - Scrollview Delegate

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView
{
    if (nextIndexPath != nil)
    {
        UITextField*     nextTextField;
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:nextIndexPath];
        nextIndexPath = nil;
        
        nextTextField = (UITextField*)[cell.contentView viewWithTag:TextFieldCellTag];
        [nextTextField becomeFirstResponder];
    }
}


#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch
{
    if ([touch.view isKindOfClass:[UITextField class]] || [touch.view isKindOfClass:[UIButton class]])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}


#pragma mark - Image Picker Delegate

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    UIImage* image = [info objectForKey:UIImagePickerControllerEditedImage];
    NSData*  data  = UIImageJPEGRepresentation(image, 0.5);

    purchaseInfo[@"proofImage"] = [Base64 encode:data];

    //### When not reloading here, the new footer text will be way too low (iOS 7.0.6).
    [self.tableView reloadData];

    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
