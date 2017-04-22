//
//  VerifyPhoneVoiceCallViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "VerifyPhoneVoiceCallViewController.h"
#import "Common.h"
#import "WebClient.h"


typedef enum
{
    TableSectionCode = 1UL << 0,
    TableSectionCall = 1UL << 1,
} TableSections;

typedef enum
{
    CallRowLanguage  = 1UL << 0,
    CallRowCallMe    = 1UL << 1,
} CallRows;


@interface VerifyPhoneVoiceCallViewController ()

@property (nonatomic, assign) TableSections sections;
@property (nonatomic, assign) CallRows      callRows;
@property (nonatomic, strong) PhoneNumber*  phoneNumber;
@property (nonatomic, strong) NSString*     uuid;
@property (nonatomic, copy)   void        (^completion)(PhoneNumber* phoneNumber, NSString* uuid);

@end


@implementation VerifyPhoneVoiceCallViewController

- (instancetype)initWithPhoneNumber:(PhoneNumber*)phoneNumber
                         completion:(void (^)(PhoneNumber* verifiedPhoneNumber, NSString* uuid))completion;
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.phoneNumber = phoneNumber;
        self.completion  = completion;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Verify", @"");

    UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self
                                                                                action:@selector(cancelAction)];
    self.navigationItem.rightBarButtonItem = buttonItem;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
}


#pragma mark - TableView Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    self.sections |= TableSectionCode;
    self.sections |= TableSectionCall;

    self.callRows |= CallRowLanguage;
    self.callRows |= CallRowCallMe;

    return [Common bitsSetCount:self.sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionCode: numberOfRows = 1;                                   break;
        case TableSectionCall: numberOfRows = [Common bitsSetCount:self.callRows]; break;
    }

    return numberOfRows;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionCode: cell = [self codeCellForRowAtIndexPath:indexPath]; break;
        case TableSectionCall: cell = [self callCellForRowAtIndexPath:indexPath]; break;
    }

    return cell;
}


#pragma mark - Cell Methods

- (UITableViewCell*)codeCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        identifier;

    identifier  = @"CodeCell";
    cell        = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }

    return cell;
}


- (UITableViewCell*)callCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        identifier;

    identifier  = @"CallCell";
    cell        = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }

    return cell;
}


#pragma mark - Actions

- (void)cancelAction
{
    self.completion = nil;

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
