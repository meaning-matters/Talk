//
//  NumberTermsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 03/07/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "NumberTermsViewController.h"
#import "Common.h"
#import "BlockAlertView.h"
#import "Strings.h"

typedef NS_ENUM(NSUInteger, NumberTerms)
{
    NumberTermPersonal        = 1UL << 0,
    NumberTermSerious         = 1UL << 1,   // No pranks.
    NumberTermNoTelemarketing = 1UL << 2,
    NumberTermNoUnlawful      = 1UL << 3,
    NumberTermAddressUpdate   = 1UL << 4,
};

@interface NumberTermsViewController ()

@property (nonatomic, copy) void (^completion)(void);
@property (nonatomic, assign) NumberTerms agreedTerms;
@property (nonatomic, assign) NumberTerms sections;

@end


@implementation NumberTermsViewController

- (instancetype)initWithAgreed:(BOOL)agreed agreedCompletion:(void (^)(void))completion
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        _completion  = [completion copy];
        _sections    = NumberTermPersonal | NumberTermSerious | NumberTermNoTelemarketing | NumberTermNoUnlawful | NumberTermAddressUpdate;
        _agreedTerms = agreed ? _sections : 0;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:self.sections];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell;
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    BOOL selected;
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case NumberTermPersonal:
        {
            selected = (self.agreedTerms & NumberTermPersonal);
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                    @"Person-to-person Only",
                                                                    @"...");
            break;
        }
        case NumberTermSerious:
        {
            selected = (self.agreedTerms & NumberTermSerious);
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                    @"Serious Use Only",
                                                                    @"...");
            break;
        }
        case NumberTermNoTelemarketing:
        {
            selected = (self.agreedTerms & NumberTermNoTelemarketing);
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                    @"No Telemarketing",
                                                                    @"...");
            break;
        }
        case NumberTermNoUnlawful:
        {
            selected = (self.agreedTerms & NumberTermNoUnlawful);
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                    @"No Unlawful Use",
                                                                    @"...");
            break;
        }
        case NumberTermAddressUpdate:
        {
            selected = (self.agreedTerms & NumberTermAddressUpdate);
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                    @"Keep Address Up-to-date",
                                                                    @"...");
            break;
        }
    }

    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.tintColor     = selected ? [Skinning tintColor] : [UIColor colorWithWhite:0.9 alpha:1.0];

    return cell;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case NumberTermPersonal:
        {
            title = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                      @"Numbers may not be used for any computer controlled "
                                                      @"telephony services, including calling card services. ",
                                                      @"...");
            break;
        }
        case NumberTermSerious:
        {
            title = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                      @"Number should only be used for serious ...",
                                                      @"...");
            break;
        }
        case NumberTermNoTelemarketing:
        {
            title = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                      @"It's not allowed to use Numbers for telemarketing, "
                                                      @"call centers, or simular applications that involve "
                                                      @"reaching large numbers of people.",
                                                      @"...");
            break;
        }
        case NumberTermNoUnlawful:
        {
            title = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                      @"It's forbidden to use a Number for any unlawful purpose "
                                                      @"whatsoever, including but not limited to the transmission "
                                                      @"of information or the offering of any service which is "
                                                      @"contrary to any applicable law or regulation, abusive, "
                                                      @"harmful, threatening, defamatory, pornographic or which "
                                                      @"could be considered offensive in any other way.",
                                                      @"...");
            break;
        }
        case NumberTermAddressUpdate:
        {
            title = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                      @"When you move, you'll make sure to submit your new address "
                                                      @"used for this Number within 1 week.",
                                                      @"...");
            break;
        }
    }

    return title;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

    cell.tintColor = [Skinning tintColor];

    self.agreedTerms |= (1UL << indexPath.section);

    if (self.agreedTerms == self.sections)
    {
        NSString* title   = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                              @"Agreeing To Terms",
                                                              @"....\n"
                                                              @"[iOS alert title size].");
        NSString* message = NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                              @"Thanks for agreeing to these terms. "
                                                              @"Please be reminded that the full Terms and Conditions "
                                                              @"text can be found from the About tab.\n\n"
                                                              @"Do you understand that we'll have to suspend your "
                                                              @"account when breaking any of these rules?",
                                                              @"....\n"
                                                              @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            if (buttonIndex == 1)
            {
                self.completion();
            }

            [self.navigationController popViewControllerAnimated:YES];
        }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:[Strings yesString], nil];
    }
}

@end
