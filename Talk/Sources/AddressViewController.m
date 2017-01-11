//
//  AddressViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 16/11/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import <objc/runtime.h>
#import <Photos/Photos.h>
#import "AddressViewController.h"
#import "AddressIdTypesViewController.h"
#import "AddressPostcodesViewController.h"
#import "AddressCitiesViewController.h"
#import "AddressSalutationsViewController.h"
#import "AddressMunicipalitiesViewController.h"
#import "ProofImageViewController.h"
#import "CountriesViewController.h"
#import "Strings.h"
#import "Common.h"
#import "CountryNames.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "DataManager.h"
#import "BlockActionSheet.h"
#import "Settings.h"
#import "Salutation.h"
#import "ProofTypes.h"
#import "ImagePicker.h"
#import "AddressUpdatesHandler.h"
#import "AddressStatus.h"
#import "IdType.h"
#import "NumberData.h"

typedef NS_ENUM(NSUInteger, TableSections)
{
    TableSectionName        = 1UL << 0, // Name given by user.
    TableSectionStatus      = 1UL << 1, // The verification status.
    TableSectionProof       = 1UL << 2, // Proof images.
    TableSectionDetails     = 1UL << 3, // Salutation, company, first, last.
    TableSectionAddress     = 1UL << 4, // Street, number, city, postcode.
    TableSectionExtraFields = 1UL << 5, // Extra for few countries.  Assumed last section in updateExtraFieldsSection.
    TableSectionNumbers     = 1UL << 6, // Optional list of Numbers for which this Address is used currently.
};

typedef NS_ENUM(NSUInteger, TableRowsProof)
{
    TableRowsProofAddress  = 1UL << 0,
    TableRowsProofIdentity = 1UL << 1,
};

typedef NS_ENUM(NSUInteger, TableRowsDetails)
{
    TableRowDetailsSalutation = 1UL << 0,
    TableRowDetailsCompany    = 1UL << 1,
    TableRowDetailsFirstName  = 1UL << 2,
    TableRowDetailsLastName   = 1UL << 3,
};

typedef NS_ENUM(NSUInteger, TableRowsAddress)
{
    TableRowAddressStreet         = 1UL << 0,
    TableRowAddressBuildingNumber = 1UL << 1,
    TableRowAddressBuildingLetter = 1UL << 2,
    TableRowAddressCity           = 1UL << 3,
    TableRowAddressPostcode       = 1UL << 4,
    TableRowAddressCountry        = 1UL << 5,
    TableRowAddressAreaCode       = 1UL << 6,
};

// https://developers.voxbone.com/docs/v3/regulation/#extra-fields-list
typedef NS_ENUM(NSUInteger, TableRowsExtraFields)
{
    TableRowExtraFieldsNationality      = 1UL << 0,
    TableRowExtraFieldsIdType           = 1UL << 1,
    TableRowExtraFieldsIdNumber         = 1UL << 2,
    TableRowExtraFieldsFiscalIdCode     = 1UL << 3,
    TableRowExtraFieldsStreetCode       = 1UL << 4,
    TableRowExtraFieldsMunicipalityCode = 1UL << 5,
};


@interface AddressViewController ()

@property (nonatomic, assign) TableSections               sections;
@property (nonatomic, assign) TableRowsProof              rowsProof;
@property (nonatomic, assign) TableRowsExtraFields        rowsExtraFields;
@property (nonatomic, assign) TableRowsDetails            rowsDetails;
@property (nonatomic, assign) TableRowsAddress            rowsAddress;
@property (nonatomic, assign) BOOL                        isNew;
@property (nonatomic, assign) BOOL                        isDeleting;
@property (nonatomic, assign) BOOL                        isUpdatable;

@property (nonatomic, strong) NSFetchedResultsController* fetchedAddressesController;
@property (nonatomic, strong) NSString*                   numberIsoCountryCode;
@property (nonatomic, strong) NSString*                   areaCode;
@property (nonatomic, strong) NSString*                   areaId;
@property (nonatomic, assign) NumberTypeMask              numberTypeMask;

@property (nonatomic, assign) AddressTypeMask             addressTypeMask;
@property (nonatomic, strong) IdType*                     idType;
@property (nonatomic, strong) Salutation*                 salutation;
@property (nonatomic, strong) ProofTypes*                 proofTypes;
@property (nonatomic, strong) NSArray*                    citiesArray;
@property (nonatomic, strong) NSDictionary*               personRegulations;
@property (nonatomic, strong) NSDictionary*               companyRegulations;
@property (nonatomic, assign) BOOL                        alwaysRequired;
@property (nonatomic, readonly) NSArray*                  extraFields;    // Has get method.
@property (nonatomic, readonly) NSArray*                  idTypes;        // Has get method.

@property (nonatomic, strong) UITextField*                idTypeTextField;
@property (nonatomic, strong) UITextField*                idNumberTextField;
@property (nonatomic, strong) UITextField*                nationalityTextField;
@property (nonatomic, strong) UITextField*                fiscalIdCodeTextField;
@property (nonatomic, strong) UITextField*                streetCodeTextField;
@property (nonatomic, strong) UITextField*                municipalityCodeTextField;
@property (nonatomic, strong) UITextField*                salutationTextField;
@property (nonatomic, strong) UITextField*                companyNameTextField;
@property (nonatomic, strong) UITextField*                firstNameTextField;
@property (nonatomic, strong) UITextField*                lastNameTextField;
@property (nonatomic, strong) UITextField*                cityTextField;
@property (nonatomic, strong) UITextField*                postcodeTextField;
@property (nonatomic, strong) UITextField*                countryTextField;

@property (nonatomic, strong) NSIndexPath*                companyNameIndexPath;
@property (nonatomic, strong) NSIndexPath*                firstNameIndexPath;
@property (nonatomic, strong) NSIndexPath*                lastNameIndexPath;
@property (nonatomic, strong) NSIndexPath*                streetIndexPath;
@property (nonatomic, strong) NSIndexPath*                buildingNumberIndexPath;
@property (nonatomic, strong) NSIndexPath*                buildingLetterIndexPath;
@property (nonatomic, strong) NSIndexPath*                cityIndexPath;
@property (nonatomic, strong) NSIndexPath*                postcodeIndexPath;
@property (nonatomic, strong) NSIndexPath*                idTypeIndexPath;
@property (nonatomic, strong) NSIndexPath*                idNumberIndexPath;
@property (nonatomic, strong) NSIndexPath*                fiscalIdCodeIndexPath;
@property (nonatomic, strong) NSIndexPath*                streetCodeIndexPath;
@property (nonatomic, strong) NSIndexPath*                municipalityCodeIndexPath;

@property (nonatomic, strong) NSIndexPath*                nextIndexPath;      // Index-path of cell to show after Next button is tapped.

@property (nonatomic, copy) void (^createCompletion)(AddressData* address);

@property (nonatomic, strong) NSIndexPath*                activeCellIndexPath;

@property (nonatomic, strong) ImagePicker*                imagePicker;

@end


@implementation AddressViewController

- (instancetype)initWithAddress:(AddressData*)address
           managedObjectContext:(NSManagedObjectContext*)managedObjectContext
                    addressType:(AddressTypeMask)addressTypeMask //### TODO Delete and let is come from API 9.
                 isoCountryCode:(NSString*)isoCountryCode
                       areaCode:(NSString*)areaCode
                         areaId:(NSString*)areaId
                           city:(NSString*)city
                     numberType:(NumberTypeMask)numberTypeMask
                     completion:(void (^)(AddressData* address))completion;
{
    if (self = [super initWithManagedObjectContext:managedObjectContext])
    {
        self.isNew                = (address == nil);
        self.isUpdatable          = (address != nil && isoCountryCode != nil && address.addressStatus == AddressStatusStagedMask);
        self.address              = address;
        self.title                = self.isNew ? [Strings newAddressString] : [Strings addressString];

        self.numberIsoCountryCode = isoCountryCode;
        self.areaCode             = areaCode;
        self.areaId               = areaId;
        self.numberTypeMask       = numberTypeMask;
        self.addressTypeMask      = addressTypeMask;
        self.createCompletion     = completion;

        self.imagePicker          = [[ImagePicker alloc] initWithPresentingViewController:self];
        
        if (self.isNew == YES)
        {
            // Create a new managed object context; set its parent to the fetched results controller's context.
            NSManagedObjectContext* managedObjectContext;
            managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [managedObjectContext setParentContext:self.managedObjectContext];
            self.managedObjectContext = managedObjectContext;
            
            self.address = [NSEntityDescription insertNewObjectForEntityForName:@"Address"
                                                         inManagedObjectContext:self.managedObjectContext];
            self.address.salutation = @"MS";

            if (self.addressTypeMask == AddressTypeLocalMask)
            {
                self.address.areaCode = areaCode;
                self.address.city     = [city capitalizedString];
            }
        }
        else
        {
            self.managedObjectContext = managedObjectContext;
        }

        self.item = self.address;

        self.salutation = [[Salutation alloc] initWithString:self.address.salutation];

        if (self.addressTypeMask == AddressTypeLocalMask || self.addressTypeMask == AddressTypeNationalMask)
        {
            self.address.isoCountryCode = self.numberIsoCountryCode;
        }

        self.idType = [[IdType alloc] initWithString:self.address.idType];

        self.rowsDetails |= TableRowDetailsSalutation;
        if (self.isNew == YES || self.isUpdatable)
        {
            self.rowsDetails |= TableRowDetailsCompany;
            self.rowsDetails |= TableRowDetailsFirstName;
            self.rowsDetails |= TableRowDetailsLastName;
        }
        else
        {
            self.rowsDetails |= (self.address.companyName.length > 0) ? TableRowDetailsCompany   : 0;
            self.rowsDetails |= (self.address.firstName.length   > 0) ? TableRowDetailsFirstName : 0;
            self.rowsDetails |= (self.address.lastName.length    > 0) ? TableRowDetailsLastName  : 0;
        }
        
        self.rowsAddress |= TableRowAddressStreet;
        self.rowsAddress |= TableRowAddressBuildingNumber;
        self.rowsAddress |= TableRowAddressCity;
        self.rowsAddress |= TableRowAddressPostcode;
        self.rowsAddress |= TableRowAddressCountry;
        if (self.isNew == YES || self.isUpdatable)
        {
            self.rowsAddress |= TableRowAddressBuildingLetter;
            self.rowsAddress |= (self.addressTypeMask == AddressTypeLocalMask) ? TableRowAddressAreaCode : 0;
        }
        else
        {
            self.rowsAddress |= (self.address.buildingLetter.length > 0) ? TableRowAddressBuildingLetter : 0;
            self.rowsAddress |= (self.address.areaCode.length       > 0) ? TableRowAddressAreaCode       : 0;
        }
    }
    
    return self;
}


