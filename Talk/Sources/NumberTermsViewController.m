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
@property (nonatomic, assign) NumberTerms rows;

@end


@implementation NumberTermsViewController

- (instancetype)initWithAgreed:(BOOL)agreed agreedCompletion:(void (^)(void))completion
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        _completion  = [completion copy];
        _rows        = NumberTermPersonal | NumberTermSerious | NumberTermNoTelemarketing | NumberTermNoUnlawful | NumberTermAddressUpdate;
        _agreedTerms = agreed ? _rows : 0;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupFootnotesHandlingOnTableView:self.tableView];

    if (!self.agreedTerms)
    {
        UIButton* button         = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        UIImage*  normalImage    = [Common maskedImageNamed:@"Checkmark" color:[Skinning tintColor]];
        UIImage*  highlightImage = [Common maskedImageNamed:@"Checkmark" color:[Skinning placeholderColor]];

        [button setImage:normalImage    forState:UIControlStateNormal];
        [button setImage:highlightImage forState:UIControlStateHighlighted];

        button.imageEdgeInsets       = UIEdgeInsetsMake(10, 20, 10, 0);
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;

        [button addTarget:self action:@selector(agreeAllAction) forControlEvents:UIControlEventAllEvents];

        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
}


- (void)agreeAllAction
{
    self.agreedTerms = self.rows;

    [self.tableView reloadData];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.333 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
    {
        self.completion();

        [self.navigationController popViewControllerAnimated:YES];
    });
}


#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [Common bitsSetCount:self.rows];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }

    BOOL selected;
    switch ([Common nthBitSet:indexPath.row inValue:self.rows])
    {
        case NumberTermPersonal:
        {
            selected = (self.agreedTerms & NumberTermPersonal);
            cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                          @"Use Personally",
                                                                          @"...");
            cell.detailTextLabel.text = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                          @"Not for automated systems. Also, don't "
                                                                          @"buy a Number for a third party.",
                                                                          @"...");
            break;
        }
        case NumberTermSerious:
        {
            selected = (self.agreedTerms & NumberTermSerious);
            cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                          @"Use Respectfully",
                                                                          @"...");
            cell.detailTextLabel.text = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                          @"Don't use a Number for pranks, bullying "
                                                                          @"people, or anything malicious.",
                                                                          @"...");
            break;
        }
        case NumberTermNoTelemarketing:
        {
            selected = (self.agreedTerms & NumberTermNoTelemarketing);
            cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                          @"Normal Scale",
                                                                          @"...");
            cell.detailTextLabel.text = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                          @"Large scale use for telemarketing, call "
                                                                          @"centres, or similar, is not allowed.",
                                                                          @"...");
            break;
        }
        case NumberTermNoUnlawful:
        {
            selected = (self.agreedTerms & NumberTermNoUnlawful);
            cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                          @"Use Lawfully",
                                                                          @"...");
            cell.detailTextLabel.text = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                          @"It's forbidden to use a Number for any "
                                                                          @"unlawful purpose whatsoever.",
                                                                          @"...");
            break;
        }
        case NumberTermAddressUpdate:
        {
            selected = (self.agreedTerms & NumberTermAddressUpdate);
            cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                          @"Update Information",
                                                                          @"...");
            cell.detailTextLabel.text = NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                                                          @"When you move or get a new ID, update your "
                                                                          @"information within 2 weeks.",
                                                                          @"...");
            break;
        }
    }

    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.tintColor     = selected ? [Skinning tintColor] : [UIColor colorWithWhite:0.9 alpha:1.0];

    return cell;
}


- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                             @"How To Use A Number",
                                             @"...");
}


- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return NSLocalizedStringWithDefaultValue(@"Terms", nil, [NSBundle mainBundle],
                                             @"The above is a reminder of important rules from the Terms and Conditions, "
                                             @"which you agreed to when becoming a NumberBay insider. They can be found "
                                             @"via the About tab.\n\nWe'll have to suspend the account of anyone "
                                             @"breaking any of the rules.",
                                             @"...");
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

    cell.tintColor = [Skinning tintColor];

    self.agreedTerms |= (1UL << indexPath.row);

    if (self.agreedTerms == self.rows)
    {
        self.completion();

        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90.0;
}

@end
