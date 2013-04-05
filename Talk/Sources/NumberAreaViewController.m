//
//  NumberAreaViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 11/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberAreaViewController.h"
#import "CommonStrings.h"
#import "WebClient.h"
#import "BlockAlertView.h"


typedef enum
{
    TableSectionName,           // Salutation, irst, last, company.
    TalbeSectionAddress,        // Street, number, city, zipcode.
    TableSectionCountry,
    TableSectionState,          // Optional.
    TableSectionArea,
    TableSectionAction,         // Check or buy.
    TableSectionNumber          // Number of table sections.
} TableSections;


@interface NumberAreaViewController ()
{
    NSDictionary*           country;
    NSDictionary*           state;
    NSDictionary*           area;
    NSMutableDictionary*    info;
    BOOL                    requireInfo;
    BOOL                    isChecked;
}

@end


@implementation NumberAreaViewController

- (id)initWithCountry:(NSDictionary*)theCountry state:(NSDictionary*)theState area:(NSDictionary*)theArea
{    
    if (self = [super initWithNibName:@"NumberAreaView" bundle:nil])
    {
        country     = theCountry;
        state       = theState;
        area        = theArea;
        info        = [NSMutableDictionary dictionary];
        requireInfo = [area[@"requireInfo"] boolValue];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = [CommonStrings loadingString];

    UIBarButtonItem*    cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    if (requireInfo)
    {
        [[WebClient sharedClient] retrieveNumberAreaInfoForIsoCountryCode:country[@"isoCountryCode"]
                                                                 areaCode:area[@"areaCode"]
                                                                    reply:^(WebClientStatus status, id content)
        {
            if (status == WebClientStatusOk)
            {
                self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberArea ScreenTitle", nil,
                                                                              [NSBundle mainBundle], @"Area",
                                                                              @"Title of app screen with one area.\n"
                                                                              @"[1 line larger font].");
                info = [NSMutableArray arrayWithArray:content];
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
    else
    {
        self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberArea ScreenTitle", nil,
                                                                      [NSBundle mainBundle], @"Area",
                                                                      @"Title of app screen with one area.\n"
                                                                      @"[1 line larger font].");
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[WebClient sharedClient] cancelAllRetrieveAreaInfoForIsoCountryCode:country[@"isoCountryCode"]
                                                                areaCode:area[@"areaCode"]];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Helper Methods

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}




#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return TableSectionNumber;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch (section)
    {
        case TableSectionName:
            if (requireInfo)
            {
                title = NSLocalizedStringWithDefaultValue(@"NumberArea:Name SectionHeader", nil,
                                                          [NSBundle mainBundle], @"Name",
                                                          @"Name and company of someone.");
            }
            break;

        case TalbeSectionAddress:
            if (requireInfo)
            {
                title = NSLocalizedStringWithDefaultValue(@"NumberArea:Address SectionHeader", nil,
                                                          [NSBundle mainBundle], @"Address",
                                                          @"Address of someone.");
            }
            break;

        case TableSectionCountry:
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Country SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Country",
                                                      @"Country.");
            break;

        case TableSectionState:
            if (state != nil)
            {
                title = NSLocalizedStringWithDefaultValue(@"NumberArea:State SectionHeader", nil,
                                                          [NSBundle mainBundle], @"State",
                                                          @"State in country.");
            }
            break;

        case TableSectionArea:
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Area SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Area",
                                                      @"Telephone area (or city).");
            break;

        case TableSectionAction:
            break;
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch (section)
    {
        case TableSectionName:
            break;

        case TalbeSectionAddress:
            if (requireInfo)
            {
                title = NSLocalizedStringWithDefaultValue(@"NumberArea:Address SectionFooter", nil,
                                                          [NSBundle mainBundle],
                                                          @"For this area name and address information is required.",
                                                          @"Explaining that information must be supplied by user.");
            }
            break;

        case TableSectionCountry:
            break;

        case TableSectionState:
            break;

        case TableSectionArea:
            break;

        case TableSectionAction:
            if (isChecked == NO)
            {
                title = NSLocalizedStringWithDefaultValue(@"NumberArea:Action SectionFooter", nil,
                                                          [NSBundle mainBundle],
                                                          @"The information supplied must first be checked.",
                                                          @"Telephone area (or city).");
            }
            break;
    }

    return title;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger   numberOfRows = 0;

    switch (section)
    {
        case TableSectionName:
            numberOfRows = requireInfo ? 4 : 0;
            break;

        case TalbeSectionAddress:
            numberOfRows = requireInfo ? 4 : 0;
            break;

        case TableSectionCountry:
            numberOfRows = 1;
            break;

        case TableSectionState:
            numberOfRows = (state != nil) ? 1 : 0;
            break;

        case TableSectionArea:
            numberOfRows = 1;
            break;

        case TableSectionAction:
            numberOfRows = 1;
            break;
    }

    return numberOfRows;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.tableView cellForRowAtIndexPath:indexPath].selectionStyle == UITableViewCellSelectionStyleNone)
    {
        return;
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    switch (indexPath.section)
    {
        case TableSectionName:
            cell = [self nameCellForRowAtIndexPath:indexPath];
            break;

        case TalbeSectionAddress:
            cell = [self addressCellForRowAtIndexPath:indexPath];
            break;
            
        case TableSectionCountry:
            cell = [self countryCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionState:
            cell = [self stateCellForRowAtIndexPath:indexPath];
            break;
            
        case TableSectionArea:
            cell = [self areaCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionAction:
            cell = [self actionCellForRowAtIndexPath:indexPath];
            break;
    }

    return cell;
}


- (UITableViewCell*)nameCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    cell.imageView.image = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)addressCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    cell.imageView.image = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)countryCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    cell.imageView.image = [UIImage imageNamed:country[@"isoCountryCode"]];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)stateCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    cell.imageView.image = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)areaCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    cell.imageView.image = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)actionCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    cell.imageView.image = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

@end