- (NSString*)localizedExtraFieldTitleForRow:(NSUInteger)row
{
    NSString* title = nil;

    switch ([Common nthBitSet:row inValue:self.rowsExtraFields])
    {
        case TableRowExtraFieldsNationality:
        {
            title = NSLocalizedStringWithDefaultValue(@"Address Nationality", nil, [NSBundle mainBundle],
                                                      @"Nationality",
                                                      @"...");
            break;
        }
        case TableRowExtraFieldsIdType:
        {
            title = NSLocalizedStringWithDefaultValue(@"Address ID Type", nil, [NSBundle mainBundle],
                                                      @"ID Type",
                                                      @"...");
            break;
        }
        case TableRowExtraFieldsIdNumber:
        {
            title = NSLocalizedStringWithDefaultValue(@"Address ID Number", nil, [NSBundle mainBundle],
                                                      @"ID Number",
                                                      @"...");
            break;
        }
        case TableRowExtraFieldsFiscalIdCode:
        {
            title = [IdType localizedStringForValue:IdTypeValueFiscalIdCode];
            break;
        }
        case TableRowExtraFieldsStreetCode:
        {
            title = NSLocalizedStringWithDefaultValue(@"Address Denmark Street Code", nil, [NSBundle mainBundle],
                                                      @"Street Code",
                                                      @"...");
            break;
        }
        case TableRowExtraFieldsMunicipalityCode:
        {
            title = [Strings municipalityCodeString];
            break;
        }
    }
    
    return title;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;

    UIBarButtonItem* buttonItem;
    if (self.isNew)
    {
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                   target:self
                                                                   action:@selector(createAction)];
        self.navigationItem.leftBarButtonItem = buttonItem;

        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancelAction)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }
    else if (self.isUpdatable == NO)
    {
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                   target:self
                                                                   action:@selector(deleteAction)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }
    
    [self updateSaveBarButtonItem];
    
    if (self.isNew || self.isUpdatable)
    {
        [self loadData];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.postcodeTextField.text           = self.address.postcode;
    self.cityTextField.text               = self.address.city;
    self.municipalityCodeTextField.text   = self.address.municipalityCode;

    self.companyNameTextField.placeholder = [self placeHolderForTextField:self.companyNameTextField];
    self.firstNameTextField.placeholder   = [self placeHolderForTextField:self.firstNameTextField];
    self.lastNameTextField.placeholder    = [self placeHolderForTextField:self.lastNameTextField];

    [self updateSaveBarButtonItem];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.isNew == NO)
    {
        [self doAddressUpdate];
    }
}


- (void)doAddressUpdate
{
    NSString*     title = nil;
    NSString*     message;
    NSDictionary* addressUpdate = [[AddressUpdatesHandler sharedHandler] addressUpdateWithUuid:self.address.uuid];
    if (addressUpdate != nil)
    {
        AddressStatusMask mask = [addressUpdate[@"addressStatus"] integerValue];
        switch (mask)
        {
            case AddressStatusUnknown:
            {
                break;
            }
            case AddressStatusStagedMask:
            {
                break;
            }
            case AddressStatusNotVerifiedMask:
            {
                break;
            }
            case AddressStatusVerificationRequestedMask:
            {
                break;
            }
            case AddressStatusVerifiedMask:
            {
                title   = NSLocalizedStringWithDefaultValue(@"Address:AddressLocal Verified", nil, [NSBundle mainBundle],
                                                            @"Address Is Verified",
                                                            @"...");
                message = NSLocalizedStringWithDefaultValue(@"Address:AddressLocal Verified", nil, [NSBundle mainBundle],
                                                            @"Your address plus the proof image have been "
                                                            @"checked and all is okay.\n\nYou can now "
                                                            @"buy Numbers that require an address in this area.",
                                                            @"...");
                break;
            }
            case AddressStatusRejectedMask:
            {
                title   = NSLocalizedStringWithDefaultValue(@"Address:AddressLocal Verified", nil, [NSBundle mainBundle],
                                                            @"Address Is Rejected",
                                                            @"...");
                message = NSLocalizedStringWithDefaultValue(@"Address:AddressLocal Verified", nil, [NSBundle mainBundle],
                                                            @"Your address plus the proof image have been "
                                                            @"checked, but something is not correct yet: %@.\n\n"
                                                            @"Please add a new image or create a new Address.",
                                                            @"...");
                message = [NSString stringWithFormat:message, [self rejectionReasonMessageForAddressUpdate:addressUpdate]];
                break;
            }
            case AddressStatusDisabledMask:
            {
                title   = NSLocalizedStringWithDefaultValue(@"Address:AddressLocal Verified", nil, [NSBundle mainBundle],
                                                            @"Address Is Disabled",
                                                            @"...");
                message = NSLocalizedStringWithDefaultValue(@"Address:AddressLocal Verified", nil, [NSBundle mainBundle],
                                                            @"Your address has been disabled.\n\n"
                                                            @"Please contact us, via Help > Contact Us, "
                                                            @"to receive more details.",
                                                            @"...");
                break;
            }
        }
    }

    if (title != nil)
    {
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            [[AddressUpdatesHandler sharedHandler] removeAddressUpdateWithUuid:self.address.uuid];
        }
                             cancelButtonTitle:[Strings okString]
                             otherButtonTitles:nil];
    }
    else
    {
        [[AddressUpdatesHandler sharedHandler] removeAddressUpdateWithUuid:self.address.uuid];
    }
}


- (NSString*)rejectionReasonMessageForAddressUpdate:(NSDictionary*)addressUpdate
{
    NSArray* messages = [AddressStatus rejectionReasonMessagesForMask:[addressUpdate[@"rejectionReasons"] integerValue]];

    return [messages componentsJoinedByString:@", "];
}


- (void)dealloc
{
    [[WebClient sharedClient] cancelAllRetrieveAreaInfoForIsoCountryCode:self.numberIsoCountryCode areaId:self.areaId];
}


#pragma mark - Helpers

