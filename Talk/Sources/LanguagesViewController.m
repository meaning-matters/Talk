//
//  LanguagesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/04/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "LanguagesViewController.h"
#import "Common.h"
#import "Strings.h"

@interface LanguagesViewController ()

@property (nonatomic, strong) UITableViewCell* selectedCell;
@property (nonatomic, strong) NSArray*         languageCodes;
@property (nonatomic, strong) NSString*        languageCode;
@property (nonatomic, copy) void (^completion)(NSString* languageCode);

@end

@implementation LanguagesViewController

- (instancetype)initWithLanguageCodes:(NSArray*)languageCodes
                         languageCode:(NSString*)languageCode
                           completion:(void (^)( NSString* languageCode))completion
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = [Strings languageString];

        self.languageCodes = languageCodes;
        self.languageCode  = languageCode;
        self.completion    = completion;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.languageCodes.count;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    cell.textLabel.text = [Common languageNameForCode:self.languageCodes[indexPath.row]];

    if ([self.languageCode isEqualToString:self.languageCodes[indexPath.row]])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.selectedCell = cell;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Language in which to hear code", @"");
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];

    self.selectedCell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    self.selectedCell = cell;

    self.completion ? self.completion(self.languageCodes[indexPath.row]) : 0;

    [self.navigationController popViewControllerAnimated:YES];
}

@end
