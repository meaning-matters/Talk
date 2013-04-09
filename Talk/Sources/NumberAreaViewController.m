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
#import "Common.h"
#import "CountryNames.h"


typedef enum
{
    TableSectionArea    = 1UL << 0, // Type, area code, area name.
    TableSectionNaming  = 1UL << 1, // Name given by user.
    TableSectionName    = 1UL << 2, // Salutation, irst, last, company.
    TableSectionAddress = 1UL << 3, // Street, number, city, zipcode.
    TableSectionAction  = 1UL << 4, // Check info, or Buy.
} TableSections;


const int   TextFieldCellTag = 1234;
const int   CountryCellTag   = 4321;


@interface NumberAreaViewController ()
{
    NSDictionary*           country;
    NSDictionary*           state;
    NSDictionary*           area;
    NumberTypeMask          numberTypeMask;

    NSMutableDictionary*    info;
    BOOL                    requireInfo;
    BOOL                    isChecked;
    TableSections           sections;

    // Editables.
    UITextField*            nameTextField;
    UITextField*            salutationTextField;
    UITextField*            firstNameTextField;
    UITextField*            lastNameTextField;
    UITextField*            companyTextField;
    UITextField*            streetTextField;
    UITextField*            buildingTextField;

    // Keyboard stuff.
    BOOL                    keyboardShown;
    CGFloat                 keyboardOverlap;
    NSIndexPath*            activeCellIndexPath;
}

@end


@implementation NumberAreaViewController

