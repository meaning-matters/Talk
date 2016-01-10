//
//  NumberAreaViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 11/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberAreaViewController.h"
#import "NumberAreaPostcodesViewController.h"
#import "NumberAreaCitiesViewController.h"
#import "NumberAreaTitlesViewController.h"
#import "BuyNumberViewController.h"
#import "CountriesViewController.h"
#import "AddressesViewController.h"
#import "Strings.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Common.h"
#import "CountryNames.h"
#import "NumberAreaActionCell.h"
#import "PurchaseManager.h"
#import "Base64.h"
#import "Skinning.h"
#import "DataManager.h"
#import "AddressData.h"


// Update reloadSections calls when adding/removing sections.
typedef enum
{
    TableSectionArea           = 1UL << 0, // Type, area code, area name, state, country.
    TableSectionName           = 1UL << 1, // Name given by user.
    TableSectionAddress        = 1UL << 2,
    TableSectionAction         = 1UL << 3, // Check info, or Buy.
} TableSections;

typedef enum
{
    AreaRowType     = 1UL << 0,
    AreaRowAreaCode = 1UL << 1,
    AreaRowAreaName = 1UL << 2,
    AreaRowState    = 1UL << 3,
    AreaRowCountry  = 1UL << 4,
} AreaRows;


@interface NumberAreaViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate>
{
    NSString*       numberIsoCountryCode;
    NSString*       areaCode;
    AddressTypeMask addressTypeMask;
    NSDictionary*   state;
    NSDictionary*   area;
    NumberTypeMask  numberTypeMask;


    NSArray*       citiesArray;
    NSString*      name;
    BOOL           requireProof;
    BOOL           isChecked;
    TableSections  sections;
    AreaRows       areaRows;

    NSIndexPath*   actionIndexPath;

    // Keyboard stuff.
    BOOL           keyboardShown;
    CGFloat        keyboardOverlap;
}

@property (nonatomic, strong) NSIndexPath*             nameIndexPath;

@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic, assign) BOOL                     hasCorrectedInsets;
@property (nonatomic, strong) AddressData*             address;
@property (nonatomic, strong) NSPredicate*             addressesPredicate;
@property (nonatomic, assign) BOOL                     isLoading;

@end


