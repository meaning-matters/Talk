//
//  AddressViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 16/11/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import <objc/runtime.h>
#import "AddressViewController.h"
#import "NumberAreaPostcodesViewController.h"
#import "NumberAreaCitiesViewController.h"
#import "NumberAreaTitlesViewController.h"
#import "CountriesViewController.h"
#import "Strings.h"
#import "Common.h"
#import "CountryNames.h"
#import "NumberAreaActionCell.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Base64.h"
#import "DataManager.h"
#import "BlockActionSheet.h"

typedef NS_ENUM(NSUInteger, TableSections)
{
    TableSectionName    = 1UL << 0, // Name given by user.
    TableSectionDetails = 1UL << 1, // Salutation, company, first, last.
    TableSectionAddress = 1UL << 2, // Street, number, city, postcode.
    TableSectionProof   = 1UL << 3, // Proof image.
};


@interface AddressViewController () <UIImagePickerControllerDelegate>

@property (nonatomic, assign) TableSections               sections;
@property (nonatomic, assign) BOOL                        isNew;
@property (nonatomic, assign) BOOL                        isDeleting;

@property (nonatomic, strong) NSFetchedResultsController* fetchedAddressesController;
@property (nonatomic, strong) NSString*                   numberIsoCountryCode;
@property (nonatomic, strong) NSString*                   areaCode;
@property (nonatomic, assign) NumberTypeMask              numberTypeMask;
@property (nonatomic, strong) NSString*                   addressType;
@property (nonatomic, strong) NSDictionary*               proofType;

@property (nonatomic, strong) NSArray*                    citiesArray;
@property (nonatomic, assign) BOOL                        isChecked;

@property (nonatomic, strong) UITextField*                salutationTextField;
@property (nonatomic, strong) UITextField*                companyNameTextField;
@property (nonatomic, strong) UITextField*                firstNameTextField;
@property (nonatomic, strong) UITextField*                lastNameTextField;
@property (nonatomic, strong) UITextField*                cityTextField;
@property (nonatomic, strong) UITextField*                postcodeTextField;
@property (nonatomic, strong) UITextField*                countryTextField;

@property (nonatomic, strong) NSIndexPath*                salutationIndexPath;
@property (nonatomic, strong) NSIndexPath*                companyNameIndexPath;
@property (nonatomic, strong) NSIndexPath*                firstNameIndexPath;
@property (nonatomic, strong) NSIndexPath*                lastNameIndexPath;
@property (nonatomic, strong) NSIndexPath*                streetIndexPath;
@property (nonatomic, strong) NSIndexPath*                buildingNumberIndexPath;
@property (nonatomic, strong) NSIndexPath*                buildingLetterIndexPath;
@property (nonatomic, strong) NSIndexPath*                cityIndexPath;
@property (nonatomic, strong) NSIndexPath*                postcodeIndexPath;
@property (nonatomic, strong) NSIndexPath*                countryIndexPath;
@property (nonatomic, strong) NSIndexPath*                actionIndexPath;

@property (nonatomic, strong) NSIndexPath*                nextIndexPath;      // Index-path of cell to show after Next button is tapped.

// Keyboard stuff.
@property (nonatomic, assign) BOOL                        keyboardShown;
@property (nonatomic, assign) CGFloat                     keyboardOverlap;
@property (nonatomic, strong) NSIndexPath*                activeCellIndexPath;

@property (nonatomic, assign) BOOL                        isLoading;
@property (nonatomic, strong) UIActivityIndicatorView*    activityIndicator;

@end


@implementation AddressViewController