- (id)initWithCountry:(NSDictionary*)theCountry
                state:(NSDictionary*)theState
                 area:(NSDictionary*)theArea
       numberTypeMask:(NumberTypeMask)theNumberTypeMask
{    
    if (self = [super initWithNibName:@"NumberAreaView" bundle:nil])
    {
        country        = theCountry;
        state          = theState;
        area           = theArea;
        numberTypeMask = theNumberTypeMask;
        info           = [NSMutableDictionary dictionary];
        requireInfo    = [area[@"requireInfo"] boolValue];

        // Mandatory sections.
        sections |= TableSectionArea;
        sections |= TableSectionNaming;
        sections |= TableSectionAction;

        // Optional Sections.
        sections |= requireInfo ? TableSectionName    : 0;
        sections |= requireInfo ? TableSectionAddress : 0;
   }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem*    cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    [self addKeyboardNotifications];

    if (requireInfo)
    {
        self.navigationItem.title = [CommonStrings loadingString];
        [self loadData];
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


#pragma mark - Helper Methods

- (void)loadData
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


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (UITextField*)addTextFieldToCell:(UITableViewCell*)cell
{
    UITextField*    textField;
    CGRect          frame = CGRectMake(83, 11, 216, 30);

    textField = [[UITextField alloc] initWithFrame:frame];
    [textField setFont:[UIFont boldSystemFontOfSize:15]];

    textField.returnKeyType          = UIReturnKeyDone;
    textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    textField.delegate               = self;

    [cell.contentView addSubview:textField];

    return textField;
}


- (void)addCountryImageToCell:(UITableViewCell*)cell isoCountryCode:(NSString*)isoCountryCode
{
    UIImage*        image = [UIImage imageNamed:isoCountryCode];
    UIImageView*    imageView = (UIImageView*)[cell viewWithTag:CountryCellTag];
    CGRect          frame = CGRectMake(33, 4, image.size.width, image.size.height);

    imageView = (imageView == nil) ? [[UIImageView alloc] initWithFrame:frame] : imageView;
    imageView.tag = CountryCellTag;
    imageView.image = image;

    [cell.contentView addSubview:imageView];
}


- (NSIndexPath*)findCellIndexPathForSubview:(UIView*)subview
{
    UIView* superview = subview.superview;
    while ([superview class] != [UITableViewCell class])
    {
        superview = superview.superview;
    }

    return [self.tableView indexPathForCell:(UITableViewCell*)superview];
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common countSetBits:sections];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch ([Common getNthSetBit:section inValue:sections])
    {
        case TableSectionArea:
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Area SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Current Selection",
                                                      @"...");
            break;

        case TableSectionNaming:
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Naming SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Enter a Name...",
                                                      @"...");
            break;

        case TableSectionName:
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Name SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Supply Contact Name...",
                                                      @"Name and company of someone.");
            break;

        case TableSectionAddress:
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Address SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Supply Contact Address...",
                                                      @"Address of someone.");
            break;

        case TableSectionAction:
            break;
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch ([Common getNthSetBit:section inValue:sections])
    {
        case TableSectionArea:
            break;

        case TableSectionNaming:
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Naming SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"Give this telephone number a short name that is easy "
                                                      @"to remember.\nCan not be changed afterwards!",
                                                      @"Explaining that user must supply a name.");
            break;

        case TableSectionName:
            break;

        case TableSectionAddress:
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Address SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"For this area name and address information is required.",
                                                      @"Explaining that information must be supplied by user.");
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

    switch ([Common getNthSetBit:section inValue:sections])
    {
        case TableSectionArea:
            numberOfRows = 4 + (state != nil);
            break;

        case TableSectionNaming:
            numberOfRows = 1;
            break;

        case TableSectionName:
            numberOfRows = requireInfo ? 4 : 0;
            break;

        case TableSectionAddress:
            numberOfRows = requireInfo ? 4 : 0;
            break;

        case TableSectionAction:
            numberOfRows = 1;
            break;
    }

    return numberOfRows;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell = [self.tableView cellForRowAtIndexPath:indexPath];
    CGRect          frame = cell.detailTextLabel.frame;

    NSLog(@"%f %f %f %f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    NSLog(@"%@", cell.detailTextLabel.font);

    if ([self.tableView cellForRowAtIndexPath:indexPath].selectionStyle == UITableViewCellSelectionStyleNone)
    {
        return;
    }
    else
    {
        switch ([Common getNthSetBit:indexPath.section inValue:sections])
        {
            case TableSectionAction:
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                break;

            case TableSectionAddress:
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                break;
        }
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    switch ([Common getNthSetBit:indexPath.section inValue:sections])
    {
        case TableSectionArea:
            cell = [self areaCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionNaming:
            cell = [self namingCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionName:
            cell = [self nameCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionAddress:
            cell = [self addressCellForRowAtIndexPath:indexPath];
            break;
            
        case TableSectionAction:
            cell = [self actionCellForRowAtIndexPath:indexPath];
            break;
    }

    return cell;
}


- (UITableViewCell*)areaCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*        cell;
    NSString*               identifier;

    identifier  = (indexPath.row <= 2 + (state != nil)) ? @"Value2Cell" : @"CountryCell";
    cell        = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:identifier];
    }

    switch (indexPath.row)
    {
        case 0:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:NumberType Label", nil,
                                                                    [NSBundle mainBundle], @"Type",
                                                                    @"....");
            cell.detailTextLabel.text = [NumberType numberTypeLocalizedString:numberTypeMask];
            cell.imageView.image = nil;
            break;

        case 1:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:AreaCode Label", nil,
                                                                    [NSBundle mainBundle], @"Area Code",
                                                                    @"....");
            cell.detailTextLabel.text = area[@"areaCode"];
            cell.imageView.image = nil;
            break;

        case 2:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:AreaName Label", nil,
                                                                    [NSBundle mainBundle], @"Area",
                                                                    @"....");
            cell.detailTextLabel.text = area[@"areaName"];
            cell.imageView.image = nil;
            break;

        case 3:
            if (state != nil)
            {
                cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:State Label", nil,
                                                                        [NSBundle mainBundle], @"State",
                                                                        @"....");
                cell.detailTextLabel.text = state[@"stateName"];
                cell.imageView.image = nil;
            }
            else
            {
                cell.textLabel.text = @" "; // Without this, the detailTextLabel is on the left.
                cell.detailTextLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:country[@"isoCountryCode"]];
                [self addCountryImageToCell:cell isoCountryCode:country[@"isoCountryCode"]];
            }
            break;

        case 4:
            cell.textLabel.text = @" ";     // Without this, the detailTextLabel is on the left.
            cell.detailTextLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:country[@"isoCountryCode"]];
            [self addCountryImageToCell:cell isoCountryCode:country[@"isoCountryCode"]];
            break;
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)namingCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    UITextField*        textField;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"TextFieldCell"];
        textField = [self addTextFieldToCell:cell];
        textField.tag = TextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
    }

    cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:Name Label", nil,
                                                            [NSBundle mainBundle], @"Name",
                                                            @"....");
    nameTextField = textField;

    cell.detailTextLabel.text = nil;
    cell.imageView.image = nil;
    cell.accessoryType   = UITableViewCellAccessoryNone;
    cell.selectionStyle  = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)nameCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    UITextField*        textField;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"TextFieldCell"];
        textField = [self addTextFieldToCell:cell];
        textField.tag = TextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
    }

    switch (indexPath.row)
    {
        case 0:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:Salutation Label", nil,
                                                                    [NSBundle mainBundle], @"Title",
                                                                    @"....");
            salutationTextField = textField;
            break;

        case 1:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:FirstName Label", nil,
                                                                    [NSBundle mainBundle], @"Firstname",
                                                                    @"....");
            firstNameTextField = textField;
            break;

        case 2:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:LastName Label", nil,
                                                                    [NSBundle mainBundle], @"Lastname",
                                                                    @"....");
            lastNameTextField = textField;
            break;

        case 3:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:Company Label", nil,
                                                                    [NSBundle mainBundle], @"Company",
                                                                    @"....");
            companyTextField = textField;
            break;
    }

    cell.detailTextLabel.text = nil;
    cell.imageView.image = nil;
    cell.accessoryType   = UITableViewCellAccessoryNone;
    cell.selectionStyle  = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)addressCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NSString*           identifier = (indexPath.row <= 1) ? @"TextFieldCell" : @"Value2Cell";
    UITextField*        textField;

    cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:identifier];
        textField = [self addTextFieldToCell:cell];
        textField.tag = TextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell.contentView viewWithTag:TextFieldCellTag];
    }

    switch (indexPath.row)
    {
        case 0:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:Street Label", nil,
                                                                    [NSBundle mainBundle], @"Street",
                                                                    @"....");
            cell.detailTextLabel.text = nil;
            streetTextField = textField;
            cell.accessoryType  = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;

        case 1:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:Building Label", nil,
                                                                    [NSBundle mainBundle], @"Building",
                                                                    @"....");
            cell.detailTextLabel.text = nil;
            buildingTextField = textField;
            cell.accessoryType  = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;

        case 2:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:ZipCode Label", nil,
                                                                    [NSBundle mainBundle], @"ZIP Code",
                                                                    @"Postalcode, Post Code, ...");
            
            cell.detailTextLabel.text = nil;
            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            break;

        case 3:
            cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"NumberArea:City Label", nil,
                                                                    [NSBundle mainBundle], @"City",
                                                                    @"....");
            cell.detailTextLabel.text = nil;
            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            break;
    }

    cell.imageView.image = nil;

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
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;

    return cell;
}