- (NSString*)stringByStrippingNonBreakingSpaces:(NSString*)string
{
    return [string stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
}


- (void)updateSaveBarButtonItem
{
    BOOL complete;
    
    if (self.isNew == YES || self.isUpdatable)
    {
        complete = [self isAddressComplete];

        if (self.proofTypes != nil)
        {
            complete = complete && self.address.hasIdentityProof;
        }
    }
    else
    {
        complete = [self.address.name stringByRemovingWhiteSpace].length > 0;
    }
    
    self.navigationItem.leftBarButtonItem.enabled = complete;
}


- (void)loadData
{
    self.isLoading = YES;
    __weak typeof(self) weakSelf = self;
    [[WebClient sharedClient] retrieveNumberAreaInfoForIsoCountryCode:self.numberIsoCountryCode
                                                               areaId:self.areaId
                                                                reply:^(NSError*        error,
                                                                        NSArray*        cities,
                                                                        AddressTypeMask addressType,
                                                                        BOOL            alwaysRequired,
                                                                        NSDictionary*   personRegulations,
                                                                        NSDictionary*   companyRegulations)
    {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (error == nil)
        {
            strongSelf.citiesArray        = cities;
            strongSelf.addressTypeMask    = addressType;
            strongSelf.alwaysRequired     = alwaysRequired;
            strongSelf.personRegulations  = personRegulations;
            strongSelf.companyRegulations = companyRegulations;
            strongSelf.proofTypes         = [[ProofTypes alloc] initWithPerson:personRegulations
                                                                       company:companyRegulations
                                                                    salutation:self.salutation];
            if (strongSelf.citiesArray.count > 0)
            {
                strongSelf.address.postcode = @"";     // Resets what user may have typed while loading (on slow internet).
                strongSelf.address.city     = @"";     // Resets what user may have typed while loading (on slow internet).
            }

            [strongSelf.tableView reloadData];
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
                [strongSelf dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[Strings cancelString]
                                 otherButtonTitles:nil];
        }

        strongSelf.isLoading = NO;    // Placed here, after processing results, to let reload of search results work.
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

    if (self.isNew == YES || self.isUpdatable)
    {
        emptyMask |= ([self.address.name           stringByRemovingWhiteSpace].length == 0) << 0;
        emptyMask |= ([self.address.companyName    stringByRemovingWhiteSpace].length == 0) << 1;
        emptyMask |= ([self.address.firstName      stringByRemovingWhiteSpace].length == 0) << 2;
        emptyMask |= ([self.address.lastName       stringByRemovingWhiteSpace].length == 0) << 3;
        emptyMask |= ([self.address.street         stringByRemovingWhiteSpace].length == 0) << 4;
        emptyMask |= ([self.address.buildingNumber stringByRemovingWhiteSpace].length == 0) << 5;
        emptyMask |= ([self.address.buildingLetter stringByRemovingWhiteSpace].length == 0) << 6;
        if (self.citiesArray.count == 0)
        {
            emptyMask |= ([self.address.city       stringByRemovingWhiteSpace].length == 0) << 7;
            emptyMask |= ([self.address.postcode   stringByRemovingWhiteSpace].length == 0) << 8;
        }

        emptyMask |= ((self.rowsExtraFields & TableRowExtraFieldsIdNumber) &&
                      ([self.address.idNumber stringByRemovingWhiteSpace].length == 0)) << 9;
        emptyMask |= ((self.rowsExtraFields & TableRowExtraFieldsFiscalIdCode) &&
                      ([self.address.fiscalIdCode stringByRemovingWhiteSpace].length == 0)) << 10;
        emptyMask |= ((self.rowsExtraFields & TableRowExtraFieldsStreetCode) &&
                      ([self.address.streetCode stringByRemovingWhiteSpace].length == 0)) << 11;
        emptyMask |= ((self.rowsExtraFields & TableRowExtraFieldsMunicipalityCode) &&
                      ([self.address.municipalityCode stringByRemovingWhiteSpace].length == 0)) << 12;
    }
    else
    {
        emptyMask |= ([self.address.name stringByRemovingWhiteSpace].length == 0) << 0;
    }

    if (emptyMask != 0)
    {
        currentBit |= [currentKey isEqualToString:@"name"]             <<  0;
        currentBit |= [currentKey isEqualToString:@"companyName"]      <<  1;
        currentBit |= [currentKey isEqualToString:@"firstName"]        <<  2;
        currentBit |= [currentKey isEqualToString:@"lastName"]         <<  3;
        currentBit |= [currentKey isEqualToString:@"street"]           <<  4;
        currentBit |= [currentKey isEqualToString:@"buildingNumber"]   <<  5;
        currentBit |= [currentKey isEqualToString:@"buildingLetter"]   <<  6;
        currentBit |= [currentKey isEqualToString:@"city"]             <<  7;
        currentBit |= [currentKey isEqualToString:@"postcode"]         <<  8;
        currentBit |= [currentKey isEqualToString:@"idNumber"]         <<  9;
        currentBit |= [currentKey isEqualToString:@"fiscalIdCode"]     << 10;
        currentBit |= [currentKey isEqualToString:@"streetCode"]       << 11;
        currentBit |= [currentKey isEqualToString:@"municipalityCode"] << 12;
        
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
        indexPath = (nextBit == (1 <<  0)) ? self.nameIndexPath             : indexPath;
        indexPath = (nextBit == (1 <<  1)) ? self.companyNameIndexPath      : indexPath;
        indexPath = (nextBit == (1 <<  2)) ? self.firstNameIndexPath        : indexPath;
        indexPath = (nextBit == (1 <<  3)) ? self.lastNameIndexPath         : indexPath;
        indexPath = (nextBit == (1 <<  4)) ? self.streetIndexPath           : indexPath;
        indexPath = (nextBit == (1 <<  5)) ? self.buildingNumberIndexPath   : indexPath;
        indexPath = (nextBit == (1 <<  6)) ? self.buildingLetterIndexPath   : indexPath;
        indexPath = (nextBit == (1 <<  7)) ? self.cityIndexPath             : indexPath;
        indexPath = (nextBit == (1 <<  8)) ? self.postcodeIndexPath         : indexPath;
        indexPath = (nextBit == (1 <<  9)) ? self.idNumberIndexPath         : indexPath;
        indexPath = (nextBit == (1 << 10)) ? self.fiscalIdCodeIndexPath     : indexPath;
        indexPath = (nextBit == (1 << 11)) ? self.streetCodeIndexPath       : indexPath;
        indexPath = (nextBit == (1 << 12)) ? self.municipalityCodeIndexPath : indexPath;

        return indexPath;
    }
    else
    {
        return nil;
    }
}


- (BOOL)isAddressComplete
{
    BOOL complete;
    
    if (self.isNew == YES || self.isUpdatable)
    {
        if (self.salutation.isPerson)
        {
            complete = [self.address.name           stringByRemovingWhiteSpace].length > 0    &&
                       [self.address.firstName      stringByRemovingWhiteSpace].length > 0    &&
                       [self.address.lastName       stringByRemovingWhiteSpace].length > 0    &&
                       [self.address.street         stringByRemovingWhiteSpace].length > 0    &&
                       [self.address.buildingNumber stringByRemovingWhiteSpace].length > 0    &&
                       [self.address.city           stringByRemovingWhiteSpace].length > 0    &&
                       [self.address.postcode       stringByRemovingWhiteSpace].length > 0    &&
                       [self.address.isoCountryCode stringByRemovingWhiteSpace].length > 0    &&
                       self.proofTypes.requiresAddressProof  == self.address.hasAddressProof  &&
                       self.proofTypes.requiresIdentityProof == self.address.hasIdentityProof &&
                       [self areExtraFieldsComplete];

        }

        if (self.salutation.isCompany)
        {
            complete = [self.address.name           stringByRemovingWhiteSpace].length > 0    &&
                       [self.address.companyName    stringByRemovingWhiteSpace].length > 0    &&
                       [self.address.street         stringByRemovingWhiteSpace].length > 0    &&
                       [self.address.buildingNumber stringByRemovingWhiteSpace].length > 0    &&
                       [self.address.city           stringByRemovingWhiteSpace].length > 0    &&
                       [self.address.postcode       stringByRemovingWhiteSpace].length > 0    &&
                       [self.address.isoCountryCode stringByRemovingWhiteSpace].length > 0    &&
                       self.proofTypes.requiresAddressProof  == self.address.hasAddressProof  &&
                       self.proofTypes.requiresIdentityProof == self.address.hasIdentityProof &&
                       [self areExtraFieldsComplete];
        }
    }
    else
    {
        complete = ([self.address.name stringByRemovingWhiteSpace].length > 0);
    }
    
    return complete;
}


- (BOOL)areExtraFieldsComplete
{
    BOOL complete;
    BOOL valid;

    if (self.isNew == YES || self.isUpdatable)
    {
        complete = !((self.rowsExtraFields & TableRowExtraFieldsNationality) &&
                     ([self.address.nationality stringByRemovingWhiteSpace].length == 0)) &&
                   !((self.rowsExtraFields & TableRowExtraFieldsIdType) &&
                     ([self.address.idType stringByRemovingWhiteSpace].length == 0)) &&
                   !((self.rowsExtraFields & TableRowExtraFieldsIdNumber) &&
                     ([self.address.idNumber stringByRemovingWhiteSpace].length == 0)) &&
                   !((self.rowsExtraFields & TableRowExtraFieldsFiscalIdCode) &&
                     ([self.address.fiscalIdCode stringByRemovingWhiteSpace].length == 0)) &&
                   !((self.rowsExtraFields & TableRowExtraFieldsStreetCode) &&
                     ([self.address.streetCode stringByRemovingWhiteSpace].length == 0)) &&
                   !((self.rowsExtraFields & TableRowExtraFieldsMunicipalityCode) &&
                     ([self.address.municipalityCode stringByRemovingWhiteSpace].length == 0));

        IdType* idType = [[IdType alloc] initWithValue:IdTypeValueFiscalIdCode];
        valid    = !((self.rowsExtraFields & TableRowExtraFieldsIdNumber) &&
                     ![self.idType isValidWithIdString:self.address.idNumber]) &&
                   !((self.rowsExtraFields & TableRowExtraFieldsFiscalIdCode) &&
                     ![idType isValidWithIdString:self.address.fiscalIdCode]) &&
                   !((self.rowsExtraFields & TableRowExtraFieldsStreetCode) &&
                     ![self isValidStreetCode:self.address.streetCode]);
    }
    else
    {
        complete = YES;
        valid    = YES;
    }

    return complete && valid;
}


- (BOOL)isValidStreetCode:(NSString*)streetCode
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[0-9]{1,4}"];

    return [predicate evaluateWithObject:streetCode];
}


- (void)initializeIndexPaths
{
    NSInteger section  = [Common nOfBit:TableSectionName inValue:self.sections];
    self.nameIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];

    if (self.isNew || self.isUpdatable)
    {
        NSInteger detailsSection       = [Common nOfBit:TableSectionDetails inValue:self.sections];
        NSInteger addressSection       = [Common nOfBit:TableSectionAddress inValue:self.sections];

        self.companyNameIndexPath      = [self indexPathForRowMask:TableRowDetailsCompany        inSection:detailsSection];
        self.firstNameIndexPath        = [self indexPathForRowMask:TableRowDetailsFirstName      inSection:detailsSection];
        self.lastNameIndexPath         = [self indexPathForRowMask:TableRowDetailsLastName       inSection:detailsSection];

        self.streetIndexPath           = [self indexPathForRowMask:TableRowAddressStreet         inSection:addressSection];
        self.buildingNumberIndexPath   = [self indexPathForRowMask:TableRowAddressBuildingNumber inSection:addressSection];
        self.buildingLetterIndexPath   = [self indexPathForRowMask:TableRowAddressBuildingLetter inSection:addressSection];
        self.cityIndexPath             = [self indexPathForRowMask:TableRowAddressCity           inSection:addressSection];
        self.postcodeIndexPath         = [self indexPathForRowMask:TableRowAddressPostcode       inSection:addressSection];

        self.idNumberIndexPath         = [self indexPathForExtraFieldsRowMask:TableRowExtraFieldsIdNumber];
        self.idTypeIndexPath           = [self indexPathForExtraFieldsRowMask:TableRowExtraFieldsIdType];
        self.fiscalIdCodeIndexPath     = [self indexPathForExtraFieldsRowMask:TableRowExtraFieldsFiscalIdCode];
        self.streetCodeIndexPath       = [self indexPathForExtraFieldsRowMask:TableRowExtraFieldsStreetCode];
        self.municipalityCodeIndexPath = [self indexPathForExtraFieldsRowMask:TableRowExtraFieldsMunicipalityCode];
    }
}


- (NSIndexPath*)indexPathForRowMask:(NSInteger)rowMask inSection:(NSInteger)section
{
    return [NSIndexPath indexPathForRow:[Common bitIndexOfMask:rowMask] inSection:section];
}


- (NSIndexPath*)indexPathForExtraFieldsRowMask:(NSInteger)rowMask
{
    NSInteger section = [Common nOfBit:TableSectionExtraFields inValue:self.sections];
    NSInteger row     = [Common nOfBit:rowMask                 inValue:self.rowsExtraFields];

    return [NSIndexPath indexPathForRow:row inSection:section];
}


- (NSString*)placeHolderForTextField:(UITextField*)textField
{
    NSString* placeHolder = nil;
    
    // The default is "Required".

    if (self.salutation.isPerson)
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

    if (self.salutation.isCompany)
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

    return placeHolder;
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


- (NSString*)cellIdentifierForIndexPath:(NSIndexPath*)indexPath
{
    return [NSString stringWithFormat:@"Cell %d:%d", (int)indexPath.section, (int)indexPath.row];
}


- (void)refreshExtraFieldsSection
{
    NSArray* idTypes = self.idTypes;

    if (idTypes.count == 1)
    {
        self.idType.string  = idTypes[0];
        self.address.idType = idTypes[0];
    }
    else
    {
        self.idType.value   = IdTypeValueNone;
        self.address.idType = nil;
    }

    self.address.idNumber     = nil;
    self.address.fiscalIdCode = nil;

    [Common reloadSections:TableSectionExtraFields allSections:self.sections tableView:self.tableView];
}


- (void)updateExtraFieldsSection
{
    if (self.extraFields.count > 0)
    {
        // Assumes that Extra Fields section is bottom one.
        NSUInteger  index    = [self numberOfSectionsInTableView:self.tableView] - 1;
        NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];

        [self.tableView beginUpdates];
        [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
    else
    {
        // Assumes that Extra Fields section is bottom one.
        NSUInteger  index    = [self numberOfSectionsInTableView:self.tableView];
        NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];

        [self.tableView beginUpdates];
        [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];

        // Clear Extra Fields data.
        self.address.idType           = nil;
        self.address.idNumber         = nil;
        self.address.nationality      = nil;
        self.address.fiscalIdCode     = nil;
        self.address.streetCode       = nil;
        self.address.municipalityCode = nil;
    }
}


- (void)updateAddressSectionForDenmark
{
    if ([self.address.isoCountryCode isEqualToString:@"DK"])
    {
        NSData* data     = [Common dataForResource:@"DenmarkCityPostcodes" ofType:@"json"];
        self.citiesArray = [Common objectWithJsonData:data];

        if (self.address.postcode != nil)
        {
            NSPredicate* predicate;
            predicate = [NSPredicate predicateWithFormat:@"ANY postcodes == %@", self.address.postcode];
            NSDictionary* city = [[self.citiesArray filteredArrayUsingPredicate:predicate] firstObject];

            if (city == nil)
            {
                self.address.postcode = nil;
            }
            else
            {
                self.address.city = city[@"city"];
            }
        }

        if (self.address.city != nil)
        {
            NSPredicate* predicate;
            predicate = [NSPredicate predicateWithFormat:@"city == %@", self.address.city];
            NSDictionary* city = [[self.citiesArray filteredArrayUsingPredicate:predicate] firstObject];

            if (city == nil)
            {
                self.address.city = nil;
            }
            else if ([city[@"postcodes"] count] == 1)
            {
                self.address.postcode = city[@"postcodes"][0];
            }
        }
    }
    else
    {
        self.citiesArray = nil;
    }

    [self.tableView reloadData];

}


- (void)showIdTypesViewControllerWithCell:(UITableViewCell*)cell
{
    AddressIdTypesViewController* idTypesViewController;

    NSArray* idTypes = self.idTypes;
    idTypesViewController = [[AddressIdTypesViewController alloc] initWithIdType:self.idType
                                                                         idTypes:idTypes
                                                                      completion:^
    {
        self.address.idType = self.idType.string;

        // Update the cell.
        self.idTypeTextField.text = self.idType.localizedString;
    }];

    idTypesViewController.title = cell.textLabel.text;
    [self.navigationController pushViewController:idTypesViewController animated:YES];
}


- (NSArray*)extraFields
{
    if (self.alwaysRequired || [self.address.isoCountryCode isEqualToString:self.numberIsoCountryCode])
    {
        return self.salutation.isPerson ? self.personRegulations[@"extraFields"] : self.companyRegulations[@"extraFields"];
    }
    else
    {
        return nil;
    }
}


- (NSArray*)idTypes
{
    if (self.alwaysRequired || [self.address.isoCountryCode isEqualToString:self.numberIsoCountryCode])
    {
        return self.salutation.isPerson ? self.personRegulations[@"idTypes"] : self.companyRegulations[@"idTypes"];
    }
    else
    {
        return nil;
    }
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    self.sections = 0;

    // Mandatory sections.
    self.sections |= TableSectionName;
    self.sections |= TableSectionDetails;
    self.sections |= TableSectionAddress;

    // Optional sections.
    self.sections |= self.isNew ? 0 : TableSectionStatus;
    self.sections |= (self.proofTypes.requiresAddressProof || self.proofTypes.requiresIdentityProof ||
                      self.address.hasAddressProof         || self.address.hasIdentityProof) ? TableSectionProof : 0;

    self.rowsProof = 0;
    self.rowsProof |= (self.proofTypes.requiresAddressProof  || self.address.hasAddressProof)  ? TableRowsProofAddress  : 0;
    self.rowsProof |= (self.proofTypes.requiresIdentityProof || self.address.hasIdentityProof) ? TableRowsProofIdentity : 0;

    // We need to determine the existence of the ExtraFields section dynamically, based on
    // the country of the address (which the user may have to select from a list).
    self.rowsExtraFields = 0;
    if (self.isNew)
    {
        NSArray* fields = self.extraFields;

        if (fields.count > 0)
        {
            self.sections |= TableSectionExtraFields;

            self.rowsExtraFields |= [fields containsObject:@"nationality"]      ? TableRowExtraFieldsNationality      : 0;
            self.rowsExtraFields |= [fields containsObject:@"idType"]           ? TableRowExtraFieldsIdType           : 0;
            self.rowsExtraFields |= [fields containsObject:@"idNumber"]         ? TableRowExtraFieldsIdNumber         : 0;
            self.rowsExtraFields |= [fields containsObject:@"fiscalIdCode"]     ? TableRowExtraFieldsFiscalIdCode     : 0;
            self.rowsExtraFields |= [fields containsObject:@"streetCode"]       ? TableRowExtraFieldsStreetCode       : 0;
            self.rowsExtraFields |= [fields containsObject:@"municipalityCode"] ? TableRowExtraFieldsMunicipalityCode : 0;
        }
    }
    else
    {
        self.rowsExtraFields |= (self.address.nationality      != nil) ? TableRowExtraFieldsNationality      : 0;
        self.rowsExtraFields |= (self.address.idType           != nil) ? TableRowExtraFieldsIdType           : 0;
        self.rowsExtraFields |= (self.address.idNumber         != nil) ? TableRowExtraFieldsIdNumber         : 0;
        self.rowsExtraFields |= (self.address.fiscalIdCode     != nil) ? TableRowExtraFieldsFiscalIdCode     : 0;
        self.rowsExtraFields |= (self.address.streetCode       != nil) ? TableRowExtraFieldsStreetCode       : 0;
        self.rowsExtraFields |= (self.address.municipalityCode != nil) ? TableRowExtraFieldsMunicipalityCode : 0;

        self.sections |= (self.rowsExtraFields != 0)      ? TableSectionExtraFields : 0;
        self.sections |= (self.address.numbers.count > 0) ? TableSectionNumbers     : 0;
    }

    [self initializeIndexPaths];

    return [Common bitsSetCount:self.sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionName:        numberOfRows = 1;                                          break;
        case TableSectionStatus:      numberOfRows = 1;                                          break;
        case TableSectionProof:       numberOfRows = [Common bitsSetCount:self.rowsProof];       break;
        case TableSectionDetails:     numberOfRows = [Common bitsSetCount:self.rowsDetails];     break;
        case TableSectionAddress:     numberOfRows = [Common bitsSetCount:self.rowsAddress];     break;
        case TableSectionExtraFields: numberOfRows = [Common bitsSetCount:self.rowsExtraFields]; break;
        case TableSectionNumbers:     numberOfRows = self.address.numbers.count;                 break;
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
            if (self.isNew || self.isUpdatable)
            {
                switch (self.addressTypeMask)
                {
                    case AddressTypeWorldwideMask:
                    {
                        title = NSLocalizedStringWithDefaultValue(@"Address:AddressWorldwide SectionHeader", nil,
                                                                  [NSBundle mainBundle], @"Worldwide Contact Address",
                                                                  @"Address of someone.");
                        break;
                    }
                    case AddressTypeNationalMask:
                    {
                        title = NSLocalizedStringWithDefaultValue(@"Address:AddressNational SectionHeader", nil,
                                                                  [NSBundle mainBundle], @"National Contact Address",
                                                                  @"Address of someone.");
                        break;
                    }
                    case AddressTypeLocalMask:
                    {
                        title = NSLocalizedStringWithDefaultValue(@"Address:AddressLocal SectionHeader", nil,
                                                                  [NSBundle mainBundle], @"Local Contact Address",
                                                                  @"Address of someone.");
                        break;
                    }
                    case AddressTypeExtranational:
                    {
                        title = NSLocalizedStringWithDefaultValue(@"Address:AddressNational SectionHeader", nil,
                                                                  [NSBundle mainBundle], @"Outside County Contact Address",
                                                                  @"Address of someone.");
                        break;
                    }
                }
            }
            else
            {
                title = NSLocalizedStringWithDefaultValue(@"Address:ContactAddress SectionHeader", nil,
                                                          [NSBundle mainBundle], @"Contact Address",
                                                          @"...");
            }

            break;
        }
        case TableSectionExtraFields:
        {
            title = NSLocalizedStringWithDefaultValue(@"Address:ExtraFields SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Additional Information",
                                                      @"Name and company of someone.");
            break;
        }
        case TableSectionNumbers:
        {
            title = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                      @"Used For Numbers",
                                                      @"Table header above numbers\n"
                                                      @"[1 line larger font].");
            break;
        }
    }
    
    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title = nil;

    if (self.showFootnotes == NO)
    {
        return nil;
    }

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionName:
        {
            if (self.isNew)
            {
                title = [Strings nameFooterString];
            }

            break;
        }
        case TableSectionProof:
        {
#warning Texts below NEED UPDATE
            if ((self.proofTypes.requiresAddressProof  && self.address.hasAddressProof == NO) ||
                (self.proofTypes.requiresIdentityProof && self.address.hasIdentityProof == NO))
            {
                title = NSLocalizedStringWithDefaultValue(@"Address:Action SectionFooterTakePicture", nil,
                                                          [NSBundle mainBundle],
                                                          @"###### NEEDS DYNAMIC TEXT ... For this area a proof of address is (legally) required.\n\n"
                                                          @"Take a picture of a recent utility bill, or bank statement. "
                                                          @"Make sure the date, your name & address, and the name of "
                                                          @"the company/bank are clearly visible.",
                                                          @"Telephone area (or city).");
            }
            else
            {
                title = NSLocalizedStringWithDefaultValue(@"Address:Action SectionFooterBuy", nil,
                                                          [NSBundle mainBundle],
                                                          @"######## NEEDS UPDATE: You can always buy extra months to use "
                                                          @"this phone number.",
                                                          @"Explaining that user can buy more months.");
            }

            break;
        }
        case TableSectionExtraFields:
        {
            if (self.isNew || self.isUpdatable)
            {
                title = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                          @"A red color indicates that the text you entered is not "
                                                          @"complete/valid yet.",
                                                          @".....");
            }
        }
    }

    return title;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    AddressSalutationsViewController*    salutationsViewController;
    AddressPostcodesViewController*      postcodesViewController;
    AddressCitiesViewController*         citiesViewController;
    AddressMunicipalitiesViewController* municipalitiesViewController;
    CountriesViewController*             countriesViewController;
    NSString*                            isoCountryCode;
    UITableViewCell*                     cell;
    void (^completion)(BOOL cancelled, NSString* isoCountryCode);

    cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell.selectionStyle == UITableViewCellSelectionStyleNone)
    {
        return;
    }
    else
    {
        switch ([Common nthBitSet:indexPath.section inValue:self.sections])
        {
            case TableSectionStatus:
            {
                NSString* title   = [AddressStatus localizedStringForAddressStatusMask:self.address.addressStatus];
                NSString* message = [AddressStatus localizedMessageForAddressStatusMask:self.address.addressStatus];

                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                 {
                     [tableView deselectRowAtIndexPath:indexPath animated:YES];
                 }
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:nil];
                break;
            }
            case TableSectionProof:
            {
                switch ([Common nthBitSet:indexPath.row inValue:self.rowsProof])
                {
                    case TableRowsProofAddress:
                    {
                        if ((self.isNew || self.isUpdatable) && self.address.hasAddressProof == NO)
                        {
                            __weak typeof(self) weakSelf = self;
                            [self.imagePicker pickImageWithCompletion:^(NSData* imageData)
                            {
                                __strong typeof(weakSelf) strongSelf = weakSelf;

                                [tableView deselectRowAtIndexPath:indexPath animated:YES];

                                if (imageData != nil)
                                {
                                    strongSelf.address.addressProof    = imageData;
                                    strongSelf.address.hasAddressProof = YES;
                                    [Common reloadSections:TableSectionProof
                                               allSections:strongSelf.sections
                                                 tableView:strongSelf.tableView];
                                }
                            }];
                        }
                        else
                        {
                            UITableViewCell*          cell = [self.tableView cellForRowAtIndexPath:indexPath];
                            ProofImageViewController* viewController;

                            viewController       = [[ProofImageViewController alloc] initWithAddress:self.address
                                                                                                type:ProofImageTypeAddress
                                                                                            editable:(self.isNew || self.isUpdatable)];
                            viewController.title = cell.textLabel.text;
                            
                            [self.navigationController pushViewController:viewController animated:YES];
                        }

                        break;
                    }
                    case TableRowsProofIdentity:
                    {
                        if ((self.isNew || self.isUpdatable) && self.address.hasIdentityProof == NO)
                        {
                            __weak typeof(self) weakSelf = self;
                            [self.imagePicker pickImageWithCompletion:^(NSData* imageData)
                            {
                                __strong typeof(weakSelf) strongSelf = weakSelf;

                                [tableView deselectRowAtIndexPath:indexPath animated:YES];

                                if (imageData != nil)
                                {
                                    strongSelf.address.identityProof    = imageData;
                                    strongSelf.address.hasIdentityProof = YES;
                                    [Common reloadSections:TableSectionProof
                                               allSections:strongSelf.sections
                                                 tableView:strongSelf.tableView];
                                }
                            }];
                        }
                        else
                        {
                            UITableViewCell*          cell = [self.tableView cellForRowAtIndexPath:indexPath];
                            ProofImageViewController* viewController;

                            viewController       = [[ProofImageViewController alloc] initWithAddress:self.address
                                                                                                type:ProofImageTypeIdentity
                                                                                            editable:(self.isNew || self.isUpdatable)];

                            viewController.title = cell.textLabel.text;
                            
                            [self.navigationController pushViewController:viewController animated:YES];
                        }

                        break;
                    }
                }
                break;
            }
            case TableSectionDetails:
            {
                salutationsViewController = [[AddressSalutationsViewController alloc] initWithSalutation:self.salutation
                                                                                              completion:^
                {
                    BOOL update = ([self.address.salutation isEqualToString:self.salutation.string] == NO);
                    self.address.salutation = self.salutation.string;

                    if (update)
                    {
                        [self refreshExtraFieldsSection];
                    }

                    UITextField* textField = [cell viewWithTag:CommonTextFieldCellTag];
                    textField.text = self.salutation.localizedString;
                }];

                salutationsViewController.title = cell.textLabel.text;
                [self.navigationController pushViewController:salutationsViewController animated:YES];
                break;
            }
            case TableSectionAddress:
            {
                switch ([Common nthBitSet:indexPath.row inValue:self.rowsAddress])
                {
                    case TableRowAddressCity:
                    {
                        citiesViewController = [[AddressCitiesViewController alloc] initWithCitiesArray:self.citiesArray
                                                                                                   address:self.address];
                        [self.navigationController pushViewController:citiesViewController animated:YES];
                        break;
                    }
                    case TableRowAddressPostcode:
                    {
                        postcodesViewController = [[AddressPostcodesViewController alloc] initWithCitiesArray:self.citiesArray
                                                                                                      address:self.address];
                        [self.navigationController pushViewController:postcodesViewController animated:YES];
                        break;
                    }
                    case TableRowAddressCountry:
                    {
                        BOOL hadExtraFields = (self.extraFields.count > 0);
                        isoCountryCode = self.address.isoCountryCode;
                        completion = ^(BOOL cancelled, NSString* isoCountryCode)
                        {
                            if (cancelled == NO)
                            {
                                self.address.isoCountryCode = isoCountryCode;
                                
                                // Update the cell.
                                self.countryTextField.text = [[CountryNames sharedNames] nameForIsoCountryCode:isoCountryCode];

                                if (hadExtraFields != (self.extraFields.count > 0))
                                {
                                    [self updateExtraFieldsSection];
                                }

                                if ([self.numberIsoCountryCode isEqualToString:@"DK"])
                                {
                                    [self updateAddressSectionForDenmark];
                                }
                            }
                        };

                        NSString* excluded = (self.addressTypeMask == AddressTypeExtranational) ? self.numberIsoCountryCode : nil;

                        countriesViewController = [[CountriesViewController alloc] initWithIsoCountryCode:isoCountryCode
                                                                                   excludedIsoCountryCode:excluded
                                                                                                    title:[Strings countryString]
                                                                                               completion:completion];
                        [self.navigationController pushViewController:countriesViewController animated:YES];
                        break;
                    }
                    case TableRowAddressAreaCode:
                    {
                        //####
                    }
                }

                break;
            }
            case TableSectionExtraFields:
            {
                switch ([Common nthBitSet:indexPath.row inValue:self.rowsExtraFields])
                {
                    case TableRowExtraFieldsNationality:
                    {
                        isoCountryCode = self.address.nationality;
                        completion = ^(BOOL cancelled, NSString* isoCountryCode)
                        {
                            if (cancelled == NO)
                            {
                                self.address.nationality = isoCountryCode;

                                // Update the cell.
                                self.nationalityTextField.text = [[CountryNames sharedNames] nameForIsoCountryCode:isoCountryCode];
                            }
                        };

                        countriesViewController = [[CountriesViewController alloc] initWithIsoCountryCode:isoCountryCode
                                                                                                    title:[Strings nationalityString]
                                                                                               completion:completion];
                        [self.navigationController pushViewController:countriesViewController animated:YES];
                        break;
                    }
                    case TableRowExtraFieldsIdType:
                    {
                        if (self.idTypes.count == 1)
                        {
                            return;
                        }
                        else
                        {
                            [self showIdTypesViewControllerWithCell:cell];
                        }
                        break;
                    }
                    case TableRowExtraFieldsMunicipalityCode:
                    {
                        NSData* data                 = [Common dataForResource:@"DenmarkMunicipalities" ofType:@"json"];
                        NSArray* municipalitiesArray = [Common objectWithJsonData:data];

                        municipalitiesViewController = [[AddressMunicipalitiesViewController alloc] initWithMunicipalitiesArray:municipalitiesArray
                                                                                                                        address:self.address];
                        [self.navigationController pushViewController:municipalitiesViewController animated:YES];

                        break;
                    }
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
        case TableSectionName:        cell = [self nameCellForRowAtIndexPath:indexPath];        break;
        case TableSectionStatus:      cell = [self statusCellForRowAtIndexPath:indexPath];      break;
        case TableSectionProof:       cell = [self proofCellForRowAtIndexPath:indexPath];       break;
        case TableSectionDetails:     cell = [self detailsCellForRowAtIndexPath:indexPath];     break;
        case TableSectionAddress:     cell = [self addressCellForRowAtIndexPath:indexPath];     break;
        case TableSectionExtraFields: cell = [self extraFieldsCellForRowAtIndexPath:indexPath]; break;
        case TableSectionNumbers:     cell = [self numbersCellForRowAtIndexPath:indexPath];     break;
    }
    
    return cell;
}


#pragma mark - Cell Methods

- (UITableViewCell*)nameCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell      = [super nameCellForRowAtIndexPath:indexPath];
    UITextField*     textField = [cell viewWithTag:CommonTextFieldCellTag];
    
    objc_setAssociatedObject(textField, @"TextFieldKey", @"name", OBJC_ASSOCIATION_RETAIN);

    [self updateTextField:textField onCell:cell];

    return cell;
}