- (instancetype)initWithAddress:(AddressData*)address
           managedObjectContext:(NSManagedObjectContext*)managedObjectContext
                 isoCountryCode:(NSString*)isoCountryCode
                       areaCode:(NSString*)areaCode
                 numberTypeMask:(NumberTypeMask)numberTypeMask
                    addressType:(NSString*)addressType
                      proofType:(NSDictionary*)proofType
{
    if (self = [super initWithManagedObjectContext:managedObjectContext])
    {
        self.sections             = TableSectionName | TableSectionDetails | TableSectionAddress;
        self.isNew                = (address == nil);
        self.address              = address;
        self.title                = self.isNew ? [Strings newAddressString] : [Strings addressString];

        self.numberIsoCountryCode = isoCountryCode;
        self.areaCode             = areaCode;
        self.numberTypeMask       = numberTypeMask;
        self.addressType          = addressType;
        self.proofType            = proofType;
        
        if (self.isNew == YES)
        {
            // Create a new managed object context; set its parent to the fetched results controller's context.
            NSManagedObjectContext* managedObjectContext;
            managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [managedObjectContext setParentContext:self.managedObjectContext];
            self.managedObjectContext = managedObjectContext;
            
            self.address = [NSEntityDescription insertNewObjectForEntityForName:@"Address"
                                                         inManagedObjectContext:self.managedObjectContext];
            self.address.salutation = @"MR";
        }
        else
        {
            self.managedObjectContext = managedObjectContext;
        }
        
        if ([self.addressType isEqualToString:@"LOCAL"] || [self.addressType isEqualToString:@"NATIONAL"])
        {
            self.address.isoCountryCode = self.numberIsoCountryCode;
        }
        
        // Mandatory sections.
        self.sections |= TableSectionName;
        self.sections |= TableSectionDetails;
        self.sections |= TableSectionAddress;
        self.sections |= TableSectionProof;
        
        [self initializeIndexPaths];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;
    
    UIBarButtonItem* buttonItem;
    if (self.isNew)
    {
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancelAction)];
        self.navigationItem.leftBarButtonItem = buttonItem;

        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                   target:self
                                                                   action:@selector(createAction)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }
    else
    {
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                   target:self
                                                                   action:@selector(deleteAction)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }
    
    [self updateRightBarButtonItem];
    
    if (self.isNew)
    {
        [self loadData];
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"NumberAreaActionCell" bundle:nil]
         forCellReuseIdentifier:@"NumberAreaActionCell"];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.salutationTextField.text = [Strings localizedSalutation:self.address.salutation];
    self.postcodeTextField.text   = self.address.postcode;
    self.cityTextField.text       = self.address.city;
    
    self.companyNameTextField.placeholder = [self placeHolderForTextField:self.companyNameTextField];
    self.firstNameTextField.placeholder   = [self placeHolderForTextField:self.firstNameTextField];
    self.lastNameTextField.placeholder    = [self placeHolderForTextField:self.lastNameTextField];
    
    NumberAreaActionCell* cell = (NumberAreaActionCell*)[self.tableView cellForRowAtIndexPath:self.actionIndexPath];
    cell.label.text            = [self actionCellText];
    
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[WebClient sharedClient] cancelAllRetrieveAreaInfoForIsoCountryCode:self.numberIsoCountryCode
                                                                areaCode:self.areaCode];
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


#pragma mark - Helpers

