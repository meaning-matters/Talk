//
//  IncomingChargesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 02/07/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "IncomingChargesViewController.h"
#import "NumberData.h"
#import "Skinning.h"
#import "Strings.h"
#import "Common.h"
#import "PurchaseManager.h"


@interface IncomingChargesViewController ()

@property (nonatomic, assign) float fixedSetup;
@property (nonatomic, assign) float fixedRate;
@property (nonatomic, assign) float mobileSetup;
@property (nonatomic, assign) float mobileRate;
@property (nonatomic, assign) float payphoneSetup;
@property (nonatomic, assign) float payphoneRate;

@end


@implementation IncomingChargesViewController

- (instancetype)initWithArea:(NSDictionary*)area
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        _fixedSetup    = [area[@"fixedSetup"]    floatValue];
        _fixedRate     = [area[@"fixedRate"]     floatValue];
        _mobileSetup   = [area[@"mobileSetup"]   floatValue];
        _mobileRate    = [area[@"mobileRate"]    floatValue];
        _payphoneSetup = [area[@"payphoneSetup"] floatValue];
        _payphoneRate  = [area[@"payphoneRate"]  floatValue];
    }

    return self;
}


- (instancetype)initWithNumber:(NumberData*)number
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        _fixedSetup    = number.fixedSetup;
        _fixedRate     = number.fixedRate;
        _mobileSetup   = number.mobileSetup;
        _mobileRate    = number.mobileRate;
        _payphoneSetup = number.payphoneSetup;
        _payphoneRate  = number.payphoneRate;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


+ (BOOL)hasIncomingChargesWithArea:(NSDictionary*)area
{
    return [area[@"fixedSetup"]    floatValue] != 0 ||
           [area[@"fixedRate"]     floatValue] != 0 ||
           [area[@"mobileSetup"]   floatValue] != 0 ||
           [area[@"mobileRate"]    floatValue] != 0 ||
           [area[@"payphoneSetup"] floatValue] != 0 ||
           [area[@"payphoneRate"]  floatValue] != 0;
}


+ (BOOL)hasIncomingChargesWithNumber:(NumberData*)number
{
    return number.fixedSetup    != 0 ||
           number.fixedRate     != 0 ||
           number.mobileSetup   != 0 ||
           number.mobileRate    != 0 ||
           number.payphoneSetup != 0 ||
           number.payphoneRate  != 0;
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"DefaultCell"];
    }

    cell.accessoryView             = nil;
    cell.detailTextLabel.textColor = [Skinning valueColor];

    float charge;

    switch (indexPath.row)
    {
        case 0: cell.textLabel.text = [Strings fixedSetupString];    charge = self.fixedSetup;    break;
        case 1: cell.textLabel.text = [Strings fixedRateString];     charge = self.fixedRate;     break;
        case 2: cell.textLabel.text = [Strings mobileSetupString];   charge = self.mobileSetup;   break;
        case 3: cell.textLabel.text = [Strings mobileRateString];    charge = self.mobileRate;    break;
        case 4: cell.textLabel.text = [Strings payphoneSetupString]; charge = self.payphoneSetup; break;
        case 5: cell.textLabel.text = [Strings payphoneRateString];  charge = self.payphoneRate;  break;
    }

    if (charge == 0.0)
    {
        cell.textLabel.attributedText = [Common strikethroughAttributedString:cell.textLabel.text];
    }

    cell.detailTextLabel.text   = [[PurchaseManager sharedManager] localizedFormattedPrice2ExtraDigits:charge];
    cell.userInteractionEnabled = NO; // Must be set last, otherwise setting colors does not work.

    return cell;
}


#pragma mark - Table View Delegate

- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    return NSLocalizedStringWithDefaultValue(@"IncomingCharges SectionFooter", nil, [NSBundle mainBundle],
                                             @"When someone calls you at this Number, the above additional "
                                             @"charges apply, depending on the type of phone used.\n\n"
                                             @"These charges will be taken from your Credit. "
                                             @"The setup fee is taken once for each call, followed by a price "
                                             @"per minute.",
                                             @"....");
}

@end