@implementation NumberAreaViewController

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                                 state:(NSDictionary*)theState
                                  area:(NSDictionary*)theArea
                        numberTypeMask:(NumberTypeMask)theNumberTypeMask
{    
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        numberIsoCountryCode = isoCountryCode;
        state                = theState;
        area                 = theArea;
        numberTypeMask       = theNumberTypeMask;
        requireProof         = [area[@"requireProof"] boolValue];
        areaCode             = [area[@"areaCode"] length] > 0 ? area[@"areaCode"] : nil;
        addressTypeMask      = [AddressType addressTypeMaskForString:area[@"addressType"]];

        // Mandatory sections.
        sections |= TableSectionArea;
        sections |= TableSectionName;
        sections |= TableSectionAction;

        // Optional Sections.
        sections |= (addressTypeMask == AddressTypeNoneMask) ? 0 : TableSectionAddress;

        // Always there Area section rows.
        areaRows |= AreaRowType;
        areaRows |= AreaRowCountry;
        
        // Conditionally there Area section rows.
        BOOL allCities = (area[@"areaName"] != [NSNull null] &&
                          [area[@"areaName"] caseInsensitiveCompare:@"All cities"] == NSOrderedSame);
        areaRows |= ([area[@"areaCode"] length] > 0)                           ? AreaRowAreaCode : 0;
        areaRows |= (numberTypeMask == NumberTypeGeographicMask && !allCities) ? AreaRowAreaName : 0;
        areaRows |= (numberTypeMask == NumberTypeSpecialMask)                  ? AreaRowAreaName : 0;
        areaRows |= (state != nil)                                             ? AreaRowState    : 0;

        // Default naming.
        NSString* city;
        NSString* countryName = [[CountryNames sharedNames] nameForIsoCountryCode:numberIsoCountryCode];
        switch (numberTypeMask)
        {
            case NumberTypeGeographicMask:
            {
                city = [Common capitalizedString:area[@"city"]];
                name = [NSString stringWithFormat:@"%@ (%@)", city, numberIsoCountryCode];
                break;
            }
            case NumberTypeNationalMask:
            {
                name = [NSString stringWithFormat:@"%@ (paid)", countryName];
                break;
            }
            case NumberTypeTollFreeMask:
            {
                name = [NSString stringWithFormat:@"%@ (free)", countryName];
                break;
            }
            case NumberTypeMobileMask:
            {
                name = [NSString stringWithFormat:@"%@ (mobile)", countryName];
                break;
            }
            case NumberTypeSharedCostMask:
            {
                name = [NSString stringWithFormat:@"%@ (shared)", countryName];
                break;
            }
            case NumberTypeSpecialMask:
            {
                name = [NSString stringWithFormat:@"%@ (special)", countryName];
                break;
            }
            case NumberTypeInternationalMask:
            {
                name = [NSString stringWithFormat:@"International (%@)", area[@"areaCode"]];
                break;
            }
        }
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberArea ScreenTitle", nil,
                                                                  [NSBundle mainBundle], @"Area",
                                                                  @"Title of app screen with one area.\n"
                                                                  @"[1 line larger font].");

    UIBarButtonItem* cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancelAction)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    // Let keyboard be hidden when user taps outside text fields.
    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:gestureRecognizer];

    [self.tableView registerNib:[UINib nibWithNibName:@"NumberAreaActionCell" bundle:nil]
         forCellReuseIdentifier:@"NumberAreaActionCell"];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NumberAreaActionCell* cell = (NumberAreaActionCell*)[self.tableView cellForRowAtIndexPath:actionIndexPath];
    cell.label.text            = [self actionCellText];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];

    [self loadAddressesPredicate];
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    UIView* topView = [[[[UIApplication sharedApplication] keyWindow] subviews] lastObject];
    CGPoint center = topView.center;
    center = [topView convertPoint:center toView:self.view];
    self.activityIndicator.center = center;
}


#pragma mark - Helper Methods

- (void)hideKeyboard:(UIGestureRecognizer*)gestureRecognizer
{
    if (name.length > 0)
    {
        if (self.hasCorrectedInsets == YES)
        {
            //### Workaround: http://stackoverflow.com/a/22053349/1971013
            [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 265, 0)];
            [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(64, 0, 265, 0)];
            
            self.hasCorrectedInsets = NO;
        }
        
        //####[self save];
        [[self.tableView superview] endEditing:YES];
    }
}


