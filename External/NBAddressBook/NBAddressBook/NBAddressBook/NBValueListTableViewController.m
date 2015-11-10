//
//  NBValueListTableViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/6/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBValueListTableViewController.h"

@implementation NBValueListTableViewController

@synthesize structureManager;

#pragma mark - Initialisation
//Used to determine what list to display
static LabelType labelType;
+ (void)setLabelType:(LabelType)labelTypeParam
{
    labelType = labelTypeParam;
}


//Used to determine where to store the selected value
static NSIndexPath* targetLabel;
+ (void)setTargetIndexPath:(NSIndexPath*)indexPathParam
{
    targetLabel = indexPathParam;
}


+ (NSIndexPath*)getTargetIndexPath
{
    return targetLabel;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set the screen title
    UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed)];
    [self.navigationItem setLeftBarButtonItem:cancelButton];
    
    //Determine what to load the list with
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];    
    switch (labelType) {
        case LT_NUMBER:
        {
            defaultLabels = NUMBER_ARRAY;
            customLabels = [userDefaults objectForKey:UD_NUMBER_CUSTOM_LABELS_ARRAY];
            break;
        }
        case LT_EMAIL:
        {
            defaultLabels = HWO_ARRAY;
            customLabels = [userDefaults objectForKey:UD_MAIL_CUSTOM_LABELS_ARRAY];
            break;
        }
        case LT_WEBSITE:
        {
            defaultLabels = WEB_ARRAY;
            customLabels = [userDefaults objectForKey:UD_WEBSITE_CUSTOM_LABELS_ARRAY];
            break;
        }
        case LT_RINGTONE:
        {
#warning - Replace to read in ringtones from local folder or a static array
            defaultLabels = [RINGTONE_ARRAY arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:@"Ringtone 1", @"Ringtone 2", @"Ringtone 3", nil]];
            customLabels = nil; //Not used for ringtones
            break;
        }
        case LT_VIBRATION:
        {
            defaultLabels = VIBRATION_ARRAY;
            customLabels = nil; //Not used for vibrations
            break;
        }
        case LT_SOCIAL:
        {
            defaultLabels = SOCIAL_ARRAY;
            customLabels = [userDefaults objectForKey:UD_SOCIAL_CUSTOM_LABELS_ARRAY];
            break;
        }
        case LT_IM_LABEL:
        {
            defaultLabels = HWO_ARRAY;
            customLabels = [userDefaults objectForKey:UD_IM_CUSTOM_LABELS_ARRAY];
            break;
        }
        case LT_IM_SERVICE:
        {
            defaultLabels = IM_ARRAY;
            customLabels = [userDefaults objectForKey:UD_IM_CUSTOM_SERVICES_ARRAY];
            break;
        }
        case LT_RELATED:
        {
            defaultLabels = RELATED_ARRAY;
            customLabels = [userDefaults objectForKey:UD_RELATED_CUSTOM_LABELS_ARRAY];
            break;
        }
        case LT_ADDRESS:
        {
            defaultLabels = HWO_ARRAY;
            customLabels = [userDefaults objectForKey:UD_ADDRESS_CUSTOM_LABELS_ARRAY];
            break;
        }
        case LT_DATE:
        {
            defaultLabels = DATE_ARRAY;
            customLabels = [userDefaults objectForKey:UD_DATE_CUSTOM_LABELS_ARRAY];
            break;
        }
        default:
        {
            break;
        }
    }
    
    //Listen for custom values
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mutateWithCustomValue:) name:NF_MUTATE_CUSTOM_LABEL object:nil];
}

