//
//  NBCustomValueTableViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/6/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBCustomValueTableViewController.h"

@implementation NBCustomValueTableViewController

#pragma mark - Initialization
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set the bar buttons
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed)]];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(savePressed)]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.textField becomeFirstResponder];
}

#pragma mark - Tableview management (1 row only)
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * identifier = @"CellIdentifier";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        
        //Also add the textfield
        self.textField = [[UITextField alloc]initWithFrame:CGRectMake(20, 12, cell.frame.size.width - 20, 25)];
        self.textField.delegate = self;
        [self.textField setPlaceholder:@"Enter value"];
        [cell addSubview:self.textField];
    }
    return cell;
}

#pragma mark - Button delegates
- (void)cancelPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)savePressed
{
    //Inform the system of the new label
    [[NSNotificationCenter defaultCenter] postNotificationName:NF_MUTATE_CUSTOM_LABEL object:nil userInfo:[NSDictionary dictionaryWithObjects:@[self.textField.text, [NSNumber numberWithInt:1]] forKeys:@[NF_KEY_LABEL_VALUE, NF_KEY_ADD_NEW_LABEL]]];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Textfield delegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString * resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self.navigationItem.rightBarButtonItem setEnabled:[resultString length] > 0];
    return YES;
}
@end
