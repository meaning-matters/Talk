//
//  NumbersViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "NumbersViewController.h"
#import "NumberCountriesViewController.h"
#import "AppDelegate.h"


@interface NumbersViewController ()
{
    NSMutableArray*         numbersArray;
    NSMutableArray*         filteredNumbersArray;
    BOOL                    isFiltered;
}

@end


@implementation NumbersViewController

- (id)init
{
    if (self = [super initWithNibName:@"NumbersView" bundle:nil])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"Numbers:NumbersList ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Numbers",
                                                       @"Title of app screen with list of phone numbers\n"
                                                       @"[1 line larger font].");
        self.tabBarItem.image = [UIImage imageNamed:@"NumbersTab.png"];

        numbersArray = [NSMutableArray array];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(addAction)];

    // Change Search to Done on search keyboard.
    for (UIView* searchBarSubview in [self.searchBar subviews])
    {
        if ([searchBarSubview conformsToProtocol:@protocol(UITextInputTraits)])
        {
            @try
            {
                [(UITextField*)searchBarSubview setReturnKeyType:UIReturnKeyDone];
                [(UITextField*)searchBarSubview setKeyboardAppearance:UIKeyboardAppearanceAlert];
            }
            @catch (NSException* exception)
            {
                // Ignore exception.
            }
        }
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return isFiltered ? filteredNumbersArray.count : numbersArray.count;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSDictionary*       number;

    if (isFiltered)
    {
        number = filteredNumbersArray[indexPath.row];
    }
    else
    {
        number = numbersArray[indexPath.row];
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    [self.navigationController popViewControllerAnimated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NSDictionary*       number;
    NSString*           isoCountryCode;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    if (isFiltered)
    {
        number = filteredNumbersArray[indexPath.row];
    }
    else
    {
        number = numbersArray[indexPath.row];
    }

    isoCountryCode = number[@"isoCountryCode"];

    cell.imageView.image = [UIImage imageNamed:isoCountryCode];
    cell.textLabel.text  = number[@"number"];
    cell.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


#pragma mark - Search Bar Delegate

- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
    if (searchText.length == 0)
    {
        isFiltered = NO;
    }
    else
    {
        isFiltered = YES;
        filteredNumbersArray = [NSMutableArray array];

        for (NSDictionary* number in numbersArray)
        {
            NSRange range = [number[@"something"] rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound)
            {
                [filteredNumbersArray addObject:number];
            }
        }
    }

    [self.tableView reloadData];
}


- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar
{
    [self done];
}


- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar
{
    isFiltered = NO;
    self.searchBar.text = @"";
    [self.tableView reloadData];

    [self enableCancelButton:NO];

    [searchBar performSelector:@selector(resignFirstResponder)
                    withObject:nil
                    afterDelay:0.1];
}


#pragma mark - Scrollview Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)activeScrollView
{
    [self done];
}


#pragma mark - Utility Methods

- (void)done
{
    if ([self.searchBar isFirstResponder])
    {
        [self.searchBar resignFirstResponder];

        [self enableCancelButton:[self.searchBar.text length] > 0];
    }
}


- (void)enableCancelButton:(BOOL)enabled
{
    // Enable search-bar cancel button.
    for (UIView* possibleButton in self.searchBar.subviews)
    {
        if ([possibleButton isKindOfClass:[UIButton class]])
        {
            ((UIButton*)possibleButton).enabled = enabled;
            break;
        }
    }
}


- (void)addAction
{
    NumberCountriesViewController*  numberCountriesViewController;
    
    numberCountriesViewController = [[NumberCountriesViewController alloc] init];
    numberCountriesViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [AppDelegate.appDelegate.tabBarController presentViewController:numberCountriesViewController
                                                           animated:YES
                                                         completion:nil];
}

@end
