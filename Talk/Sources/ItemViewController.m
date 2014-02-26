//
//  ItemViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 26/02/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "ItemViewController.h"
#import "DataManager.h"


@interface ItemViewController ()
{
}

@end


@implementation ItemViewController

- (id)init
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleManagedObjectsChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:[DataManager sharedManager].managedObjectContext];
    }

    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextObjectsDidChangeNotification
                                                  object:[DataManager sharedManager].managedObjectContext];
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
        //### Workaround: http://stackoverflow.com/a/22053349/1971013
        [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 265, 0)];
        [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(64, 0, 265, 0)];

        [[self.tableView superview] endEditing:YES];

        [self save];
    }
}


#pragma mark - TextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
    textField.returnKeyType = UIReturnKeyDone;
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

    //### Workaround: http://stackoverflow.com/a/22053349/1971013
    [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 265, 0)];
    [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(64, 0, 265, 0)];

    // we can always return YES, because the Done button will be disabled when there's no text.
    return YES;
}


- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    self.name = [textField.text stringByReplacingCharactersInRange:range withString:string];

    [self.tableView scrollToRowAtIndexPath:self.nameIndexPath
                          atScrollPosition:UITableViewScrollPositionNone
                                  animated:YES];
    
    return YES;
}

@end
