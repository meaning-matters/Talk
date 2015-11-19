//
//  AddressViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 16/11/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "AddressViewController.h"
#import "Strings.h"

typedef enum
{
    TableSectionName    = 1UL << 0, // Name given by user.
    TableSectionDetails = 1UL << 1, // Salutation, company, first, last.
    TableSectionAddress = 1UL << 2, // Street, number, city, zipcode.
} TableSections;


@interface AddressViewController ()

@property (nonatomic, assign) TableSections sections;
@property (nonatomic, assign) BOOL          isNew;

@property (nonatomic, strong) UITextField*  salutationTextField;
@property (nonatomic, strong) UITextField*  companyNameTextField;
@property (nonatomic, strong) UITextField*  companyDescriptionTextField;
@property (nonatomic, strong) UITextField*  firstNameTextField;
@property (nonatomic, strong) UITextField*  lastNameTextField;
@property (nonatomic, strong) UITextField*  cityTextField;
@property (nonatomic, strong) UITextField*  postcodeTextField;
@property (nonatomic, strong) UITextField*  countryTextField;


@property (nonatomic, strong) NSIndexPath*  salutationIndexPath;
@property (nonatomic, strong) NSIndexPath*  companyNameIndexPath;
@property (nonatomic, strong) NSIndexPath*  companyDescriptionIndexPath;
@property (nonatomic, strong) NSIndexPath*  firstNameIndexPath;
@property (nonatomic, strong) NSIndexPath*  lastNameIndexPath;
@property (nonatomic, strong) NSIndexPath*  streetIndexPath;
@property (nonatomic, strong) NSIndexPath*  buildingNumberIndexPath;
@property (nonatomic, strong) NSIndexPath*  buildingLetterIndexPath;
@property (nonatomic, strong) NSIndexPath*  cityIndexPath;
@property (nonatomic, strong) NSIndexPath*  postcodeIndexPath;
@property (nonatomic, strong) NSIndexPath*  countryIndexPath;
@property (nonatomic, strong) NSIndexPath*  actionIndexPath;

@property (nonatomic, strong) NSIndexPath*  nextIndexPath;      // Index-path of cell to show after Next button is tapped.

// Keyboard stuff.
@property (nonatomic, assign) BOOL          keyboardShown;
@property (nonatomic, assign) CGFloat       keyboardOverlap;
@property (nonatomic, strong) NSIndexPath*  activeCellIndexPath;

@end


@implementation AddressViewController

- (instancetype)initWithAddress:(AddressData*)address
           managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super initWithManagedObjectContext:managedObjectContext])
    {
        self.sections             = TableSectionName | TableSectionDetails | TableSectionAddress;
        self.isNew                = (address == nil);
        self.address              = address;
        self.managedObjectContext = managedObjectContext;
        self.title                = self.isNew ? [Strings newAddressString] : [Strings addressesString];
        
        self.name                 = address.isoCountryCode;
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;
    
    if (self.isNew)
    {
        UIBarButtonItem* buttonItem;
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
        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                   target:self
                                                                   action:@selector(deleteAction)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }
    
    [self updateRightBarButtonItem];
}


#pragma mark - Helpers

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)updateRightBarButtonItem
{
    if (self.isNew == YES)
    {
        BOOL valid = [self.name stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0;
        
        self.navigationItem.rightBarButtonItem.enabled = valid;
    }
}

@end