- (void)updateRightBarButtonItem
{
    if (self.isNew == YES)
    {
        BOOL valid = [self.name stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0;
        
        self.navigationItem.rightBarButtonItem.enabled = valid;
    }
}


- (void)hideKeyboard:(UIGestureRecognizer*)gestureRecognizer
{
    [[self.tableView superview] endEditing:YES];
}


- (void)loadData
{
    self.isLoading = YES;
    [[WebClient sharedClient] retrieveNumberAreaInfoForIsoCountryCode:self.numberIsoCountryCode
                                                             areaCode:self.areaCode
                                                                reply:^(NSError* error, id content)
    {
        if (error == nil)
        {
            self.citiesArray = [NSArray arrayWithArray:content];
            self.address.postcode = @"";     // Resets what user may have typed while loading (on slow internet).
            self.address.city     = @"";     // Resets what user may have typed while loading (on slow internet).
            
            [self.tableView reloadData];
            self.isLoading = NO;    // Placed here, after processing results, to let reload of search results work.
        }
        else if (error.code == WebStatusFailServiceUnavailable)
        {
            NSString* title;
            NSString* message;
            
            title   = NSLocalizedStringWithDefaultValue(@"Address UnavailableAlertTitle", nil,
                                                        [NSBundle mainBundle], @"Service Unavailable",
                                                        @"Alert title telling that an online service is not available.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"Address UnavailableAlertMessage", nil,
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
            
            title   = NSLocalizedStringWithDefaultValue(@"Address LoadFailAlertTitle", nil,
                                                        [NSBundle mainBundle], @"Loading Failed",
                                                        @"Alert title telling that loading information over internet failed.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"Address LoadFailAlertMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Loading the list of cities and postcodes failed: %@\n\nPlease try again later.",
                                                        @"Alert message telling that loading information over internet failed.\n"
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


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (NSIndexPath*)nextEmptyIndexPathForKey:(NSString*)currentKey
{
    unsigned emptyMask  = 0;
    unsigned currentBit = 0;
    
    if (self.isNew == YES)
    {
        emptyMask |= ([self.name                   length] == 0) << 0;
        emptyMask |= ([self.address.companyName    length] == 0) << 1;
        emptyMask |= ([self.address.firstName      length] == 0) << 2;
        emptyMask |= ([self.address.lastName       length] == 0) << 3;
        emptyMask |= ([self.address.street         length] == 0) << 4;
        emptyMask |= ([self.address.buildingNumber length] == 0) << 5;
        emptyMask |= ([self.address.buildingLetter length] == 0) << 6;
        if (self.citiesArray.count == 0)
        {
            emptyMask |= ([self.address.city       length] == 0) << 7;
            emptyMask |= ([self.address.postcode   length] == 0) << 8;
        }
    }
    else
    {
        emptyMask |= ([self.name length] == 0) << 0;
    }
    
    if (emptyMask != 0)
    {
        currentBit |= [currentKey isEqualToString:@"name"]           << 0;
        currentBit |= [currentKey isEqualToString:@"companyName"]    << 1;
        currentBit |= [currentKey isEqualToString:@"firstName"]      << 2;
        currentBit |= [currentKey isEqualToString:@"lastName"]       << 3;
        currentBit |= [currentKey isEqualToString:@"street"]         << 4;
        currentBit |= [currentKey isEqualToString:@"buildingNumber"] << 5;
        currentBit |= [currentKey isEqualToString:@"buildingLetter"] << 6;
        currentBit |= [currentKey isEqualToString:@"city"]           << 7;
        currentBit |= [currentKey isEqualToString:@"postcode"]       << 8;
        
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
        indexPath = (nextBit == (1 << 0)) ? self.nameIndexPath           : indexPath;
        indexPath = (nextBit == (1 << 1)) ? self.companyNameIndexPath    : indexPath;
        indexPath = (nextBit == (1 << 2)) ? self.firstNameIndexPath      : indexPath;
        indexPath = (nextBit == (1 << 3)) ? self.lastNameIndexPath       : indexPath;
        indexPath = (nextBit == (1 << 4)) ? self.streetIndexPath         : indexPath;
        indexPath = (nextBit == (1 << 5)) ? self.buildingNumberIndexPath : indexPath;
        indexPath = (nextBit == (1 << 6)) ? self.buildingLetterIndexPath : indexPath;
        indexPath = (nextBit == (1 << 7)) ? self.cityIndexPath           : indexPath;
        indexPath = (nextBit == (1 << 8)) ? self.postcodeIndexPath       : indexPath;
        
        return indexPath;
    }
    else
    {
        return nil;
    }
}


- (BOOL)isAddressComplete
{
    BOOL    complete;
    
    if (self.isNew == YES)
    {
        if ([self.address.salutation isEqualToString:@"COMPANY"] == YES)
        {
            complete = ([self.name                   length] > 0 &&
                        [self.address.salutation     length] > 0 &&
                        [self.address.companyName    length] > 0 &&
                        [self.address.street         length] > 0 &&
                        [self.address.buildingNumber length] > 0 &&
                        [self.address.city           length] > 0 &&
                        [self.address.postcode       length] > 0 &&
                        [self.address.isoCountryCode length] > 0);
        }
        else
        {
            complete = ([self.name                   length] > 0 &&
                        [self.address.salutation     length] > 0 &&
                        [self.address.firstName      length] > 0 &&
                        [self.address.lastName       length] > 0 &&
                        [self.address.street         length] > 0 &&
                        [self.address.buildingNumber length] > 0 &&
                        [self.address.city           length] > 0 &&
                        [self.address.postcode       length] > 0 &&
                        [self.address.isoCountryCode length] > 0);
        }
    }
    else
    {
        complete = ([self.name length] > 0);
    }
    
    return complete;
}


- (void)initializeIndexPaths
{
    self.nameIndexPath           = [NSIndexPath indexPathForRow:0 inSection:0];
    self.salutationIndexPath     = [NSIndexPath indexPathForRow:0 inSection:1];
    self.companyNameIndexPath    = [NSIndexPath indexPathForRow:1 inSection:1];
    self.firstNameIndexPath      = [NSIndexPath indexPathForRow:2 inSection:1];
    self.lastNameIndexPath       = [NSIndexPath indexPathForRow:3 inSection:1];
    self.streetIndexPath         = [NSIndexPath indexPathForRow:0 inSection:2];
    self.buildingNumberIndexPath = [NSIndexPath indexPathForRow:1 inSection:2];
    self.buildingLetterIndexPath = [NSIndexPath indexPathForRow:2 inSection:2];
    self.cityIndexPath           = [NSIndexPath indexPathForRow:3 inSection:2];
    self.postcodeIndexPath       = [NSIndexPath indexPathForRow:4 inSection:2];
    self.countryIndexPath        = [NSIndexPath indexPathForRow:5 inSection:2];
    self.actionIndexPath         = [NSIndexPath indexPathForRow:0 inSection:3];
}


- (NSString*)placeHolderForTextField:(UITextField*)textField
{
    NSString* placeHolder;
    
    // The default is "Required".
    if ([self.address.salutation isEqualToString:@"MR"] || [self.address.salutation isEqualToString:@"MS"])
    {
        if (textField == self.companyNameTextField)
        {
            placeHolder = [Strings optionalString];
        }
        else if (textField == self.firstNameTextField || textField == self.lastNameTextField)
        {
            placeHolder = [Strings requiredString];
        }
        else
        {
            placeHolder = [Strings requiredString];
        }
    }
    else if ([self.address.salutation isEqualToString:@"COMPANY"])
    {
        if (textField == self.companyNameTextField)
        {
            placeHolder = [Strings requiredString];
        }
        else if (textField == self.firstNameTextField || textField == self.lastNameTextField)
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
    
    if (self.proofType != nil && self.address.proofImage == nil)
    {
        text = NSLocalizedStringWithDefaultValue(@"Address:Action TakePictureLabel", nil,
                                                 [NSBundle mainBundle],
                                                 @"Take Picture",
                                                 @"....");
    }
    else if (self.isChecked == NO)
    {
        text = NSLocalizedStringWithDefaultValue(@"Address:Action ValidateLabel", nil,
                                                 [NSBundle mainBundle],
                                                 @"Validate",
                                                 @"....");
    }
    else
    {
        text = NSLocalizedStringWithDefaultValue(@"Address:Action BuyLabel", nil,
                                                 [NSBundle mainBundle],
                                                 @"Buy",
                                                 @"....");
    }
    
    return text;
}


- (void)updateReturnKeyTypeOfTextField:(UITextField*)textField
{
    UIReturnKeyType returnKeyType = [self isAddressComplete] ? UIReturnKeyDone : UIReturnKeyNext;
    
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
    return [Common bitsSetCount:self.sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionName:
        {
            numberOfRows = 1;
            break;
        }
        case TableSectionDetails:
        {
            numberOfRows = 4;
            break;
        }
        case TableSectionAddress:
        {
            numberOfRows = 6;
            break;
        }
        case TableSectionProof:
        {
            numberOfRows = 1;
            break;
        }
    }
    
    return numberOfRows;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;
    
    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionName:
        {
            title = NSLocalizedStringWithDefaultValue(@"Address:Naming SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Address' Name In App",
                                                      @"...");
            break;
        }
        case TableSectionDetails:
        {
            title = NSLocalizedStringWithDefaultValue(@"Address:Name SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Contact Name",
                                                      @"Name and company of someone.");
            break;
        }
        case TableSectionAddress:
        {
            if ([self.addressType isEqualToString:@"LOCAL"])
            {
                title = NSLocalizedStringWithDefaultValue(@"Address:AddressLocal SectionHeader", nil,
                                                          [NSBundle mainBundle], @"Local Contact Address",
                                                          @"Address of someone.");
            }
            
            if ([self.addressType isEqualToString:@"NATIONAL"])
            {
                title = NSLocalizedStringWithDefaultValue(@"Address:AddressNational SectionHeader", nil,
                                                          [NSBundle mainBundle], @"National Contact Address",
                                                          @"Address of someone.");
            }
            
            if ([self.addressType isEqualToString:@"WORLDWIDE"])
            {
                title = NSLocalizedStringWithDefaultValue(@"Address:AddressWorldwide SectionHeader", nil,
                                                          [NSBundle mainBundle], @"Worldwide Contact Address",
                                                          @"Address of someone.");
            }
            
            break;
        }
        case TableSectionProof:
        {
            break;
        }
    }
    
    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title = nil;
    
    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionName:
        {
            title = [Strings nameFooterString];
            break;
        }
        case TableSectionDetails:
        {
            break;
        }
        case TableSectionAddress:
        {
            title = NSLocalizedStringWithDefaultValue(@"Address:Address SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"For a phone number in this area, a contact name and address "
                                                      @"are (legally) required.",
                                                      @"Explaining that information must be supplied by user.");
            break;
        }
        case TableSectionProof:
        {
            if (self.proofType != nil && self.address.proofImage == nil)
            {
                title = NSLocalizedStringWithDefaultValue(@"Address:Action SectionFooterTakePicture", nil,
                                                          [NSBundle mainBundle],
                                                          @"For this area a proof of address is (legally) required.\n\n"
                                                          @"Take a picture of a recent utility bill, or bank statement. "
                                                          @"Make sure the date, your name & address, and the name of "
                                                          @"the company/bank are clearly visible.",
                                                          @"Telephone area (or city).");
            }
            else if (self.isChecked == NO)
            {
                title = NSLocalizedStringWithDefaultValue(@"Address:Action SectionFooterCheck", nil,
                                                          [NSBundle mainBundle],
                                                          @"The information supplied must first be checked.",
                                                          @"Telephone area (or city).");
            }
            else
            {
                title = NSLocalizedStringWithDefaultValue(@"Address:Action SectionFooterBuy", nil,
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
        switch ([Common nthBitSet:indexPath.section inValue:self.sections])
        {
            case TableSectionDetails:
            {
                titlesViewController = [[NumberAreaTitlesViewController alloc] initWithAddress:self.address];
                [self.navigationController pushViewController:titlesViewController animated:YES];
                break;
            }
            case TableSectionAddress:
            {
                switch (indexPath.row)
                {
                    case 2:
                    {
                        zipsViewController = [[NumberAreaPostcodesViewController alloc] initWithCitiesArray:self.citiesArray
                                                                                               address:self.address];
                        [self.navigationController pushViewController:zipsViewController animated:YES];
                        break;
                    }
                    case 3:
                    {
                        citiesViewController = [[NumberAreaCitiesViewController alloc] initWithCitiesArray:self.citiesArray
                                                                                                   address:self.address];
                        [self.navigationController pushViewController:citiesViewController animated:YES];
                        break;
                    }
                    case 4:
                    {
                        isoCountryCode = self.address.isoCountryCode;
                        completion = ^(BOOL cancelled, NSString* isoCountryCode)
                        {
                            if (cancelled == NO)
                            {
                                self.address.isoCountryCode = isoCountryCode;
                                
                                // Update the cell.
                                UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
                                cell.textLabel.text   = nil;
                                self.countryTextField.text = [[CountryNames sharedNames] nameForIsoCountryCode:isoCountryCode];
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
            }
            case TableSectionProof:
            {
                if (self.proofType != nil && self.address.proofImage == nil)
                {
                    [self takePicture];
                }
                else if ([self isAddressComplete] == YES)
                {
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                    
                    if (self.isChecked == NO)
                    {
                        NumberAreaActionCell* cell;
                        cell = (NumberAreaActionCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                        cell.userInteractionEnabled = NO;
                        cell.label.alpha = 0.5f;
                        [cell.activityIndicator startAnimating];
                        
                        
                        [self createAction];
                        
                        /*
                        
                        self.address.numberType = [NumberType localizedStringForNumberType:self.numberTypeMask];
                        self.address.areaCode   = self.area[@"areaCode"];
                        [[WebClient sharedClient] checkPurchaseInfo:self.purchaseInfo
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
                                self.isChecked = YES;
                                [self.tableView beginUpdates];
                                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                                              withRowAnimation:UITableViewRowAnimationFade];
                                [self.tableView endUpdates];
                            }
                            else if (error.code == NSURLErrorNotConnectedToInternet)
                            {
                                NSString* title;
                                NSString* message;
                                
                                title   = NSLocalizedStringWithDefaultValue(@"Address CouldNotValidateAlertTitle", nil,
                                                                            [NSBundle mainBundle], @"Could Not Validate",
                                                                            @"Alert title telling that there's a "
                                                                            @"problem with internet connection.\n"
                                                                            @"[iOS alert title size].");
                                message = NSLocalizedStringWithDefaultValue(@"Address CouldNotValidateAlertMessage", nil,
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
                                
                                title   = NSLocalizedStringWithDefaultValue(@"Address ValidationFailedAlertTitle", nil,
                                                                            [NSBundle mainBundle], @"Validation Failed",
                                                                            @"Alert title telling that validating "
                                                                            @"name & address of user failed.\n"
                                                                            @"[iOS alert title size].");
                                message = NSLocalizedStringWithDefaultValue(@"Address ValidationFailedAlertMessage", nil,
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
                         
                         */
                    }
                    else
                    {
                        NSLog(@"###########################");
                        /*
                         BuyNumberViewController* viewController;
                         viewController = [[BuyNumberViewController alloc] initWithName:name
                         isoCountryCode:numberIsoCountryCode
                         area:area
                         numberTypeMask:numberTypeMask
                         info:purchaseInfo];
                         [self.navigationController pushViewController:viewController animated:YES];
                         */
                    }
                }
                else
                {
                    NSString*   title;
                    NSString*   message;
                    
                    title   = NSLocalizedStringWithDefaultValue(@"Address InfoIncompleteAlertTitle", nil,
                                                                [NSBundle mainBundle], @"Information Missing",
                                                                @"Alert title telling that user did not fill in all information.\n"
                                                                @"[iOS alert title size].");
                    message = NSLocalizedStringWithDefaultValue(@"Address LoadFailAlertMessage", nil,
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
    UITableViewCell* cell;
    
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionName:
        {
            cell = [self nameCellForRowAtIndexPath:indexPath];
            break;
        }
        case TableSectionDetails:
        {
            cell = [self contactNameCellForRowAtIndexPath:indexPath];
            break;
        }
        case TableSectionAddress:
        {
            cell = [self contactAddressCellForRowAtIndexPath:indexPath];
            break;
        }
        case TableSectionProof:
        {
            cell = [self actionCellForRowAtIndexPath:indexPath];
            break;
        }
    }
    
    return cell;
}


#pragma mark - Cell Methods

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
    textField.text                   = [self.name stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
    textField.userInteractionEnabled = YES;
    objc_setAssociatedObject(textField, @"TextFieldKey", @"name", OBJC_ASSOCIATION_RETAIN);
    
    cell.detailTextLabel.text = nil;
    cell.imageView.image      = nil;
    cell.accessoryType        = UITableViewCellAccessoryNone;
    cell.selectionStyle       = UITableViewCellSelectionStyleNone;
    
    [self updateTextField:textField onCell:cell];
    
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
            self.salutationTextField = textField;
            cell.accessoryType       = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle      = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text      = [Strings salutationString];
            
            textField.placeholder = [Strings requiredString];
            textField.text = [Strings localizedSalutation:self.address.salutation];
            textField.userInteractionEnabled = NO;
            objc_setAssociatedObject(textField, @"TextFieldKey", @"salutation", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 1:
        {
            self.companyNameTextField = textField;
            cell.accessoryType    = UITableViewCellAccessoryNone;
            cell.selectionStyle   = UITableViewCellSelectionStyleNone;
            cell.textLabel.text   = [Strings companyString];
            
            textField.text = [self.address.companyName stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
            objc_setAssociatedObject(textField, @"TextFieldKey", @"companyName", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 2:
        {
            self.firstNameTextField = textField;
            cell.accessoryType      = UITableViewCellAccessoryNone;
            cell.selectionStyle     = UITableViewCellSelectionStyleNone;
            cell.textLabel.text     = [Strings firstNameString];
            
            textField.text = [self.address.firstName stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
            objc_setAssociatedObject(textField, @"TextFieldKey", @"firstName", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 3:
        {
            self.lastNameTextField = textField;
            cell.accessoryType     = UITableViewCellAccessoryNone;
            cell.selectionStyle    = UITableViewCellSelectionStyleNone;
            cell.textLabel.text    = [Strings lastNameString];
            
            textField.text = [self.address.lastName stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
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
    BOOL             singlePostcode = NO;
    BOOL             singleCity     = NO;
    NSString*        identifier;
    
    switch (indexPath.row)
    {
        case 1:  identifier = @"BuildingCell";         break;
        case 2:  identifier = @"PostcodeCell";         break;
        case 4:  identifier = @"CountryTextFieldCell"; break;
        default: identifier = @"TextFieldCell";        break;
    }
    
    if (self.citiesArray.count == 1)
    {
        singleCity = YES;
        self.address.city = self.citiesArray[0][@"city"];
        
        NSArray*    postcodes = self.citiesArray[0][@"postcodes"];
        if ([postcodes count] == 1)
        {
            singlePostcode = YES;
            self.address.postcode = self.citiesArray[0][@"postcodes"][0];
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
            textField.text = [self.address.street stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
            objc_setAssociatedObject(textField, @"TextFieldKey", @"street", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 1:
        {
            cell.textLabel.text = [Strings buildingNumberString];
            textField.placeholder = [Strings requiredString];
            textField.text = [self.address.buildingNumber stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
            textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            objc_setAssociatedObject(textField, @"TextFieldKey", @"buildingNumber", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 2:
        {
            cell.textLabel.text = [Strings buildingLetterString];
            textField.placeholder = [Strings optionalString];
            textField.text = [self.address.buildingLetter stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
            textField.keyboardType = UIKeyboardTypeAlphabet;
            textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            objc_setAssociatedObject(textField, @"TextFieldKey", @"buildingLetter", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 3:
        {
            cell.textLabel.text = [Strings cityString];
            if (self.citiesArray.count == 0)
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
            
            self.cityTextField = textField;
            self.cityTextField.text = [Common capitalizedString:self.address.city];
            [self.cityTextField.text stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
            objc_setAssociatedObject(self.cityTextField, @"TextFieldKey", @"city", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 4:
        {
            cell.textLabel.text = [Strings postcodeString];
            if (self.citiesArray.count == 0)
            {
                textField.placeholder  = [Strings requiredString];
                textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            }
            else
            {
                if (singlePostcode == NO)
                {
                    textField.placeholder = [Strings requiredString];
                    cell.accessoryType    = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle   = UITableViewCellSelectionStyleDefault;
                    textField.text        = nil;
                }
                
                textField.userInteractionEnabled = NO;
            }
            
            self.postcodeTextField = textField;
            self.postcodeTextField.text = [self.address.postcode stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
            objc_setAssociatedObject(self.postcodeTextField, @"TextFieldKey", @"postcode", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case 5:
        {
            textField.placeholder            = [Strings requiredString];
            textField.userInteractionEnabled = NO;
            
            if ([self.addressType isEqualToString:@"LOCAL"] || [self.addressType isEqualToString:@"NATIONAL"])
            {
                cell.accessoryType  = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            else
            {
                cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            }
            
            self.countryTextField = textField;
            cell.textLabel.text = [Strings countryString];
            if (self.address.isoCountryCode == nil)
            {
                self.countryTextField.text = nil;
            }
            else
            {
                self.countryTextField.text = [[CountryNames sharedNames] nameForIsoCountryCode:self.address.isoCountryCode];
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
    
    self.actionIndexPath = indexPath;
    
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
        
        self.activeCellIndexPath = [self findCellIndexPathForSubview:textField];
        
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
        self.name = @"";
    }
    else
    {
        [self.address setValue:@"" forKey:key];
    }
    
    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if ([self isAddressComplete] == YES)
    {
        [textField resignFirstResponder];
        
        return YES;
    }
    else
    {
        NSString* key = objc_getAssociatedObject(textField, @"TextFieldKey");
        self.nextIndexPath = [self nextEmptyIndexPathForKey:key];
        
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:self.nextIndexPath];
        
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
    
    NSString* text = [textField.text stringByReplacingOccurrencesOfString:@"\u00a0" withString:@" "];
    if ([key isEqualToString:@"name"])
    {
        self.name = text;
    }
    else
    {
        [self.address setValue:text forKey:key];
    }
    
    [self updateReturnKeyTypeOfTextField:textField];
    
    [self.tableView scrollToRowAtIndexPath:self.activeCellIndexPath
                          atScrollPosition:UITableViewScrollPositionNone
                                  animated:YES];
    
    return NO;  // Need to return NO, because we've already changed textField.text.
}


#pragma mark - Scrollview Delegate

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView
{
    if (self.nextIndexPath != nil)
    {
        UITextField*     nextTextField;
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:self.nextIndexPath];
        self.nextIndexPath = nil;
        
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
    
    self.address.proofImage = [Base64 encode:data];
    
    //### When not reloading here, the new footer text will be way too low (iOS 7.0.6).
    [self.tableView reloadData];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)createAction
{
    self.address.name = self.name;
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [[WebClient sharedClient] createAddressForIsoCountryCode:self.numberIsoCountryCode
                                                  numberType:self.numberTypeMask
                                                        name:self.address.name
                                                  salutation:self.address.salutation
                                                   firstName:self.address.firstName
                                                    lastName:self.address.lastName
                                                 companyName:self.address.companyName
                                          companyDescription:self.address.companyDescription
                                                      street:self.address.street
                                              buildingNumber:self.address.buildingNumber
                                              buildingLetter:self.address.buildingLetter
                                                        city:self.address.city
                                                    postcode:self.address.postcode
                                              isoCountryCode:self.address.isoCountryCode
                                                  proofImage:self.address.proofImage
                                                      idType:nil //########
                                                    idNumber:nil //########
                                                fiscalIdCode:nil //########
                                                  streetCode:nil //########
                                            municipalityCode:nil //########
                                                       reply:^(NSError *error, NSString *addressId, NSArray *missingFields)
    {
         if (error == nil)
         {
             self.address.addressId = addressId;
             [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
         }
         else
         {
             [self showSaveError:error];
         }
     }];
    
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)saveAction
{
    if ([self.name isEqualToString:self.address.name] == YES)
    {
        // Nothing has changed.
        return;
    }
    
    
    NSLog(@"################### IMPLEMENT THIS");
    /*
    [[WebClient sharedClient] createOrUpdateIvrForUuid:self.destination.uuid
                                                  name:self.name
                                            statements:statementsArray
                                                 reply:^(NSError* error)
     {
         if (error == nil)
         {
             self.destination.name = self.name;
             statementsArray[0][@"call"][@"e164"][0] = phone.e164;
             self.destination.statements = [Common jsonStringWithObject:statementsArray];
             
             [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
         }
         else
         {
             self.name = self.destination.name;
             [self showSaveError:error];
         }
     }];
     */
}


- (void)deleteAction
{
    if (self.address.numbers.count == 0)
    {
        NSString* buttonTitle = NSLocalizedStringWithDefaultValue(@"AddressView DeleteTitle", nil, [NSBundle mainBundle],
                                                                  @"Delete Address",
                                                                  @"...\n"
                                                                  @"[1/3 line small font].");
        
        [BlockActionSheet showActionSheetWithTitle:nil
                                        completion:^(BOOL cancelled, BOOL destruct, NSInteger buttonIndex)
        {
            if (destruct == YES)
            {
                self.isDeleting = YES;
                 
                [self.address deleteFromManagedObjectContext:self.managedObjectContext
                                                  completion:^(BOOL succeeded)
                {
                    if (succeeded)
                    {
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                    else
                    {
                        self.isDeleting = NO;
                    }
                }];
            }
        }
                                 cancelButtonTitle:[Strings cancelString]
                            destructiveButtonTitle:buttonTitle
                                 otherButtonTitles:nil];
    }
    else
    {
        NSString* title;
        NSString* message;
        
        title   = NSLocalizedStringWithDefaultValue(@"AddressView CantDeleteTitle", nil, [NSBundle mainBundle],
                                                    @"Can't Delete Address",
                                                    @"...\n"
                                                    @"[1/3 line small font].");
        title   = NSLocalizedStringWithDefaultValue(@"AddressView CantDeleteMessage", nil, [NSBundle mainBundle],
                                                    @"This Address can't be deleted because it's used by one or more Numbers.",
                                                    @"...\n"
                                                    @"[1/3 line small font].");
        
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
}


- (void)showSaveError:(NSError*)error
{
    NSString* title;
    NSString* message;
    
    title   = NSLocalizedStringWithDefaultValue(@"Destination SaveErrorTitle", nil, [NSBundle mainBundle],
                                                @"Failed To Save",
                                                @"....\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"Destination SaveErroMessage", nil, [NSBundle mainBundle],
                                                @"Failed to save this Destination: %@",
                                                @"...\n"
                                                @"[iOS alert message size]");
    [BlockAlertView showAlertViewWithTitle:title
                                   message:[NSString stringWithFormat:message, [error localizedDescription]]
                                completion:nil
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


#pragma mark - Baseclass Override

- (void)save
{
    if (self.isNew == NO && self.isDeleting == NO)
    {
        [self saveAction];
    }
}


- (void)update
{
    [self updateRightBarButtonItem];
}

@end
