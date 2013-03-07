//
//  NumberStatesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberStatesViewController.h"
#import "CountryNames.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "CommonStrings.h"


@interface NumberStatesViewController ()
{
    NSArray*                nameIndexArray;         // Array with all first letters of country names.
    NSMutableDictionary*    nameIndexDictionary;    // Dictionary with entry (containing array of names) per letter.
    NSMutableArray*         filteredNamesArray;

    NSMutableArray*         countriesArray; //### states...
    BOOL                    isFiltered;
}

@end


@implementation NumberStatesViewController

- (id)init
{
    if (self = [super initWithNibName:@"NumberStatesView" bundle:nil])
    {
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"NumberCountries:Loading ScreenTitle", nil,
                                                                         [NSBundle mainBundle], @"Loading Countries...",
                                                                         @"Title of app screen with list of countries, "
                                                                         @"while loading.\n"
                                                                         @"[1 line larger font - abbreviated 'Loading...'].");

    [[WebClient sharedClient] retrieveNumberCountries:^(WebClientStatus status, id content)
     {
         if (status == WebClientStatusOk)
         {
             self.navigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"NumberCountries:Done ScreenTitle", nil,
                                                                                  [NSBundle mainBundle], @"Available Countries",
                                                                                  @"Title of app screen with list of countries.\n"
                                                                                  @"[1 line larger font - abbreviated 'Countries'].");

             // Combine number types per country.
             for (NSDictionary* newCountry in (NSArray*)content)
             {
                 NSMutableDictionary*    matchedCountry = nil;
                 for (NSMutableDictionary* country in countriesArray)
                 {
                     if ([newCountry[@"isoCode"] isEqualToString:country[@"isoCode"]])
                     {
                         matchedCountry = country;
                         break;
                     }
                 }

                 if (matchedCountry == nil)
                 {
                     NSMutableDictionary* country = [NSMutableDictionary dictionaryWithDictionary:newCountry];
                     country[[country[@"type"] lowercaseString]] = [NSNumber numberWithBool:YES];
                     [countriesArray addObject:country];
                 }
                 else
                 {
                     matchedCountry[[newCountry[@"type"] lowercaseString]] = [NSNumber numberWithBool:YES];
                 }
             }

             // Create indexes.
             nameIndexDictionary = [NSMutableDictionary dictionary];
             for (NSMutableDictionary* country in countriesArray)
             {
                 NSString*       name = [[CountryNames sharedNames] nameForIsoCountryCode:country[@"isoCode"]];
                 NSString*       nameIndex = [name substringToIndex:1];
                 NSMutableArray* indexArray;
                 if ((indexArray = [nameIndexDictionary valueForKey:nameIndex]) != nil)
                 {
                     [indexArray addObject:name];
                 }
                 else
                 {
                     indexArray = [NSMutableArray array];
                     nameIndexDictionary[nameIndex] = indexArray;
                     [indexArray addObject:name];
                 }
             }

             // Sort indexes.
             nameIndexArray = [[nameIndexDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCompare:)];
             for (NSString* nameIndex in nameIndexArray)
             {
                 nameIndexDictionary[nameIndex] = [nameIndexDictionary[nameIndex] sortedArrayUsingSelector:@selector(localizedCompare:)];
             }

             [self.tableView reloadData];
         }
         else if (status == WebClientStatusFailServiceUnavailable)
         {
             NSString*   title;
             NSString*   message;

             title = NSLocalizedStringWithDefaultValue(@"NumberCountries UnavailableAlertTitle", nil,
                                                       [NSBundle mainBundle], @"Service Unavailable",
                                                       @"Alert title telling that loading countries over internet failed.\n"
                                                       @"[iOS alert title size].");
             message = NSLocalizedStringWithDefaultValue(@"NumberCountries UnavailableAlertMessage", nil,
                                                         [NSBundle mainBundle],
                                                         @"The service for buying numbers is temporarily offline."
                                                         @"\n\nPlease try again later.",
                                                         @"Alert message telling that loading countries over internet failed.\n"
                                                         @"[iOS alert message size - use correct iOS terms for: Settings "
                                                         @"and Notifications!]");
             [BlockAlertView showAlertViewWithTitle:title
                                            message:message
                                         completion:^(BOOL cancelled, NSInteger buttonIndex)
              {
                  [self dismissViewControllerAnimated:YES completion:nil];
              }
                                  cancelButtonTitle:[CommonStrings cancelString]
                                  otherButtonTitles:nil];
         }
         else
         {
             NSString*   title;
             NSString*   message;

             title = NSLocalizedStringWithDefaultValue(@"NumberCountries LoadFailAlertTitle", nil,
                                                       [NSBundle mainBundle], @"Loading Failed",
                                                       @"Alert title telling that loading countries over internet failed.\n"
                                                       @"[iOS alert title size].");
             message = NSLocalizedStringWithDefaultValue(@"NumberCountries LoadFailAlertMessage", nil,
                                                         [NSBundle mainBundle],
                                                         @"Loading the list of countries failed.\n\nPlease try again later.",
                                                         @"Alert message telling that loading countries over internet failed.\n"
                                                         @"[iOS alert message size - use correct iOS terms for: Settings "
                                                         @"and Notifications!]");
             [BlockAlertView showAlertViewWithTitle:title
                                            message:message
                                         completion:^(BOOL cancelled, NSInteger buttonIndex)
              {
                  [self dismissViewControllerAnimated:YES completion:nil];
              }
                                  cancelButtonTitle:[CommonStrings cancelString]
                                  otherButtonTitles:nil];
         }
     }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Actions

- (IBAction)cancelAction:(id)sender
{
    // [[WebClient sharedClient] cancelAllRetrieveNumberStates:@"country####"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
