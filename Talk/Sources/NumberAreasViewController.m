//
//  NumberAreasViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 09/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberAreasViewController.h"
#import "NumberType.h"
#import "WebClient.h"
#import "CountryNames.h"
#import "BlockAlertView.h"
#import "CommonStrings.h"


@interface NumberAreasViewController ()
{
    NSDictionary*           country;
    NSString*               stateId;

    NSArray*                nameIndexArray;         // Array with all first letters of country names.
    NSMutableDictionary*    nameIndexDictionary;    // Dictionary with entry (containing array of names) per letter.
    NSMutableArray*         filteredNamesArray;

    NSMutableArray*         areasArray;
    BOOL                    isFiltered;
}

@end


@implementation NumberAreasViewController

- (id)initWithCountry:(NSDictionary*)theCountry stateId:(NSString*)theStateId
{
    ;
    if (self = [super initWithNibName:@"NumberAreaView" bundle:nil])
    {
        country = theCountry;
        stateId = theStateId;   // Is nil for country without states.
    }

    return self;
}


- (void)cancel
{
    //[[WebClient sharedClient] cancelAllRetrieveNumberAreas];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem*    cancelButton;

    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberCountries:Loading ScreenTitle", nil,
                                                                  [NSBundle mainBundle], @"Loading Countries...",
                                                                  @"Title of app screen with list of countries, "
                                                                  @"while loading.\n"
                                                                  @"[1 line larger font - abbreviated 'Loading...'].");

    [[WebClient sharedClient] retrieveNumberCountries:^(WebClientStatus status, id content)
    {
        if (status == WebClientStatusOk)
        {
            self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberCountries:Done ScreenTitle", nil,
                                                                          [NSBundle mainBundle], @"Countries",
                                                                          @"Title of app screen with list of countries.\n"
                                                                          @"[1 line larger font - abbreviated 'Countries'].");

            // Combine number types per area.
            for (NSDictionary* newCountry in (NSArray*)content)
            {
                NSMutableDictionary*    matchedCountry = nil;
                for (NSMutableDictionary* country in areasArray)
                {
                    if ([newCountry[@"isoCode"] isEqualToString:country[@"isoCode"]])
                    {
                        matchedCountry = country;
                        break;
                    }
                }

                if (matchedCountry == nil)
                {
                    matchedCountry = [NSMutableDictionary dictionaryWithDictionary:newCountry];
                    matchedCountry[@"types"] = @(0);
                    [areasArray addObject:matchedCountry];
                }

                if ([matchedCountry[@"type"] isEqualToString:@"GEOGRAPHIC"])
                {
                    matchedCountry[@"types"] = @([matchedCountry[@"types"] intValue] | NumberTypeGeographicMask);
                }
                else if ([matchedCountry[@"type"] isEqualToString:@"TOLLFREE"])
                {
                    matchedCountry[@"types"] = @([matchedCountry[@"types"] intValue] | NumberTypeTollFreeMask);
                }
                else if ([matchedCountry[@"type"] isEqualToString:@"NATIONAL"])
                {
                    matchedCountry[@"types"] = @([matchedCountry[@"types"] intValue] | NumberTypeNationalMask);
                }
            }

            // Create indexes.
            nameIndexDictionary = [NSMutableDictionary dictionary];
            for (NSMutableDictionary* country in areasArray)
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
            if (isFiltered)
            {
                [self searchBar:self.searchDisplayController.searchBar
                  textDidChange:self.searchDisplayController.searchBar.text];

                [self.searchDisplayController.searchResultsTableView reloadData];
            }
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

@end