- (void)cancelAction
{
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (NSString*)actionCellText
{
    NSString* text;

    //#### needed?
    text = NSLocalizedStringWithDefaultValue(@"NumberArea:Action BuyLabel", nil,
                                             [NSBundle mainBundle],
                                             @"Buy",
                                             @"....");
    
    return text;
}


- (void)loadAddressesPredicate
{
    if (self.address == nil)
    {
        self.isLoading = YES;
        [self reloadAddressCell];
    }

    [AddressesViewController loadAddressesPredicateWithAddressType:addressTypeMask
                                                    isoCountryCode:numberIsoCountryCode
                                                          areaCode:areaCode
                                                        numberType:numberTypeMask
                                                        completion:^(NSPredicate *predicate, NSError *error)
    {
        self.isLoading = NO;
        if (error == nil)
        {
            [self reloadAddressCell];
            self.addressesPredicate = predicate;
        }
        else
        {
            [self showError:error];
        }
    }];
}


- (void)reloadAddressCell
{
    NSArray* indexPaths = @[[NSIndexPath indexPathForItem:0
                                                inSection:[Common nOfBit:TableSectionAddress inValue:sections]]];

    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}


- (void)showError:(NSError*)error
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"NumberArea LoadFailAlertTitle", nil,
                                                [NSBundle mainBundle], @"Loading Failed",
                                                @"Alert title telling that loading countries over internet failed.\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"NumberArea LoadFailAlertMessage", nil,
                                                [NSBundle mainBundle],
                                                @"Loading the list of valid addresses for this area failed: %@\n\n"
                                                @"Please try again later.",
                                                @"Alert message telling that loading areas over internet failed.\n"
                                                @"[iOS alert message size!]");
    message = [NSString stringWithFormat:message, error.localizedDescription];
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
                         cancelButtonTitle:[Strings cancelString]
                         otherButtonTitles:nil];
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:sections];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionArea:
        {
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Area SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Current Selection",
                                                      @"...");
            break;
        }
        case TableSectionName:
        {
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Naming SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Number's Name In App",
                                                      @"...");
            break;
        }
        case TableSectionAction:
        {
            break;
        }
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionArea:
        {
            break;
        }
        case TableSectionName:
        {
            title = [Strings nameFooterString];
            break;
        }
        case TableSectionAddress:
        {
            title = NSLocalizedStringWithDefaultValue(@"NumberAre:Address SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"A contact name and address "
                                                      @"are legally required.",
                                                      @"Explaining that information must be supplied by user.");
            break;
        }
        case TableSectionAction:
        {
            title = NSLocalizedStringWithDefaultValue(@"NumberArea:Action SectionFooterBuy", nil,
                                                      [NSBundle mainBundle],
                                                      @"You can always buy extra months to use "
                                                      @"this phone number.",
                                                      @"Explaining that user can buy more months.");
            break;
        }
    }

    return title;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionArea:
        {
            numberOfRows = [Common bitsSetCount:areaRows];
            break;
        }
        case TableSectionName:
        {
            numberOfRows = 1;
            break;
        }
        case TableSectionAddress:
        {
            numberOfRows = 1;
            break;
        }
        case TableSectionAction:
        {
            numberOfRows = 1;
            break;
        }
    }

    return numberOfRows;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.tableView cellForRowAtIndexPath:indexPath].selectionStyle == UITableViewCellSelectionStyleNone)
    {
        return;
    }

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionAddress:
        {
            NSManagedObjectContext*  managedObjectContext = [DataManager sharedManager].managedObjectContext;
            AddressesViewController* viewController;

            viewController = [[AddressesViewController alloc] initWithManagedObjectContext:managedObjectContext
                                                                           selectedAddress:self.address
                                                                            isoCountryCode:numberIsoCountryCode
                                                                                  areaCode:areaCode
                                                                                numberType:numberTypeMask
                                                                               addressType:addressTypeMask
                                                                                 proofType:area[@"proofType"]
                                                                                 predicate:self.addressesPredicate
                                                                                completion:^(AddressData *selectedAddress)
            {
                self.address = selectedAddress;
                [self reloadAddressCell];
            }];

            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case TableSectionAction:
        {
            if (((sections & TableSectionAddress) && self.address != nil) ||
                (sections & TableSectionAddress) == 0)
            {
                BuyNumberViewController* viewController;
                /*
                viewController = [[BuyNumberViewController alloc] initWithName:name
                                                                isoCountryCode:numberIsoCountryCode
                                                                          area:area
                                                                numberTypeMask:numberTypeMask
                                                                          info:purchaseInfo];
                [self.navigationController pushViewController:viewController animated:YES];
                 */
            }
            else
            {
                NSString*   title;
                NSString*   message;

                title   = NSLocalizedStringWithDefaultValue(@"NumberArea AddressRequiredTitle", nil,
                                                            [NSBundle mainBundle], @"Address Required",
                                                            @"Alert title telling that user did not fill in all information.\n"
                                                            @"[iOS alert title size].");
                if (requireProof)
                {
                    message = NSLocalizedStringWithDefaultValue(@"NumberArea AddressWithProofRequiredMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"A contact address with verification image are "
                                                                @"required for this type of Number in this area."
                                                                @"\n\nGo and add or select an address.",
                                                                @"Alert message telling that user did not fill in all information.\n"
                                                                @"[iOS alert message size]");
                }
                else
                {
                    message = NSLocalizedStringWithDefaultValue(@"NumberArea IncompleteAlertMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"A contact address is required for this Number."
                                                                @"\n\nGo and add or select an address.",
                                                                @"Alert message telling that user did not fill in all information.\n"
                                                                @"[iOS alert message size]");
                }
                
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                {
                    if (cancelled)
                    {
                        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                    }
                    else
                    {
                        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:1 inSection:TableSectionAddress];
                        [self tableView:tableView didSelectRowAtIndexPath:indexPath];
                    }
                }
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:[Strings goString], nil];
            }
            
            break;
        }
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionArea:    cell = [self areaCellForRowAtIndexPath:indexPath];    break;
        case TableSectionName:    cell = [self nameCellForRowAtIndexPath:indexPath];    break;
        case TableSectionAddress: cell = [self addressCellForRowAtIndexPath:indexPath]; break;
        case TableSectionAction:  cell = [self actionCellForRowAtIndexPath:indexPath];  break;
    }

    return cell;
}