- (UITableViewCell*)statusCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"StatusCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"StatusCell"];

        cell.accessoryType  = UITableViewCellAccessoryNone;
        cell.textLabel.text = NSLocalizedString(@"Status", @"");
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }

    cell.detailTextLabel.text      = [AddressStatus localizedStringForAddressStatusMask:self.address.addressStatus];
    cell.detailTextLabel.textColor = [Skinning tintColor];

    return cell;
}


- (UITableViewCell*)proofCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"ProofCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ProofCell"];
    }

    cell.detailTextLabel.textColor = [Skinning placeholderColor];

    switch ([Common nthBitSet:indexPath.row inValue:self.rowsProof])
    {
        case TableRowsProofAddress:
        {
            cell.textLabel.text = (self.proofTypes != nil) ? self.proofTypes.localizedAddressProofsString
                                                           : NSLocalizedString(@"Address Proof", @"");

            if ((self.isNew || self.isUpdatable) && self.address.hasAddressProof == NO)
            {
                cell.detailTextLabel.text = [Strings requiredString];
                cell.accessoryType        = UITableViewCellAccessoryNone;
            }
            else
            {
                cell.detailTextLabel.text = nil;
                cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
            }

            break;
        }
        case TableRowsProofIdentity:
        {
            cell.textLabel.text = (self.proofTypes != nil) ? self.proofTypes.localizedIdentityProofsString
                                                           : NSLocalizedString(@"Identity Proof", @"");

            if ((self.isNew || self.isUpdatable) && self.address.hasIdentityProof == NO)
            {
                cell.detailTextLabel.text = [Strings requiredString];
                cell.accessoryType        = UITableViewCellAccessoryNone;
            }
            else
            {
                cell.detailTextLabel.text = nil;
                cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
            }

            break;
        }
    }

    return cell;
}


