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


@interface CountriesViewController ()
{
    UITableViewCell* selectedCell;
}

@property (nonatomic, strong) NSString* isoCountryCode;
@property (nonatomic, copy) void (^completion)(BOOL cancelled, NSString* isoCountryCode);

@end


@implementation CountriesViewController

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                                 title:(NSString*)title
                            completion:(void (^)(BOOL cancelled, NSString* isoCountryCode))completion;
{
    if (self = [super init])
    {
        self.tableView.dataSource = self;
        self.tableView.delegate   = self;

        self.title                = title;

        self.objectsArray         = [[CountryNames sharedNames].namesDictionary allValues];
        self.isoCountryCode       = isoCountryCode;
        self.completion           = completion;
    }

    return self;
}


- (void)cancel
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
                                                                     action:@selector(cancel)];
        self.navigationItem.rightBarButtonItem = cancelButton;
    }
}


#pragma mark - Base Class Override

- (NSString*)nameForObject:(id)object
{
    return object;
}


- (NSString*)selectedName
{
    return [[CountryNames sharedNames] nameForIsoCountryCode:self.isoCountryCode];
}


#pragma mark - Table View Delegates

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString*        name = [self nameOnTable:tableView atIndexPath:indexPath];

    selectedCell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    selectedCell = cell;

    if (self.isModal == YES)
    {
        // Shown as modal.
        [self dismissViewControllerAnimated:YES completion:^
        {
            self.completion ? self.completion(NO, [[CountryNames sharedNames] isoCountryCodeForName:name]) : 0;
        }];
    }
    else
    {
        self.completion ? self.completion(NO, [[CountryNames sharedNames] isoCountryCodeForName:name]) : 0;

        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        name           = [self nameOnTable:tableView atIndexPath:indexPath];
    NSString*        isoCountryCode = [[CountryNames sharedNames] isoCountryCodeForName:name];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    cell.imageView.image = [UIImage imageNamed:isoCountryCode];
    cell.textLabel.text = name;

    if ([isoCountryCode isEqualToString:self.isoCountryCode])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        selectedCell = cell;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

@end
