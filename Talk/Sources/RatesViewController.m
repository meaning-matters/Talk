//
//  RatesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 01/06/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import "RatesViewController.h"
#import "Common.h"
#import "Settings.h"
#import "PhoneNumber.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "CallRatesViewController.h"
#import "NumberRatesViewController.h"

typedef enum
{
    TableSectionCallRates   = 1UL << 0,
    TableSectionNumberRates = 1UL << 1,
} TableSection;


@interface RatesViewController ()

@property (nonatomic, assign) TableSection sections;
@property (nonatomic, strong) PhoneNumber* callbackPhoneNumber;

@end


@implementation RatesViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedString(@"Rates", @"Rates tab title");
        // The tabBarItem image must be set in my own NavigationController.

        self.sections |= TableSectionCallRates;
    }

    return self;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:self.sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionCallRates:
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"RatesCell"];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"RatesCell"];
            }

            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Credit Rates", nil, [NSBundle mainBundle],
                                                                    @"Call Rates",
                                                                    @".\n"
                                                                    @"[1 line, abbreviated: Rates].");
            break;
        }
        case TableSectionNumberRates:
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"RatesCell"];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"RatesCell"];
            }

            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Number Rates", nil, [NSBundle mainBundle],
                                                                    @"Number Rates",
                                                                    @".\n"
                                                                    @"[1 line, abbreviated: Rates].");
            break;
        }
    }

    return cell;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title;

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionCallRates:
        {
            title = NSLocalizedStringWithDefaultValue(@"creditView:... CallRatesHeader", nil, [NSBundle mainBundle],
                                                      @"Best Prices You Pay Per Minute",
                                                      @"[One line larger font]");
            break;
        }
        case TableSectionNumberRates:
        {
            title = NSLocalizedStringWithDefaultValue(@"creditView:... NumberRatesHeader", nil, [NSBundle mainBundle],
                                                      @"Number Rates",
                                                      @"[One line larger font]");
            break;
        }
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title;

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionCallRates:
        {
            title = NSLocalizedStringWithDefaultValue(@"Call Rates:... TableFooter", nil, [NSBundle mainBundle],
                                                      @"There are thousands of call rates. To keep things simple, "
                                                      @"only the best prices are shown. These are very close to what "
                                                      @"you'll pay most of the time, but there are exceptions. "
                                                      @"See the Credit section on the Help tab for more info.\n\n"
                                                      @"(The actual price for calling a number is shown on the Dialer, "
                                                      @"and when you make a call.)",
                                                      @"[Multiple lines]");
            break;
        }
        case TableSectionNumberRates:
        {
            title = NSLocalizedStringWithDefaultValue(@"NumberRates:... TableFooter", nil, [NSBundle mainBundle],
                                                      @".....",
                                                      @"[Multiple lines]");
            break;
        }
    }

    return title;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionCallRates:
        {
            if ([Settings sharedSettings].callbackE164.length > 0)
            {
                CallRatesViewController* viewController;
                PhoneNumber*             phoneNumber;

                phoneNumber    = [[PhoneNumber alloc] initWithNumber:[Settings sharedSettings].callbackE164];
                viewController = [[CallRatesViewController alloc] initWithCallbackPhoneNumber:phoneNumber];
                [self.navigationController pushViewController:viewController animated:YES];
            }
            else
            {
                [Common aksForCallbackPhoneNumber:self.callbackPhoneNumber
                                       completion:^(BOOL cancelled, PhoneNumber* phoneNumber)
                {
                    self.callbackPhoneNumber = phoneNumber;

                    if (cancelled == NO && phoneNumber.isValid)
                    {
                        CallRatesViewController* viewController;

                        viewController = [[CallRatesViewController alloc] initWithCallbackPhoneNumber:phoneNumber];
                        [self.navigationController pushViewController:viewController animated:YES];
                    }
                    else
                    {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                    }
                }];
            }
            break;
        }
        case TableSectionNumberRates:
        {
            NumberRatesViewController* viewController;

            viewController = [[NumberRatesViewController alloc] init];
            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
    }
}

@end