- (UITableViewCell*)detailsCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    UITextField*     textField;
    NSString*        identifier = [self cellIdentifierForIndexPath:indexPath];

    cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];

        textField = [Common addTextFieldToCell:cell delegate:self];
        textField.tag = CommonTextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:CommonTextFieldCellTag];
    }
    
    textField.userInteractionEnabled = (self.isNew || self.isUpdatable);
    switch ([Common nthBitSet:indexPath.row inValue:self.rowsDetails])
    {
        case TableRowDetailsSalutation:
        {
            self.salutationTextField = textField;
            cell.accessoryType       = (self.isNew || self.isUpdatable) ? UITableViewCellAccessoryDisclosureIndicator
                                                                        : UITableViewCellAccessoryNone;
            cell.selectionStyle      = (self.isNew || self.isUpdatable) ? UITableViewCellSelectionStyleBlue
                                                                        : UITableViewCellSelectionStyleNone;
            cell.textLabel.text      = [Strings salutationString];
            
            textField.text = self.salutation.localizedString;
            textField.userInteractionEnabled = NO;
            objc_setAssociatedObject(textField, @"TextFieldKey", @"salutation", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case TableRowDetailsCompany:
        {
            self.companyNameTextField = textField;
            cell.accessoryType    = UITableViewCellAccessoryNone;
            cell.selectionStyle   = UITableViewCellSelectionStyleNone;
            cell.textLabel.text   = [Strings companyString];
            
            textField.text         = [self stringByStrippingNonBreakingSpaces:self.address.companyName];
            textField.keyboardType = UIKeyboardTypeAlphabet;
            objc_setAssociatedObject(textField, @"TextFieldKey", @"companyName", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case TableRowDetailsFirstName:
        {
            self.firstNameTextField = textField;
            cell.accessoryType      = UITableViewCellAccessoryNone;
            cell.selectionStyle     = UITableViewCellSelectionStyleNone;
            cell.textLabel.text     = [Strings firstNameString];
            
            textField.text         = [self stringByStrippingNonBreakingSpaces:self.address.firstName];
            textField.keyboardType = UIKeyboardTypeAlphabet;
            objc_setAssociatedObject(textField, @"TextFieldKey", @"firstName", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case TableRowDetailsLastName:
        {
            self.lastNameTextField = textField;
            cell.accessoryType     = UITableViewCellAccessoryNone;
            cell.selectionStyle    = UITableViewCellSelectionStyleNone;
            cell.textLabel.text    = [Strings lastNameString];
            
            textField.text         = [self stringByStrippingNonBreakingSpaces:self.address.lastName];
            textField.keyboardType = UIKeyboardTypeAlphabet;
            objc_setAssociatedObject(textField, @"TextFieldKey", @"lastName", OBJC_ASSOCIATION_RETAIN);
            break;
        }
    }
    
    textField.placeholder = [self placeHolderForTextField:textField];
    
    [self updateTextField:textField onCell:cell];
    
    return cell;
}


- (UITableViewCell*)addressCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    UITextField*     textField;
    BOOL             singlePostcode = NO;
    BOOL             singleCity     = NO;
    NSString*        identifier = [self cellIdentifierForIndexPath:indexPath];

    if (self.citiesArray.count == 1)
    {
        singleCity = YES;
        self.address.city = self.citiesArray[0][@"city"];
        
        NSArray* postcodes = self.citiesArray[0][@"postcodes"];
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
        
        textField = [Common addTextFieldToCell:cell delegate:self];
        textField.tag = CommonTextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell.contentView viewWithTag:CommonTextFieldCellTag];
    }

    cell.accessoryType  = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    textField.userInteractionEnabled = (self.isNew || self.isUpdatable);
    switch ([Common nthBitSet:indexPath.row inValue:self.rowsAddress])
    {
        case TableRowAddressStreet:
        {
            cell.textLabel.text = [Strings streetString];
            textField.placeholder  = [Strings requiredString];
            textField.text         = [self stringByStrippingNonBreakingSpaces:self.address.street];
            textField.keyboardType = UIKeyboardTypeAlphabet;
            objc_setAssociatedObject(textField, @"TextFieldKey", @"street", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case TableRowAddressBuildingNumber:
        {
            cell.textLabel.text = [Strings buildingNumberString];
            textField.placeholder            = [Strings requiredString];
            textField.text                   = [self stringByStrippingNonBreakingSpaces:self.address.buildingNumber];
            textField.keyboardType           = UIKeyboardTypeNumbersAndPunctuation;
            textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            objc_setAssociatedObject(textField, @"TextFieldKey", @"buildingNumber", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case TableRowAddressBuildingLetter:
        {
            cell.textLabel.text = [Strings buildingLetterString];
            textField.placeholder            = [Strings optionalString];
            textField.text                   = [self stringByStrippingNonBreakingSpaces:self.address.buildingLetter];
            textField.keyboardType           = UIKeyboardTypeAlphabet;
            textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            objc_setAssociatedObject(textField, @"TextFieldKey", @"buildingLetter", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case TableRowAddressCity:
        {
            cell.textLabel.text = [Strings cityString];
            if (self.citiesArray.count == 0)
            {
                textField.placeholder  = [Strings requiredString];
                textField.keyboardType = UIKeyboardTypeAlphabet;
            }
            else
            {
                if (singleCity == NO)
                {
                    textField.placeholder = [Strings requiredString];
                    textField.text        = nil;
                    cell.accessoryType    = (self.isNew || self.isUpdatable) ? UITableViewCellAccessoryDisclosureIndicator
                                                                             : UITableViewCellAccessoryNone;
                    cell.selectionStyle   = (self.isNew || self.isUpdatable) ? UITableViewCellSelectionStyleDefault
                                                                             : UITableViewCellSelectionStyleNone;
                    textField.text        = nil;
                }
                
                textField.userInteractionEnabled = NO;
            }

            self.cityTextField = textField;
            self.cityTextField.text = [Common capitalizedString:self.address.city];
            self.cityTextField.text = [self stringByStrippingNonBreakingSpaces:self.cityTextField.text];
            objc_setAssociatedObject(self.cityTextField, @"TextFieldKey", @"city", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case TableRowAddressPostcode:
        {
            cell.textLabel.text = [Strings postcodeString];
            if (self.citiesArray.count == 0)
            {
                textField.placeholder            = [Strings requiredString];
                textField.keyboardType           = UIKeyboardTypeNumbersAndPunctuation;
                textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            }
            else
            {
                if (singlePostcode == NO)
                {
                    textField.placeholder = [Strings requiredString];
                    cell.accessoryType    = (self.isNew || self.isUpdatable) ? UITableViewCellAccessoryDisclosureIndicator
                                                                             : UITableViewCellAccessoryNone;
                    cell.selectionStyle   = (self.isNew || self.isUpdatable) ? UITableViewCellSelectionStyleDefault
                                                                             : UITableViewCellSelectionStyleNone;
                    textField.text        = nil;
                }
                
                textField.userInteractionEnabled = NO;
            }
            
            self.postcodeTextField = textField;
            self.postcodeTextField.text = [self stringByStrippingNonBreakingSpaces:self.address.postcode];
            objc_setAssociatedObject(self.postcodeTextField, @"TextFieldKey", @"postcode", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case TableRowAddressCountry:
        {
            textField.placeholder            = [Strings requiredString];
            textField.userInteractionEnabled = NO;
            
            if (self.addressTypeMask == AddressTypeLocalMask    ||
                self.addressTypeMask == AddressTypeNationalMask ||
                (!self.isNew && !self.isUpdatable))
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
        case TableRowAddressAreaCode:
        {
            cell.textLabel.text = [Strings areaCodeString];
            textField.userInteractionEnabled = NO;

            // When creating an address we have the correct `numberIsoCountryCode`, but when showing without
            // Number context (from Numbers > Addresses), we use the `address`' country as backup.
            NSString* isoCountryCode = self.numberIsoCountryCode ? self.numberIsoCountryCode : self.address.isoCountryCode;
            textField.text = [NSString stringWithFormat:@"+%@ %@", [Common callingCodeForCountry:isoCountryCode],
                                                                   self.address.areaCode];
            break;
        }
    }

    [self updateTextField:textField onCell:cell];

    return cell;
}


- (UITableViewCell*)extraFieldsCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    UITextField*     textField;
    NSString*        identifier = [self cellIdentifierForIndexPath:indexPath];

    cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];

        textField = [Common addTextFieldToCell:cell delegate:self];
        textField.tag = CommonTextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:CommonTextFieldCellTag];
    }

    textField.userInteractionEnabled = (self.isNew || self.isUpdatable);
    textField.placeholder            = [Strings requiredString];
    switch ([Common nthBitSet:indexPath.row inValue:self.rowsExtraFields])
    {
        case TableRowExtraFieldsNationality:
        {
            textField.userInteractionEnabled = NO;

            if (self.isNew || self.isUpdatable)
            {
                cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            }
            else
            {
                cell.accessoryType  = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }

            self.nationalityTextField = textField;
            if (self.address.nationality == nil)
            {
                self.nationalityTextField.text = nil;
            }
            else
            {
                self.nationalityTextField.text = [[CountryNames sharedNames] nameForIsoCountryCode:self.address.nationality];
            }

            break;
        }
        case TableRowExtraFieldsIdType:
        {
            textField.userInteractionEnabled = NO;

            if ((self.isNew || self.isUpdatable) && self.idTypes.count > 1)
            {
                cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            }
            else
            {
                cell.accessoryType  = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }

            self.idTypeTextField = textField;
            if (self.address.idType == nil)
            {
                self.idTypeTextField.text = nil;
            }
            else
            {
                self.idTypeTextField.text = self.idType.localizedString;
            }

            break;
        }
        case TableRowExtraFieldsIdNumber:
        {
            self.idNumberTextField = textField;
            cell.accessoryType     = UITableViewCellAccessoryNone;
            cell.selectionStyle    = UITableViewCellSelectionStyleNone;

            textField.text                   = [self stringByStrippingNonBreakingSpaces:self.address.idNumber];
            textField.keyboardType           = UIKeyboardTypeNumbersAndPunctuation;
            textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            objc_setAssociatedObject(textField, @"TextFieldKey", @"idNumber", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case TableRowExtraFieldsFiscalIdCode:
        {
            self.fiscalIdCodeTextField = textField;
            cell.accessoryType         = UITableViewCellAccessoryNone;
            cell.selectionStyle        = UITableViewCellSelectionStyleNone;

            textField.text                   = [self stringByStrippingNonBreakingSpaces:self.address.fiscalIdCode];
            textField.keyboardType           = UIKeyboardTypeNumbersAndPunctuation;
            textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
           objc_setAssociatedObject(textField, @"TextFieldKey", @"fiscalIdCode", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case TableRowExtraFieldsStreetCode:
        {
            self.streetCodeTextField = textField;
            cell.accessoryType       = UITableViewCellAccessoryNone;
            cell.selectionStyle      = UITableViewCellSelectionStyleNone;

            textField.text                   = [self stringByStrippingNonBreakingSpaces:self.address.streetCode];
            textField.keyboardType           = UIKeyboardTypeNumbersAndPunctuation;
            textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            objc_setAssociatedObject(textField, @"TextFieldKey", @"streetCode", OBJC_ASSOCIATION_RETAIN);
            break;
        }
        case TableRowExtraFieldsMunicipalityCode:
        {
            textField.userInteractionEnabled = NO;

            if (self.isNew || self.isUpdatable)
            {
                cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            }
            else
            {
                cell.accessoryType  = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }

            self.municipalityCodeTextField = textField;
            if (self.address.municipalityCode == nil)
            {
                self.municipalityCodeTextField.text = nil;
            }
            else
            {
                self.municipalityCodeTextField.text = self.address.municipalityCode;
            }

            break;
        }
    }

    cell.textLabel.text = [self localizedExtraFieldTitleForRow:indexPath.row];
    
    [self updateTextField:textField onCell:cell];
    
    return cell;
}


- (UITableViewCell*)numbersCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*  cell;
    NSSortDescriptor* sortDescriptor  = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray*          sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray*          numbersArray    = [self.address.numbers sortedArrayUsingDescriptors:sortDescriptors];
    NumberData*       number          = numbersArray[indexPath.row];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumbersCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"NumbersCell"];
    }

    cell.textLabel.text = number.name;
    cell.accessoryType  = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

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
        [super textFieldShouldBeginEditing:textField];
        if (self.isNew || self.isUpdatable)
        {
            textField.enablesReturnKeyAutomatically = NO;
        }
        
        [self updateReturnKeyTypeOfTextField:textField];
        
        self.activeCellIndexPath = [self findCellIndexPathForSubview:textField];

        if (textField == self.idNumberTextField)
        {
            if (self.idType.value == IdTypeValueNone)
            {
                NSString* title;
                NSString* message;
                NSString* button;

                title   = NSLocalizedStringWithDefaultValue(@"Address ShowFieldRuleTitle", nil, [NSBundle mainBundle],
                                                            @"Select ID Type",
                                                            @"...");
                message = NSLocalizedStringWithDefaultValue(@"Address ShowFieldRuleMessage", nil, [NSBundle mainBundle],
                                                            @"To show you the ID Number format, please first select "
                                                            @"the ID Type.",
                                                            @"....\n"
                                                            @"[iOS alert message size]");
                button  = NSLocalizedStringWithDefaultValue(@"Address ShowFieldRuleTitle", nil, [NSBundle mainBundle],
                                                            @"Select",
                                                            @"...");

                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                {
                    if (buttonIndex == 1)
                    {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                        {
                            UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:self.idTypeIndexPath];
                            [self showIdTypesViewControllerWithCell:cell];
                        });
                    }
                }
                                     cancelButtonTitle:[Strings cancelString]
                                     otherButtonTitles:button, nil];
            }
            else
            {
                [self showIdNumberRule:self.idType.localizedRule];
            }
        }
        else if (textField == self.fiscalIdCodeTextField)
        {
            IdType* idType = [[IdType alloc] initWithValue:IdTypeValueFiscalIdCode];
            [self showIdNumberRule:idType.localizedRule];
        }
        else if (textField == self.streetCodeTextField)
        {
            [self showStreetCodeRule];
        }

        return YES;
    }
}


- (void)showIdNumberRule:(NSString*)localizedRule
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"Address ShowFieldRuleTitle", nil, [NSBundle mainBundle],
                                                @"ID Number Format",
                                                @"...");
    message = NSLocalizedStringWithDefaultValue(@"Address ShowFieldRuleMessage", nil, [NSBundle mainBundle],
                                                @"%@",
                                                @"....\n"
                                                @"[iOS alert message size]");
    message = [NSString stringWithFormat:message, localizedRule];

    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:nil
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


- (void)showStreetCodeRule
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"Address ShowFieldRuleTitle", nil, [NSBundle mainBundle],
                                                @"Street Code Format",
                                                @"...");
    message = NSLocalizedStringWithDefaultValue(@"Address ShowFieldRuleMessage", nil, [NSBundle mainBundle],
                                                @"The 1 to 4 digits street code of the entered address.\n\n"
                                                @"(This is a Denmark specific code; it's not the building number.)",
                                                @"....\n"
                                                @"[iOS alert message size]");

    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:nil
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
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
        self.address.name = @"";
    }
    else
    {
        [self.address setValue:@"" forKey:key];
    }
    
    [self update];
    
    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if (self.isUpdatable == YES && [self isAddressComplete] == YES)
    {
        return [super textFieldShouldReturn:textField];
    }
    
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
            
            nextTextField = (UITextField*)[cell.contentView viewWithTag:CommonTextFieldCellTag];
            [nextTextField becomeFirstResponder];
        }
        else
        {
            [self.tableView scrollToRowAtIndexPath:self.nextIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        }
        
        return NO;
    }
}


- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    NSString* key = objc_getAssociatedObject(textField, @"TextFieldKey");
    
    // See http://stackoverflow.com/a/14792880/1971013 for keeping cursor on correct position.
    UITextPosition* beginning    = textField.beginningOfDocument;
    UITextPosition* start        = [textField positionFromPosition:beginning offset:range.location];
    NSInteger       cursorOffset = [textField offsetFromPosition:beginning toPosition:start] + string.length;
    
    // See http://stackoverflow.com/a/22211018/1971013 why we're using non-breaking spaces @"\u00a0".
    textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    textField.text = [textField.text stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
    
    NSString* text = [textField.text stringByReplacingOccurrencesOfString:@"\u00a0" withString:@" "];
    if ([key isEqualToString:@"name"])
    {
        self.address.name = text;
    }
    else
    {
        [self.address setValue:text forKey:key];
    }
    
    [self updateReturnKeyTypeOfTextField:textField];
    
    [self.tableView scrollToRowAtIndexPath:self.activeCellIndexPath
                          atScrollPosition:UITableViewScrollPositionNone
                                  animated:YES];
    
    // See http://stackoverflow.com/a/14792880/1971013 for keeping cursor on correct position.
    UITextPosition* newCursorPosition = [textField positionFromPosition:textField.beginningOfDocument offset:cursorOffset];
    UITextRange*    newSelectedRange  = [textField textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
    [textField setSelectedTextRange:newSelectedRange];

    [self update];
    
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
        
        nextTextField = (UITextField*)[cell.contentView viewWithTag:CommonTextFieldCellTag];
        [nextTextField becomeFirstResponder];
    }
}


#pragma mark - Actions 

- (void)createAction
{
    self.navigationItem.rightBarButtonItem.enabled = NO;

    self.isLoading = YES;
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
                                                    areaCode:self.address.areaCode
                                                addressProof:self.address.addressProof
                                               identityProof:self.address.identityProof
                                                 nationality:self.address.nationality
                                                      idType:self.address.idType
                                                    idNumber:self.address.idNumber
                                                fiscalIdCode:self.address.fiscalIdCode
                                                  streetCode:self.address.streetCode
                                            municipalityCode:self.address.municipalityCode
                                                       reply:^(NSError*  error,
                                                               NSString* uuid,
                                                               NSString* addressStatus,
                                                               NSArray*  missingFields)
    {
        self.isLoading = NO;

        if (error == nil)
        {
            self.address.uuid          = uuid;
            self.address.addressStatus = [AddressStatus addressStatusMaskForString:addressStatus];

            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];

            self.createCompletion ? self.createCompletion(self.address) : 0;
        }
        else
        {
            NSString* title = NSLocalizedString(@"%@ Not Created", @"");
            title = [NSString stringWithFormat:title, [Strings addressString]];
            [self showSaveError:error title:title itemName:[Strings addressString] completion:nil];

            self.createCompletion ? self.createCompletion(nil) : 0;
        }
    }];

    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)saveAction
{
    self.isLoading = YES;
    [[WebClient sharedClient] updateAddressWithUuid:self.address.uuid
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
                                             idType:self.address.idType
                                           idNumber:self.address.idNumber
                                       fiscalIdCode:self.address.fiscalIdCode
                                         streetCode:self.address.streetCode
                                   municipalityCode:self.address.municipalityCode
                                              reply:^(NSError *error)
    {
        self.isLoading = NO;

        if (error == nil)
        {
            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];

            [self.view endEditing:YES];
            if (self.isNew == YES || self.isUpdatable == YES)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
        else
        {
            [self.address.managedObjectContext refreshObject:self.address mergeChanges:NO];
            [self showSaveError:error title:nil itemName:[Strings addressString] completion:^
            {
                [Common reloadSections:self.sections allSections:self.sections tableView:self.tableView];
                [self update];
            }];
        }
    }];
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
                 
                [self.address deleteWithCompletion:^(BOOL succeeded)
                {
                    if (succeeded)
                    {
                        [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
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
        message = NSLocalizedStringWithDefaultValue(@"AddressView CantDeleteMessage", nil, [NSBundle mainBundle],
                                                    @"This Address can't be deleted because it's used for one or more "
                                                    @"Numbers.",
                                                    @"...\n"
                                                    @"[1/3 line small font].");
        
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
}


#pragma mark - Baseclass Override

- (void)save
{
    if (self.isNew == NO && self.isDeleting == NO && self.address.changedValues.count > 0)
    {
        [self saveAction];
    }
}


- (void)update
{
    if (self.rowsExtraFields & TableRowExtraFieldsIdNumber)
    {
        if ([self.idType isValidWithIdString:self.address.idNumber])
        {
            self.idNumberTextField.textColor = [Skinning tintColor];
        }
        else
        {
            self.idNumberTextField.textColor = [Skinning deleteTintColor];
        }
    }

    if (self.rowsExtraFields & TableRowExtraFieldsFiscalIdCode)
    {
        IdType* idType = [[IdType alloc] initWithValue:IdTypeValueFiscalIdCode];

        if ([idType isValidWithIdString:self.address.fiscalIdCode])
        {
            self.fiscalIdCodeTextField.textColor = [Skinning tintColor];
        }
        else
        {
            self.fiscalIdCodeTextField.textColor = [Skinning deleteTintColor];
        }
    }

    if (self.rowsExtraFields & TableRowExtraFieldsMunicipalityCode)
    {
        if ([self isValidStreetCode:self.address.streetCode])
        {
            self.streetCodeTextField.textColor = [Skinning tintColor];
        }
        else
        {
            self.streetCodeTextField.textColor = [Skinning deleteTintColor];
        }
    }

    [self updateSaveBarButtonItem];
}

@end
