//
//  ItemViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 26/02/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "ItemViewController.h"
#import "DataManager.h"
#import "Common.h"
#import "Strings.h"


@interface ItemViewController ()

@property (nonatomic, assign) BOOL hasCorrectedInsets;

@end


@implementation ItemViewController

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.managedObjectContext = managedObjectContext;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleManagedObjectsChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:self.managedObjectContext];
    }

    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextObjectsDidChangeNotification
                                                  object:self.managedObjectContext];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = NO;

    // Let keyboard be hidden when user taps outside text fields.
    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:gestureRecognizer];
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


#pragma mark - Navigation Action

- (void)cancelAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Helper Methods

- (void)handleManagedObjectsChange:(NSNotification*)note
{
    NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath == nil)
    {
        [self.tableView reloadData];
    }
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


// Placeholder that must be overriden by subclass.
- (void)save
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
        textField.tag = TextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
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
    if ([touch.view isKindOfClass:[UITextField class]] || [touch.view isKindOfClass:[UIButton class]])
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
    if (self.name.length > 0)
    {
        if (self.hasCorrectedInsets == YES)
        {
            //### Workaround: http://stackoverflow.com/a/22053349/1971013
            [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 265, 0)];
            [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(64, 0, 265, 0)];

            self.hasCorrectedInsets = NO;
        }

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

    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [self save];

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
    // See http://stackoverflow.com/a/22211018/1971013 why we're using non-breaking spaces @"\u00a0".
    textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    textField.text = [textField.text stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];

    self.name = [textField.text stringByReplacingOccurrencesOfString:@"\u00a0" withString:@" "];;

    [self.tableView scrollToRowAtIndexPath:self.nameIndexPath
                          atScrollPosition:UITableViewScrollPositionNone
                                  animated:YES];

    return NO;  // Need to return NO, because we've already changed textField.text.
}

@end
