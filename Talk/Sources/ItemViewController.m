//
//  ItemViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 26/02/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import "ItemViewController.h"
#import "DataManager.h"
#import "Common.h"
#import "Strings.h"
#import "BlockAlertView.h"

#warning Check if the hard-coded inset values (265, 216, ...) are working on iPhone 6+ and for all keyboard configurations.

@interface ItemViewController ()

@property (nonatomic, assign) BOOL hasCorrectedInsets;
@property (nonatomic, assign) BOOL isKeyboardShown;

@end


@implementation ItemViewController

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.managedObjectContext = managedObjectContext;

        [self addKeyboardObservers];
    }

    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (NSString*)name
{
    return [self.item respondsToSelector:@selector(name)] ? [self.item name] : nil;
}


- (void)setName:(NSString*)name
{
    [self.item respondsToSelector:@selector(name)] ? [self.item setName:name] : 0;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = NO;

    // Let keyboard be hidden when user taps outside text fields.
    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate             = self;
    [self.tableView addGestureRecognizer:gestureRecognizer];

    [self setupFootnotesHandlingOnTableView:self.tableView];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath != nil)
    {
        [self.tableView reloadRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


#pragma mark - Keyboard State

- (void)addKeyboardObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}


- (void)keyboardDidShow:(NSNotification*)notification
{
    self.isKeyboardShown = YES;
}


- (void)keyboardDidHide:(NSNotification*)notification
{
    self.isKeyboardShown = NO;
}


#pragma mark - Navigation Action

- (void)cancelAction
{
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Public Helper Method

- (UIViewController*)backViewController
{
    NSInteger numberOfViewControllers = self.navigationController.viewControllers.count;

    if (numberOfViewControllers < 2)
    {
        return nil;
    }
    else
    {
        return [self.navigationController.viewControllers objectAtIndex:numberOfViewControllers - 2];
    }
}


- (void)showSaveError:(NSError*)error
                title:(NSString*)title
             itemName:(NSString*)itemName
           completion:(void (^)(void))completion
{
    NSString* message;

    if (title == nil)
    {
        title = NSLocalizedStringWithDefaultValue(@"SaveErrorTitle", nil, [NSBundle mainBundle],
                                                  @"%@ Not Saved",
                                                  @"....\n"
                                                  @"[iOS alert title size].");
        title = [NSString stringWithFormat:title, itemName];
    }
    message = NSLocalizedStringWithDefaultValue(@"SaveErroMessage", nil, [NSBundle mainBundle],
                                                @"Saving this %@ failed: %@\n\nPlease try again later.",
                                                @"...\n"
                                                @"[iOS alert message size]");

    [BlockAlertView showAlertViewWithTitle:title
                                   message:[NSString stringWithFormat:message, itemName, [error localizedDescription]]
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        completion ? completion() : 0;
    }
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


#pragma mark - Helper Methods

- (NSIndexPath*)findCellIndexPathForSubview:(UIView*)subview
{
    UIView* superview = subview.superview;
    while ([superview class] != [UITableViewCell class])
    {
        superview = superview.superview;
    }

    return [self.tableView indexPathForCell:(UITableViewCell*)superview];
}


#pragma mark - Placeholders that must be overriden by subclass.

- (void)save
{
}


- (void)update
{
}


#pragma mark - Name Cell

- (UITableViewCell*)nameCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    UITextField*     textField;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NameCell"];
    if (cell == nil)
    {
        cell          = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"NameCell"];
        textField     = [Common addTextFieldToCell:cell delegate:(id<UITextFieldDelegate>)self]; // The subclass must implement this delegate.
        textField.tag = CommonTextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:CommonTextFieldCellTag];
    }

    textField.placeholder = [Strings requiredString];
    textField.text        = [self.name stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];

    cell.textLabel.text   = [Strings nameString];
    cell.imageView.image  = nil;
    cell.accessoryType    = UITableViewCellAccessoryNone;
    cell.selectionStyle   = UITableViewCellSelectionStyleNone;

    return cell;
}


#pragma mark - Gesture Recognizer Delegate & Related Method

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch
{
    if (([touch.view isKindOfClass:[UITextField class]] && touch.view.isUserInteractionEnabled) ||
        [touch.view isKindOfClass:[UIButton class]])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}


- (void)hideKeyboard:(UIGestureRecognizer*)gestureRecognizer
{
    if (self.hasCorrectedInsets == YES)
    {
        //### Workaround: http://stackoverflow.com/a/22053349/1971013
        [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 265, 0)];
        [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(64, 0, 265, 0)];

        self.hasCorrectedInsets = NO;
    }

    if (self.isKeyboardShown)
    {
        [self update];
        [self save];
        [[self.tableView superview] endEditing:YES];
    }
}


#pragma mark - TextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
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


// Only used when there's a clear button (which we don't have now; see Common).
- (BOOL)textFieldShouldClear:(UITextField*)textField
{
    self.name = @"";
    
    [self update];

    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [self update];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
    {
        [self save];
    });

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

    self.name = [textField.text stringByReplacingOccurrencesOfString:@"\u00a0" withString:@" "];

    [self.tableView scrollToRowAtIndexPath:self.nameIndexPath
                          atScrollPosition:UITableViewScrollPositionNone
                                  animated:YES];

    // See http://stackoverflow.com/a/14792880/1971013 for keeping cursor on correct position.
    UITextPosition* newCursorPosition = [textField positionFromPosition:textField.beginningOfDocument offset:cursorOffset];
    UITextRange*    newSelectedRange  = [textField textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
    [textField setSelectedTextRange:newSelectedRange];
    
    [self update];
    
    return NO;  // Need to return NO, because we've already changed textField.text.
}

@end