#pragma mark - Cell Methods

- (UITableViewCell*)areaCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        identifier;

    identifier  = ([Common nthBitSet:indexPath.row inValue:areaRows] == AreaRowCountry) ? @"CountryCell"
                                                                                        : @"Value1Cell";
    cell        = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }

    switch ([Common nthBitSet:indexPath.row inValue:areaRows])
    {
        case AreaRowType:
        {
            cell.textLabel.text       = [Strings typeString];
            cell.detailTextLabel.text = [NumberType localizedStringForNumberTypeMask:numberTypeMask];
            cell.imageView.image      = nil;
            break;
        }
        case AreaRowAreaCode:
        {
            cell.textLabel.text       = [Strings areaCodeString];
            cell.detailTextLabel.text = area[@"areaCode"];
            cell.imageView.image      = nil;
            break;
        }
        case AreaRowAreaName:
        {
            cell.textLabel.text       = [Strings areaString];
            cell.detailTextLabel.text = [Common capitalizedString:area[@"areaName"]];
            cell.imageView.image      = nil;
            break;
        }
        case AreaRowState:
        {
            cell.textLabel.text       = [Strings stateString];
            cell.detailTextLabel.text = state[@"stateName"];
            cell.imageView.image      = nil;
            break;
        }
        case AreaRowCountry:
        {
            cell.textLabel.text       = @" ";     // Without this, the detailTextLabel is on the left.
            cell.detailTextLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:numberIsoCountryCode];
            [Common addCountryImageToCell:cell isoCountryCode:numberIsoCountryCode];
            break;
        }
    }

    cell.accessoryType  = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)nameCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    UITextField*     textField;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"TextFieldCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"TextFieldCell"];
        textField = [Common addTextFieldToCell:cell delegate:self];
        textField.tag = TextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
    }

    cell.textLabel.text              = [Strings nameString];
    textField.placeholder            = [Strings requiredString];
    textField.text                   = [name stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
    textField.userInteractionEnabled = YES;
    objc_setAssociatedObject(textField, @"TextFieldKey", @"name", OBJC_ASSOCIATION_RETAIN);

    cell.detailTextLabel.text = nil;
    cell.imageView.image      = nil;
    cell.accessoryType        = UITableViewCellAccessoryNone;
    cell.selectionStyle       = UITableViewCellSelectionStyleNone;

    [self updateTextField:textField onCell:cell];

    return cell;
}


- (UITableViewCell*)addressCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"AddressCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"AddressCell"];
    }
    
    cell.textLabel.text            = NSLocalizedString(@"Address", @"Address cell title");
    cell.detailTextLabel.textColor = self.address ? [Skinning valueColor] : [Skinning placeholderColor];
    cell.accessoryType             = UITableViewCellAccessoryDisclosureIndicator;

    if (self.isLoading)
    {
        UIActivityIndicatorView* spinner;
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [spinner startAnimating];

        cell.accessoryView          = spinner;
        cell.userInteractionEnabled = NO;
        cell.detailTextLabel.text   = nil;
    }
    else
    {
        cell.accessoryView          = nil;
        cell.userInteractionEnabled = YES;
        cell.detailTextLabel.text   = self.address ? self.address.name : [Strings requiredString];
    }

    return cell;
}


