//
//  CountriesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 12/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import "CountriesViewController.h"
#import "CountryNames.h"
#import "NSObject+Blocks.h"
#import "Strings.h"
#import "Common.h"
#import "BlockAlertView.h"


@interface CountriesViewController ()

@property (nonatomic, strong) UITableViewCell* selectedCell;
@property (nonatomic, strong) NSString*        isoCountryCode;
@property (nonatomic, strong) NSString*        excludedIsoCountryCode;
@property (nonatomic, copy) void (^completion)(BOOL cancelled, NSString* isoCountryCode);

@end


@implementation CountriesViewController

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                                 title:(NSString*)title
                            completion:(void (^)(BOOL cancelled, NSString* isoCountryCode))completion
{
    return [self initWithIsoCountryCode:isoCountryCode
                 excludedIsoCountryCode:nil
                                  title:title
                             completion:completion];
}


- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                excludedIsoCountryCode:(NSString*)excludedIsoCountryCode   // Not allowed for EXTRANATIONAL address type.
                                 title:(NSString*)title
                            completion:(void (^)(BOOL cancelled, NSString* isoCountryCode))completion
{
    if (self = [super init])
    {
        self.tableView.dataSource   = self;
        self.tableView.delegate     = self;

        self.title                  = title;

        self.objectsArray           = [[CountryNames sharedNames].namesDictionary allValues];
        self.isoCountryCode         = isoCountryCode;
        self.excludedIsoCountryCode = excludedIsoCountryCode;
        self.completion             = completion;
    }

    return self;
}


- (void)cancelAction
{
    [self dismissViewControllerAnimated:YES completion:^
    {
        self.completion ? self.completion(YES, nil) : 0;
    }];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self createIndexOfWidth:1];

    if (self.isModal)
    {
        UIBarButtonItem* cancelButton;

        cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                     target:self
                                                                     action:@selector(cancelAction)];
        self.navigationItem.rightBarButtonItem = cancelButton;
    }
}


#pragma mark - Base Class Override

- (NSString*)nameForObject:(id)object
{
    return object;
}


- (id)selectedObject
{
    return [[CountryNames sharedNames] nameForIsoCountryCode:self.isoCountryCode];
}


#pragma mark - Table View Delegates

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell           = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString*        name           = [self nameOnTableView:tableView atIndexPath:indexPath];
    NSString*        isoCountryCode = [[CountryNames sharedNames] isoCountryCodeForName:name];

    if ([isoCountryCode isEqualToString:self.excludedIsoCountryCode])
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"Countries ...", nil, [NSBundle mainBundle],
                                                    @"Country Not Allowed",
                                                    @"...");
        message = NSLocalizedStringWithDefaultValue(@"Countries ...", nil, [NSBundle mainBundle],
                                                    @"Legal requirements dictate that the address "
                                                    @"must be outside the Number's country.",
                                                    @"....\n"
                                                    @"[iOS alert message size]");
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
    else
    {
        self.selectedCell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.selectedCell = cell;

        if (self.isModal == YES)
        {
            // Shown as modal.
            [self dismissViewControllerAnimated:YES completion:^
            {
                self.completion ? self.completion(NO, isoCountryCode) : 0;
            }];
        }
        else
        {
            self.completion ? self.completion(NO, isoCountryCode) : 0;

            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        name           = [self nameOnTableView:tableView atIndexPath:indexPath];
    NSString*        isoCountryCode = [[CountryNames sharedNames] isoCountryCodeForName:name];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    cell.imageView.image = [UIImage imageNamed:isoCountryCode];

    if ([isoCountryCode isEqualToString:self.isoCountryCode])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.selectedCell = cell;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    if ([isoCountryCode isEqualToString:self.excludedIsoCountryCode])
    {
        cell.textLabel.attributedText = [Common strikethroughAttributedString:name];
    }
    else
    {
        cell.textLabel.text = name;
    }

    return cell;
}

@end