#pragma mark - Listen for adding/deleting custom values
- (void)mutateWithCustomValue:(NSNotification*)notification
{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    
    //Determine what label and wether to add or delete it
    NSString * customLabel = [notification.userInfo objectForKey:NF_KEY_LABEL_VALUE];
    BOOL add = [[notification.userInfo objectForKey:NF_KEY_ADD_NEW_LABEL] intValue];

    //Determine the type of list
    NSString * arrayKey;
    switch (labelType) {
        case LT_NUMBER:
        {
            arrayKey = UD_NUMBER_CUSTOM_LABELS_ARRAY;
            break;
        }
        case LT_EMAIL:
        {
            arrayKey = UD_MAIL_CUSTOM_LABELS_ARRAY;
            break;
        }
        case LT_WEBSITE:
        {
            arrayKey = UD_WEBSITE_CUSTOM_LABELS_ARRAY;
            break;
        }
        case LT_SOCIAL:
        {
            arrayKey = UD_SOCIAL_CUSTOM_LABELS_ARRAY;
            break;
        }
        case LT_IM_LABEL:
        {
            arrayKey = UD_IM_CUSTOM_LABELS_ARRAY;
            break;
        }
        case LT_IM_SERVICE:
        {
            arrayKey = UD_IM_CUSTOM_SERVICES_ARRAY;
            break;
        }
        case LT_RELATED:
        {
            arrayKey = UD_RELATED_CUSTOM_LABELS_ARRAY;
            break;
        }
        case LT_ADDRESS:
        {
            arrayKey = UD_ADDRESS_CUSTOM_LABELS_ARRAY;
            break;
        }
        case LT_DATE:
        {
            arrayKey = UD_DATE_CUSTOM_LABELS_ARRAY;
            break;
        }
        default:
        {
            break;
        }
    }
    
    //If we didn't have this array before, create it now
    customLabels = [NSMutableArray arrayWithArray:[userDefaults objectForKey:arrayKey]];
    if (customLabels == nil)
    {
        customLabels = [NSMutableArray array];
    }
    
    //Store or delete the custom value
    if (add)
    {
        if (![customLabels containsObject:customLabel])
        {
            [customLabels addObject:customLabel];
        }
    }
    else
    {
        [customLabels removeObject:customLabel];
    }
    [userDefaults setObject:customLabels forKey:arrayKey];
    [userDefaults synchronize];
    
    //Reload the table
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 1)] withRowAnimation:UITableViewRowAnimationFade];
}    

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections
    switch (labelType) {
        case LT_NUMBER:
        case LT_EMAIL:
        case LT_WEBSITE:
        case LT_SOCIAL:
        case LT_IM_LABEL:
        case LT_IM_SERVICE:
        case LT_RELATED:
        case LT_ADDRESS:
        case LT_DATE:
        {
            return 2;
            break;
        }
        case LT_RINGTONE:
        case LT_VIBRATION:
        {
            return 1;
        }
        default:
        {
            break;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //First section for the default labels, second section for custom labels
    int numberOfRows = (section == 0 ? (int)[defaultLabels count] : (int)[customLabels count] + 1);
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * identifier = @"ReuseIdentifier";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    //Since we reuse cells, reset the label
    if (indexPath.section == 0)
    {
        NSString * labelText;
        if (labelType == LT_RINGTONE || labelType == LT_VIBRATION)
        {
            labelText = NSLocalizedString( [defaultLabels objectAtIndex:indexPath.row], @"");
        }
        //Use default address book localization
        else
        {
            labelText = (__bridge NSString*)ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)[defaultLabels objectAtIndex:indexPath.row]);
        }
        [cell.textLabel setText:labelText];
    }
    else
    {
        if (indexPath.row < [customLabels count])
        {
            //It is one of the existing custom labels
            [cell.textLabel setText:[customLabels objectAtIndex:indexPath.row]];
        }
        else
        {
            //It is the add-custom-label button
            [cell.textLabel setText:NSLocalizedString(@"LBL_CUSTOM", @"")];
        }
    }
    
    //Check if this is the currently selected value
    NBPersonCellInfo * cellInfo = [[structureManager.tableStructure objectAtIndex:targetLabel.section] objectAtIndex:targetLabel.row];
    NSString * originalValue = nil;
    NSString * valueToCompareWith = nil;
    if (labelType == LT_EMAIL ||
       labelType == LT_NUMBER ||
       labelType == LT_WEBSITE ||
       labelType == LT_SOCIAL ||
       labelType == LT_IM_LABEL ||
       labelType == LT_RELATED ||
       labelType == LT_ADDRESS ||
       labelType == LT_DATE)
    {
        originalValue      = cell.textLabel.text;
        valueToCompareWith = cellInfo.labelTitle;
    }
    //In case of IM, we compare different fields
    else if (labelType == LT_IM_SERVICE)
    {
        originalValue = cell.textLabel.text;
        valueToCompareWith = cellInfo.IMType;
    }
    //In case of ringtone and vibration, set the value of the textfield
    else
    {
        originalValue      = cell.textLabel.text;        
        valueToCompareWith = cellInfo.textValue;
    }
    
    //Show or hide a checkmark
    if ([originalValue isEqualToString:valueToCompareWith])
    {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [cell.textLabel setTextColor:[UIColor colorWithRed:50/255.0f green:79/255.0f blue:133/255.0f alpha:1.0f]];
    }
    else
    {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        [cell.textLabel setTextColor:[UIColor blackColor]];
    }

    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Only 
    if ((indexPath.section == 1 && indexPath.row < [customLabels count]))
    {
        return UITableViewCellEditingStyleDelete;
    }
    else
    {
        return UITableViewCellEditingStyleNone;
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSString * label = [customLabels objectAtIndex:indexPath.row];
        NSDictionary * notificationDictionary = [NSDictionary dictionaryWithObjects:@[label, [NSNumber numberWithInt:0]] forKeys:@[NF_KEY_LABEL_VALUE, NF_KEY_ADD_NEW_LABEL]];
        NSNotification * notification = [NSNotification notificationWithName:NF_MUTATE_CUSTOM_LABEL object:nil userInfo:notificationDictionary];
        [self mutateWithCustomValue:notification];
    }
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //If we selected one of the values
    if (!(indexPath.section == 1 && indexPath.row == [customLabels count]))
    {
        //Set the selected string in the target label
        NBPersonCellInfo * cellInfo = [[structureManager.tableStructure objectAtIndex:targetLabel.section] objectAtIndex:targetLabel.row];
        
        //Set the tabel for email, numbers and websites
        if (labelType == LT_EMAIL ||
           labelType == LT_NUMBER ||
           labelType == LT_WEBSITE ||
           labelType == LT_SOCIAL ||
           labelType == LT_IM_LABEL ||
           labelType == LT_RELATED ||
           labelType == LT_ADDRESS ||
           labelType == LT_DATE)
        {
            cellInfo.labelTitle = indexPath.section == 1 ? [customLabels objectAtIndex:indexPath.row] : (__bridge NSString*)ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)[defaultLabels objectAtIndex:indexPath.row]);
        }
        //In case of labels, we set a different variable
        else if (labelType == LT_IM_SERVICE)
        {
            //Get the shortened version of this service
            cellInfo.IMType = NSLocalizedString( indexPath.section == 1 ? [customLabels objectAtIndex:indexPath.row] : [IM_ARRAY objectAtIndex:indexPath.row], @"");
        }
        //In case of ringtone and vibration, set the value of the textfield
        else
        {
            cellInfo.textValue = NSLocalizedString( indexPath.section == 1 ? [customLabels objectAtIndex:indexPath.row] : [defaultLabels objectAtIndex:indexPath.row], @"");
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    //If we selected to add a new custom value
    else
    {
        NBCustomValueTableViewController * customViewController = [[NBCustomValueTableViewController alloc]initWithStyle:UITableViewStyleGrouped];
        UINavigationController * navController = [[UINavigationController alloc]initWithRootViewController:customViewController];
        [self presentViewController:navController animated:YES completion:nil];
    }
}

#pragma mark - Cancel delegate
- (void)cancelPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Cleanup
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