- (UITableViewCell*)actionCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberAreaActionCell*   cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumberAreaActionCell"];
    if (cell == nil)
    {
        cell = [[NumberAreaActionCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:@"NumberAreaActionCell"];
    }

    cell.label.text      = [self actionCellText];
    cell.label.textColor = [Skinning tintColor];

    actionIndexPath = indexPath;

    return cell;
}


- (void)updateTextField:(UITextField*)textField onCell:(UITableViewCell*)cell
{
    cell.detailTextLabel.text = nil;
    cell.imageView.image      = nil;

    if (cell.accessoryType == UITableViewCellAccessoryDisclosureIndicator)
    {
        [Common setX:60 ofView:textField];
        textField.textColor = [UIColor grayColor];
    }
    else
    {
        [Common setX:80 ofView:textField];
        if (textField.userInteractionEnabled == YES)
        {
            textField.textColor = [Skinning tintColor];
        }
        else
        {
            textField.textColor = [UIColor grayColor];
        }
    }
}


#pragma mark - TextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
    //#### Copy-paste from ItemViewController, see if superclass can be used.
    textField.returnKeyType                 = UIReturnKeyDone;
    textField.enablesReturnKeyAutomatically = YES;
    
    #warning The method reloadInputViews messes up two-byte keyboards (e.g. Kanji).
    [textField reloadInputViews];
    
    //### Workaround: http://stackoverflow.com/a/22053349/1971013
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^(void)
    {
        if (self.tableView.contentInset.bottom == 265)
        {
            [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 216, 0)];
            [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(64, 0, 216, 0)];
            
            self.hasCorrectedInsets = YES;
        }
    });
    
    return YES;
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


// Not used at the moment, because there are no clear buttons.
- (BOOL)textFieldShouldClear:(UITextField*)textField
{
    NSString* key = objc_getAssociatedObject(textField, @"TextFieldKey");
    
    if ([key isEqualToString:@"name"])
    {
        name = @"";
    }
    
    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    //####[self save];
    
    [textField resignFirstResponder];
    
    if (self.hasCorrectedInsets == YES)
    {
        //### Workaround: http://stackoverflow.com/a/22053349/1971013
        [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 265, 0)];
        [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(64, 0, 265, 0)];
        
        self.hasCorrectedInsets = NO;
    }
    
    // we can always return YES, because the Done button will be disabled when there's no text.
    return YES;
}


- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    // See http://stackoverflow.com/a/14792880/1971013 for keeping cursor on correct position.
    UITextPosition* beginning    = textField.beginningOfDocument;
    UITextPosition* start        = [textField positionFromPosition:beginning offset:range.location];
    NSInteger       cursorOffset = [textField offsetFromPosition:beginning toPosition:start] + string.length;
    
    // See http://stackoverflow.com/a/22211018/1971013 why we're using non-breaking spaces @"\u00a0".
    textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    textField.text = [textField.text stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
    
    name = [textField.text stringByReplacingOccurrencesOfString:@"\u00a0" withString:@" "];
    
    [self.tableView scrollToRowAtIndexPath:self.nameIndexPath
                          atScrollPosition:UITableViewScrollPositionNone
                                  animated:YES];
    
    // See http://stackoverflow.com/a/14792880/1971013 for keeping cursor on correct position.
    UITextPosition* newCursorPosition = [textField positionFromPosition:textField.beginningOfDocument offset:cursorOffset];
    UITextRange*    newSelectedRange  = [textField textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
    [textField setSelectedTextRange:newSelectedRange];
    
    return NO;  // Need to return NO, because we've already changed textField.text.
}


#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch
{
    if ([touch.view isKindOfClass:[UITextField class]] || [touch.view isKindOfClass:[UIButton class]])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

@end