#pragma mark - TextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
    activeCellIndexPath = [self findCellIndexPathForSubview:textField];
    return YES;
}


- (BOOL)textFieldShouldClear:(UITextField*)textField
{
#warning Is never invoked for name field, fix!
    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - Keyboard Handling
// http://stackoverflow.com/questions/13845426/generic-uitableview-keyboard-resizing-algorithm

- (void)addKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}


- (void)keyboardWillShow:(NSNotification*)notification
{
    if (keyboardShown == YES)
    {
        return;
    }
    else
    {
        keyboardShown = YES;
    }

    // Get keyboard size.
    NSDictionary*   userInfo = [notification userInfo];
    NSValue*        value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect          keyboardRect = [self.tableView.superview convertRect:[value CGRectValue] fromView:nil];

    // Get the keyboard's animation details.
    NSTimeInterval  animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];

    // Determine how much overlap exists between tableView and the keyboard
    CGRect tableFrame = self.tableView.frame;
    CGFloat tableLowerYCoord = tableFrame.origin.y + tableFrame.size.height;
    keyboardOverlap = tableLowerYCoord - keyboardRect.origin.y;
    if (self.inputAccessoryView && keyboardOverlap > 0)
    {
        CGFloat accessoryHeight = self.inputAccessoryView.frame.size.height;
        keyboardOverlap -= accessoryHeight;

        self.tableView.contentInset          = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
    }

    if (keyboardOverlap < 0)
    {
        keyboardOverlap = 0;
    }

    if (keyboardOverlap != 0)
    {
        tableFrame.size.height -= keyboardOverlap;

        NSTimeInterval delay = 0;
        if (keyboardRect.size.height)
        {
            delay = (1 - keyboardOverlap/keyboardRect.size.height)*animationDuration;
            animationDuration = animationDuration * keyboardOverlap/keyboardRect.size.height;
        }

        [UIView animateWithDuration:animationDuration delay:delay
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^
        {
            self.tableView.frame = tableFrame;
        }
                         completion:^(BOOL finished)
        {
            [self tableAnimationEnded:nil finished:nil contextInfo:nil];
        }];
    }
}


- (void)keyboardWillHide:(NSNotification*)notification
{
    if (keyboardShown == NO)
    {
        return;
    }
    else
    {
        keyboardShown = NO;
    }

    if (keyboardOverlap == 0)
    {
        return;
    }

    // Get the size & animation details of the keyboard
    NSDictionary*   userInfo = [notification userInfo];
    NSValue*        value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect          keyboardRect = [self.tableView.superview convertRect:[value CGRectValue] fromView:nil];

    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];

    CGRect tableFrame = self.tableView.frame;
    tableFrame.size.height += keyboardOverlap;

    if(keyboardRect.size.height)
    {
        animationDuration = animationDuration * keyboardOverlap/keyboardRect.size.height;
    }

    [UIView animateWithDuration:animationDuration delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^
    {
        self.tableView.frame = tableFrame;
    }
                     completion:nil];
}


- (void)tableAnimationEnded:(NSString*)animationID finished:(NSNumber*)finished contextInfo:(void*)context
{
    // Scroll to the active cell
    if (activeCellIndexPath)
    {
        [self.tableView scrollToRowAtIndexPath:activeCellIndexPath
                              atScrollPosition:UITableViewScrollPositionNone
                                      animated:YES];
        [self.tableView selectRowAtIndexPath:activeCellIndexPath
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionNone];
    }
}

@end
