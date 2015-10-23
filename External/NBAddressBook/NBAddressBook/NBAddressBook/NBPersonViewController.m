//
//  NBPersonViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/3/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBPersonViewController.h"
#import "NBPersonCellAddressInfo.h"
#import "NBPeopleListViewController.h"
#import "NBPeoplePickerNavigationController.h"
#import "NBRecentContactViewController.h"
#import "CallableData.h"


@interface NBPersonViewController () <UITextFieldDelegate>
@end


@implementation NBPersonViewController

@synthesize contact, allowsActions, displayedPerson, personViewDelegate;

#pragma mark - Initialization
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Create the contact, with actual addressbook if it is not unknown/new
    if (displayedPerson != nil )
        self.contact = [[NBContact alloc]initWithContact:displayedPerson];
    else
        self.contact = [[NBContact alloc]init];
    
    //Set the screen title
    self.navigationItem.title = NSLocalizedString(@"NCT_INFO", @"");
    
    //Listen for keyboard popup
    [self addKeyboardNotifications];

    //Set the bar frame and take both the navigation controller and tabbar into consideration
    CGRect appFrame = self.view.bounds;
    self.view.frame = CGRectMake( 0, 0, appFrame.size.width, appFrame.size.height);
    self.tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [self.tableView setFrame:self.view.frame];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    [self.view addSubview:self.tableView];
    
    //Set footer button text layout and text
    UIView * footerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 80)];
    
    //If we allow for actions
    if (allowsActions)
    {
        //First button
        firstFooterButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [firstFooterButton setFrame:CGRectMake(8, 6, 94, 45)];
        [firstFooterButton.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [firstFooterButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [firstFooterButton.titleLabel setNumberOfLines:2];
        [firstFooterButton.titleLabel setFont:[UIFont boldSystemFontOfSize:13]];
        [firstFooterButton setTitleColor:FONT_COLOR_LABEL forState:UIControlStateNormal];
        [firstFooterButton setTitle:NSLocalizedString(@"BL_SEND_MESSAGE", @"") forState:UIControlStateNormal];
        [firstFooterButton addTarget:self action:@selector(firstFooterButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [footerView addSubview:firstFooterButton];
        
        //Second button
        secondFooterButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [secondFooterButton setFrame:CGRectMake(112, 6, 94, 45)];
        [secondFooterButton.titleLabel setLineBreakMode: NSLineBreakByWordWrapping];
        [secondFooterButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [secondFooterButton.titleLabel setNumberOfLines:2];
        [secondFooterButton.titleLabel setFont:[UIFont boldSystemFontOfSize:13]];
        [secondFooterButton setTitleColor:FONT_COLOR_LABEL forState:UIControlStateNormal];
        [secondFooterButton setTitle:NSLocalizedString(@"BL_SHARE_CONTACT", @"") forState:UIControlStateNormal];
        [secondFooterButton addTarget:self action:@selector(secondFooterButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [footerView addSubview:secondFooterButton];

        //Third button
        thirdFooterButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [thirdFooterButton setFrame:CGRectMake(217, 6, 94, 45)];
        [thirdFooterButton.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [thirdFooterButton.titleLabel setNumberOfLines:2];
        [thirdFooterButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [thirdFooterButton.titleLabel setFont:[UIFont boldSystemFontOfSize:13]];
        [thirdFooterButton setTitleColor:FONT_COLOR_LABEL forState:UIControlStateNormal];
        [thirdFooterButton setTitle:NSLocalizedString(@"BL_ADD_TO_FAV", @"") forState:UIControlStateNormal];
        [thirdFooterButton addTarget:self action:@selector(thirdFooterButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [footerView addSubview:thirdFooterButton];
    }
    
    //Finally add the footer view
    [footerView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setTableFooterView:footerView];

    //Create the portrait graphics
    portraitLine    = [UIImage imageNamed:@"portraitLine.png"];
    portraitNoPhoto = [UIImage imageNamed:@"noPictureImage.png"];
    portraitCompanyNoPhoto = [UIImage imageNamed:@"noPictureCompanyImage.png"];
    portraitBackground  = [UIImage imageNamed:@"portraitBackground"];
    
    //Create the portrait edge for non-editing
    portraitImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 68, 68)];
    [portraitImageView setImage:portraitBackground];
    [self.tableView addSubview:portraitImageView];
    
    //Create the portrait button for editing
    portraitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    portraitButton.frame = CGRectMake( 0, 0, 56, 56);
    [portraitButton setCenter:CGPointMake(43, 45)];
    [portraitButton setAdjustsImageWhenHighlighted:NO];
    [portraitButton setAdjustsImageWhenDisabled:NO];
    [self.tableView addSubview:portraitButton];
    
    //Position the portraitview behind the button
    portraitImageView.center = CGPointMake( portraitButton.center.x, portraitButton.center.y + 1);
    
    //Add a label in the back for adding pictures
    addLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, portraitButton.frame.size.width, portraitButton.frame.size.height)];
    [addLabel setCenter:portraitButton.center];
    [addLabel setText:NSLocalizedString(@"NCT_ADD_PICTURE", @"")];
    [addLabel setTextAlignment:NSTextAlignmentCenter];
    [addLabel setFont:[UIFont boldSystemFontOfSize:14]];
    [addLabel setTextColor:FONT_COLOR_LABEL];
    [addLabel setNumberOfLines:0];
    [addLabel setBackgroundColor:[UIColor clearColor]];
    [self.tableView addSubview:addLabel];
    
    //Add the edit-label in case a protrait already exists
    editLabelView = [[UIView alloc]initWithFrame:CGRectMake(
                                                            portraitButton.frame.origin.x,
                                                            portraitButton.frame.origin.y + (portraitButton.frame.size.height * 0.75f),
                                                            portraitButton.frame.size.width,
                                                            portraitButton.frame.size.height/4)];
    [editLabelView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5f]];
    UILabel * editLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, editLabelView.frame.size.width, editLabelView.frame.size.height)];
    [editLabel setTextAlignment:NSTextAlignmentCenter];
    [editLabel setText:NSLocalizedString(@"NCT_EDIT_PICTURE", @"")];
    [editLabel setTextColor:[UIColor whiteColor]];
    [editLabel setBackgroundColor:[UIColor clearColor]];
    [editLabel setFont:[UIFont boldSystemFontOfSize:13]];
    [editLabelView addSubview:editLabel];
    [self.tableView addSubview:editLabelView];

    //Create a name label with 70 default height (but can be changed by more name data)
    nameLabel = [[UILabel alloc]initWithFrame:CGRectMake( 85, 15, 220, SIZE_NAME_LABEL_MEASURE)];
    [nameLabel setNumberOfLines:0];
    [self.tableView addSubview:nameLabel];
    
    //Reset the table structure
    personStructureManager = [[NBContactStructureManager alloc] init];
    
    //Fill the person-properties into the model
    if (contact.contactRef != nil)
    {
        [personStructureManager fillWithContact:contact];
        
        [self setNameLabel];
    }

    //If we're merging, start in edit-mode, else start in viewing-mode
    [self enableEditMode:NO];

    //Listen for reloads
    [self listenForChanges:YES];
    
    [self.view setBackgroundColor:PERSON_BACKGROUND_COLOR];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //We're no longer changing the label
    changingLabel = NO;
    
    //Reload table when it re-appears
    [self.tableView reloadData];
}


#pragma mark - Reloading contact
- (void)reloadContact
{
    //Check if the contact still exists, if not, dismiss
    ABRecordRef record = ABAddressBookGetPersonWithRecordID([[NBAddressBookManager sharedManager] getAddressBook], ABRecordGetRecordID(contact.contactRef));
    if (record == nil)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        //Re-fill with the contactref we have
        [personStructureManager reset];
        [personStructureManager fillWithContact:contact];

        //If we're merging, start in edit-mode, else start in viewing-mode
        [self enableEditMode:NO];

        [self.tableView reloadData];
    }
}

#pragma mark - Focussing on fields
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
             
             //Scroll straight away to the cell for best simulation
             //### Removed.
         }
         completion:^(BOOL finished){}];
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


#pragma mark - Switch between view modes (only used in view-mode)
- (void)setPortrait:(BOOL)enable
{
    if (enable)
    {
        //Set the portrait
        BOOL hasImage = [contact getImage:NO] != nil;
        if (hasImage)
        {
            //Set the portrait withi mage
            [portraitImageView setImage:portraitBackground];
            [self changePortraitButtonImage:[contact getImage:NO]];
        }
        else
        {
            //Set the portrait dotted line
            [portraitImageView setImage:portraitLine];
            [self changePortraitButtonImage:nil];
        }

        [editLabelView setAlpha:hasImage ? 1.0f : 0.0f];
        [addLabel setAlpha:hasImage ? 0.0f : 1.0f];
    }
    else
    {
        //Set the portrait frame
        [portraitImageView setImage:portraitBackground];

        //Mutate the label alpha
        [editLabelView setAlpha:0.0f];
        [addLabel setAlpha:0.0f];

        //Set the portrait in the header
        if ([contact getImage:NO] != nil)
        {
            [self changePortraitButtonImage:[contact getImage:NO]];
        }
        else
        {
            //Companies and contacts use different no-image placeholders
            if ([contact isCompany])
            {
                [self changePortraitButtonImage:portraitCompanyNoPhoto];
            }
            else
            {
                [self changePortraitButtonImage:portraitNoPhoto];
            }
        }
    }
}


- (void)changePortraitButtonImage:(UIImage*)changeToImage
{
    [portraitButton setImage:changeToImage forState:UIControlStateNormal];
    CATransition *transition = [CATransition animation];
    transition.duration = ANIMATION_SPEED;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [portraitButton.layer addAnimation:transition forKey:nil];
}


- (void)enableEditMode:(BOOL)enable
{
    [self setNameLabel];

    //Set the namelabel visibility
    [UIView animateWithDuration:ANIMATION_SPEED
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations: ^(void){
                         //Set the name and portrait
                         [self setPortrait:enable];
                         [nameLabel setAlpha:enable ? 0.0f : 1.0f];
                     }
                     completion:nil];
    
    //Disable changing portrait in viewing mode
    [portraitButton setEnabled:enable];
    
#pragma mark - Set the fields that should be hidden
    //Mutate the ringtone field
    [[[personStructureManager.tableStructure objectAtIndex:CC_RINGTONE] objectAtIndex:0] setVisible:enable];
    [[[personStructureManager.tableStructure objectAtIndex:CC_RINGTONE] objectAtIndex:1] setVisible:enable];
    
    //Mutate the add-address button
    [[[personStructureManager.tableStructure objectAtIndex:CC_ADDRESS] lastObject] setVisible:enable];

    //Mutate the address fields
    for (NBPersonCellAddressInfo * addressInfo in [personStructureManager.tableStructure objectAtIndex:CC_ADDRESS])
    {
        NBAddressCell * addressCell = [addressInfo getAddressCell];
        [addressCell setEditing:enable];
    }
    
#pragma mark - Determine rows to show that have a value
    //Determine row visibility
    [personStructureManager determineRowVisibility:enable];
    
    //Set the editing
    [self.tableView setEditing:enable animated:YES];
    
    //Switch the label of IM labels
    [personStructureManager switchIMLabels:enable];
    
    //Reload the following sections (only after the table's been initially loaded
    if (tableViewHasLoaded)
    {
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
        [indexSet addIndex:CC_FILLER];
        [indexSet addIndex:CC_NAME];
        [indexSet addIndex:CC_NUMBER];
        [indexSet addIndex:CC_EMAIL];
        [indexSet addIndex:CC_RINGTONE];
        [indexSet addIndex:CC_HOMEPAGE];
        [indexSet addIndex:CC_SOCIAL];
        [indexSet addIndex:CC_IM];
        [indexSet addIndex:CC_ADDRESS];
        [indexSet addIndex:CC_OTHER_DATES];
        [indexSet addIndex:CC_RELATED_CONTACTS];
        [indexSet addIndex:CC_NOTES];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        
        //Reload the table without calling 'reloadData' for smooth animation. Can you believe this loophole in the API does this? 
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
    else
    {
        tableViewHasLoaded = YES;
    }
}

#pragma mark - Set name label
- (void)setNameLabel
{
    //Measure variables
    UIFont *boldFont = [UIFont boldSystemFontOfSize:18];  //Font for bold name part
    UIFont *regularFont = [UIFont systemFontOfSize:14];   //Font for regular name part
    int totalLabelHeight = 0;
    
    //Build up and measure the bold component
    NSMutableString * boldNameString = [NSMutableString string];
    NSMutableString * completeString = [NSMutableString string];
    
    //Display the name
    NSArray * nameArray = [personStructureManager.tableStructure objectAtIndex:CC_NAME];
    NSString * namePrefix =  [[nameArray objectAtIndex:NC_PREFIX] textValue];
    NSString * nameFirst = [[nameArray objectAtIndex:NC_FIRST_NAME] textValue];
    NSString * nameMiddle = [[nameArray objectAtIndex:NC_MIDDLE_NAME] textValue];
    NSString * nameLast = [[nameArray objectAtIndex:NC_LAST_NAME] textValue];
    NSString * nameSuffix = [[nameArray objectAtIndex:NC_SUFFIX] textValue];
    if ([namePrefix length] > 0)
    {
        [boldNameString appendFormat:@"%@ ", namePrefix];
    }
    if ([nameFirst length] > 0)
    {
        [boldNameString appendFormat:@"%@ ", nameFirst];
    }
    if ([nameMiddle length] > 0)
    {
        [boldNameString appendFormat:@"%@ ", nameMiddle];
    }
    if ([nameLast length] > 0)
    {
        [boldNameString appendFormat:@"%@ ", nameLast];
    }
    if ([nameSuffix length] > 0)
    {
        [boldNameString appendFormat:@"%@ ", nameSuffix];
    }
    
    //Measure the bold part
    totalLabelHeight = [self measureLabelHeight:boldNameString usingFont:boldFont];
    
    //Build up and measure the phonetic regular name-string
    NSString * phoneticFirst = [[nameArray objectAtIndex:NC_PHONETIC_FIRST] textValue];
    NSString * phoneticLast = [[nameArray objectAtIndex:NC_PHONETIC_LAST] textValue];
    NSString * phoneticString;
    if ([phoneticFirst length] > 0 && [phoneticLast length] > 0)
    {
        phoneticString = [NSString stringWithFormat:@"%@ %@", phoneticFirst, phoneticLast];
    }
    else if ([phoneticFirst length] > 0)
    {
        phoneticString = [NSString stringWithFormat:@"%@", phoneticFirst];
    }
    else if ([phoneticLast length] > 0)
    {
        phoneticString = [NSString stringWithFormat:@"%@", phoneticLast];
    }    
    //Measure the phonetic part
    totalLabelHeight += [self measureLabelHeight:phoneticString usingFont:regularFont];

    //Build up the nickname
    NSString * nickName = [[nameArray objectAtIndex:NC_NICKNAME] textValue];
    if ([nickName length] > 0)
    {
        nickName = [NSString stringWithFormat:@"“%@”", nickName];
    }
    //Measure the nickname
    totalLabelHeight += [self measureLabelHeight:nickName usingFont:regularFont];
    
    //Read the job title & department
    NSString * jobTitle = [[nameArray objectAtIndex:NC_JOB_TITLE] textValue];
    NSString * department = [[nameArray objectAtIndex:NC_DEPARTMENT] textValue];
    NSString * jobTitleAndDepartment;
    if ([jobTitle length] > 0 && [department length])
    {
        jobTitleAndDepartment = [NSString stringWithFormat:@"%@ - %@", jobTitle, department];
    }
    else if ([jobTitle length] > 0)
    {
        jobTitleAndDepartment = [NSString stringWithFormat:@"%@", jobTitle];
    }
    else if ([department length] > 0)
    {
        jobTitleAndDepartment = [NSString stringWithFormat:@"%@", department];
    }
    //Measure the job title and department
    totalLabelHeight += [self measureLabelHeight:jobTitleAndDepartment usingFont:regularFont];
    
    //Measure the company
    NSString * company = [[nameArray objectAtIndex:NC_COMPANY] textValue];
    totalLabelHeight += [self measureLabelHeight:company usingFont:regularFont];

    //Create the attributed string (text + attributes)
    [completeString attemptToAppend:boldNameString withNewline:YES];
    [completeString attemptToAppend:phoneticString withNewline:YES];
    [completeString attemptToAppend:nickName withNewline:YES];
    [completeString attemptToAppend:jobTitleAndDepartment withNewline:YES];
    [completeString attemptToAppend:company withNewline:YES];
    
    //Build up the final string to set
    NSDictionary * boldAttributes       = [NSDictionary dictionaryWithObjectsAndKeys:
                                           boldFont, NSFontAttributeName,
                                           [UIColor blackColor], NSForegroundColorAttributeName, nil];
    NSDictionary * regularAttributes    = [NSDictionary dictionaryWithObjectsAndKeys:
                                           regularFont, NSFontAttributeName,
                                           [UIColor colorWithRed:76/255.0f green:86/255.0f blue:108/255.0f alpha:1.0f], NSForegroundColorAttributeName,nil];
    
    //If there is no name-component available, display the best available property
    NSMutableAttributedString * attributedText;
    if ([completeString length] == 0)
    {
        NSString * availableProperty = [NBContact getSortingProperty:contact.contactRef mustFormatNumber:YES];
        if (availableProperty != nil && [availableProperty length] > 0)
        {
            [completeString appendString:availableProperty];
        }
    }

    //Set the attributed text
    attributedText = [[NSMutableAttributedString alloc] initWithString:completeString attributes:boldAttributes];
    
    //Complete the bold and regular-font string
    attributedText = [[NSMutableAttributedString alloc] initWithString:completeString attributes:boldAttributes];
    [attributedText setAttributes:regularAttributes range:NSMakeRange([boldNameString length],
                                                                      [completeString length] - [boldNameString length])];

    //Set the text in the label
    [nameLabel setAttributedText:attributedText];
    
    //Set the new frame
    [nameLabel setBackgroundColor:[UIColor clearColor]];
    CGRect nameRect = nameLabel.frame;
    totalLabelHeight = totalLabelHeight < SIZE_NAME_LABEL_MIN ? SIZE_NAME_LABEL_MIN : totalLabelHeight;
    nameLabel.frame = CGRectMake( nameRect.origin.x, nameRect.origin.y, nameRect.size.width, totalLabelHeight);
    
    //Set the cell height as well, so we have space to draw the label
    tableHeaderSize = totalLabelHeight + 20;
}


- (int)measureLabelHeight:(NSString*)stringToMeasure usingFont:(UIFont*)font
{
    [nameLabel setFont:font];
    [nameLabel setText:stringToMeasure];
    
    nameLabel.numberOfLines = 0;
    nameLabel.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize size = [nameLabel sizeThatFits:nameLabel.frame.size];

    return ceilf(size.height);
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [personStructureManager.tableStructure count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    NSInteger numRows = 0;
    //If we're editing the contact, show the name cells
    if (section == CC_FILLER)
    {
        //If we're editing, hide this filler
        numRows = ( tableView.isEditing) ? 0 : 1;
    }
    //Rows for known contacts
    else if (section == CC_NAME)
    {
        //Hide these cells when not editing
        if ([self.tableView isEditing])
        {
            numRows = [[personStructureManager getVisibleRows:YES forSection:section] count];
        }
        else
        {
            numRows = 0;
        }
    }
    else if (section == CC_NUMBER || section == CC_EMAIL || section == CC_HOMEPAGE)
    {
        numRows = [[personStructureManager getVisibleRows:YES forSection:section] count];
    }
    else if (section == CC_OTHER_DATES)
    {
        numRows = [[personStructureManager.tableStructure objectAtIndex:CC_OTHER_DATES] count] - (self.tableView.isEditing ? 0 : 1);
    }
    else
    {
        numRows = [[personStructureManager getVisibleRows:YES forSection:section] count];
    }
    
    //Return the number of rows
    return numRows;
}


- (UITableViewCell*)getTableViewCellForIndexPath:(NSIndexPath*)indexPath
{
    NBPersonCellInfo * cellInfo = [personStructureManager getVisibleCellForIndexPath:indexPath];
    switch (indexPath.section)
    {
        case CC_NAME:
        {
            NBNameTableViewCell * cell = [[NBNameTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            [cell registerForKeyboardDismiss];
            
            //Create a textfield for the cell
            UITextField * textField = textField = [[UITextField alloc] initWithFrame:CGRectMake(34, 0,
                                                                                                SIZE_TEXTVIEW_WIDTH, cell.frame.size.height)];
            [textField setBackgroundColor:[UIColor clearColor]];
            [textField setTextAlignment:NSTextAlignmentLeft];
            [textField setReturnKeyType:UIReturnKeyDone];
            [textField setEnabled:self.tableView.editing];
            [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
            [textField setFont:[UIFont boldSystemFontOfSize:14]];
            [textField setPlaceholder:cellInfo.textfieldPlaceHolder];
            [textField setText:cellInfo.textValue];
            [textField setTag:indexPath.section];
            [textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [cell addSubview:textField];
            
            //If the value was merged
            if (cellInfo.isMergedField)
            {
                [textField setTextColor:FONT_COLOR_MERGED];
            }
            
            //Set the section type
            [cell setSection:indexPath.section];
            
            //Remember the textfield
            [cell setCellTextfield:textField];
            cellInfo.tableViewCell = cell;
            [cell bringSubviewToFront:textField];

            return cell;
        }
        case CC_NUMBER:
        case CC_EMAIL:
        case CC_HOMEPAGE:
        case CC_RELATED_CONTACTS:
        case CC_SOCIAL:
        {
            NBDetailLineSeparatedCell * cell = [[NBDetailLineSeparatedCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            [cell registerForKeyboardDismiss];
            
            //Set the section type
            [cell setSection:indexPath.section];
            
            //Build up the title label
            UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 10.5, 75, cell.contentView.bounds.size.height/2)];
            [label setTextAlignment:NSTextAlignmentRight];
            [label setTextColor:FONT_COLOR_LABEL];
            [label setFont:FONT_LABEL];
            [label setBackgroundColor:[UIColor clearColor]];            
//            [label setHighlightedTextColor:[UIColor whiteColor]];
            [cell setCellLabel:label];
            [cell.contentView addSubview:label];

            //Make the input textfield
            UITextField * textField = [[UITextField alloc]initWithFrame:CGRectMake(85, 0, SIZE_TEXTVIEW_WIDTH, cell.frame.size.height)];
            [textField setBackgroundColor:[UIColor clearColor]];
            [textField setClearButtonMode:(indexPath.section != CC_RELATED_CONTACTS ? UITextFieldViewModeWhileEditing : UITextFieldViewModeNever)];
            [textField setFont:[UIFont boldSystemFontOfSize:14]];
            [textField setPlaceholder:cellInfo.textfieldPlaceHolder];
            if (indexPath.section == CC_NUMBER)
            {
                NSString * number = cellInfo.textValue;
#ifndef NB_STANDALONE
                number = [[NBAddressBookManager sharedManager].delegate formatNumber:cellInfo.textValue];
#endif
                [textField setText:number];
            }
            else
            {
                [textField setText:cellInfo.textValue];
            }
            [textField setEnabled:self.tableView.isEditing];
            [textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [textField setTag:indexPath.section];
            [textField setTextColor:[UIColor blackColor]];
            [cell.contentView addSubview:textField];
            
            //Disallow selection
            [cell setTag:0];
            
            //If the value was merged
            if (cellInfo.isMergedField)
            {
                [textField setTextColor:FONT_COLOR_MERGED];
            }
            
            //Remember the textfield and cell
            cellInfo.tableViewCell = cell;
            cell.cellTextfield = textField;

            return cell;
        }
        case CC_IM:
        {
            NBPersonIMCell * cell = [[NBPersonIMCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.accessoryType = UITableViewCellAccessoryNone;
            [cell registerForKeyboardDismiss];
            
            //Build up the title label
            UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 10.5, 75, cell.contentView.bounds.size.height/2)];
            [label setTextAlignment:NSTextAlignmentRight];
            [label setTextColor:FONT_COLOR_LABEL];
            [label setFont:FONT_LABEL];
            [label setBackgroundColor:[UIColor clearColor]];
            cell.cellLabel = label;
            [cell.contentView addSubview:label];
            
            //Set the section type
            [cell setSection:indexPath.section];

            //Make the input textfield
            UITextField * textField = [[UITextField alloc]initWithFrame:CGRectMake(85, 0, SIZE_TEXTVIEW_WIDTH, cell.frame.size.height)];
            [textField setBackgroundColor:[UIColor clearColor]];
            [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
            [textField setFont:[UIFont boldSystemFontOfSize:14]];
            [textField setPlaceholder:cellInfo.textfieldPlaceHolder];
            [textField setText:cellInfo.textValue];
            [textField setEnabled:self.tableView.isEditing];
            [textField setTag:indexPath.section];
            [textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [cell.contentView addSubview:textField];
            
            //If the value was merged
            if (cellInfo.isMergedField)
            {
                [textField setTextColor:FONT_COLOR_MERGED];
            }
            
            //Remember the textfield and cell
            cellInfo.tableViewCell = cell;
            cell.cellTextfield = textField;

            return cell;
        }
        case CC_OTHER_DATES:
        case CC_BIRTHDAY:
        {
            //Create the cell and label for date
            NBDateCell * dateCell = [[NBDateCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            [dateCell registerForKeyboardDismiss];
            
            //Build up the title label
            UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 10.5, 75, dateCell.contentView.bounds.size.height/2)];
            [label setTextAlignment:NSTextAlignmentRight];
            [label setTextColor:FONT_COLOR_LABEL];
            [label setFont:FONT_LABEL];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setText:cellInfo.labelTitle];
            dateCell.cellLabel = label;
            [dateCell.contentView addSubview:label];
            
            //Set the section type
            [dateCell setSection:indexPath.section];
            
            //Create a textfield for the date
            UITextField * textField = [[UITextField alloc]initWithFrame:CGRectMake(85, 0, SIZE_TEXTVIEW_WIDTH, dateCell.frame.size.height)];
            [textField setBackgroundColor:[UIColor clearColor]];
            [textField setFont:[UIFont boldSystemFontOfSize:14]];
            [textField setPlaceholder:cellInfo.textfieldPlaceHolder];
            if (cellInfo.dateValue != nil)
            {
                [textField setText:[NSString formatToShortDate:cellInfo.dateValue]];
            }
            textField.tag = indexPath.section;
            [textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [dateCell.contentView addSubview:textField];
            [textField setEnabled:YES];
            [textField setUserInteractionEnabled:NO];
            
            //Remember the cell and textfield
            [dateCell setCellTextfield:textField];
            [cellInfo setTableViewCell:dateCell];

            return dateCell;
        }
        case CC_NOTES:
        {
            //Create the cell and textview
            NBNotesCell * notesCell = [[NBNotesCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            [notesCell registerForKeyboardDismiss];
            
            //Build up the title label
            UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 10.5, 75, notesCell.contentView.bounds.size.height/2)];
            [label setTextAlignment:NSTextAlignmentRight];
            [label setTextColor:FONT_COLOR_LABEL];
            [label setFont:[UIFont boldSystemFontOfSize:13]];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setText:cellInfo.labelTitle];
            [notesCell.cellLabel setText:cellInfo.labelTitle];
            [notesCell.contentView addSubview:label];
            
            //Set the section type
            [notesCell setSection:indexPath.section];
            
            //Determine the cell height
            int notesHeight = [self getNotesFieldSize];
            if (notesHeight < SIZE_CELL_HEIGHT*1.2f)
                notesHeight = SIZE_CELL_HEIGHT*1.2f;

            //Make the input textfield
            UITextView * textView = [[UITextView alloc]initWithFrame:CGRectMake(90, 4,
                                                                                SIZE_TEXTVIEW_WIDTH, notesHeight)];
            [textView setBackgroundColor:[UIColor clearColor]];
            [textView setScrollEnabled:NO];
            [textView setFont:FONT_NOTES];
            [textView setUserInteractionEnabled:YES];
            textView.tag = indexPath.section;
            textView.editable = NO;
            [textView setText:cellInfo.textValue];
            [notesCell.contentView addSubview:textView];
            
            //If the value was merged
            if (cellInfo.isMergedField)
            {
                [textView setTextColor:FONT_COLOR_MERGED];
            }
            
            //Remember the textview and cell
            [cellInfo setTableViewCell:notesCell];
            [notesCell setCellTextview:textView];

            return notesCell;
        }
        case CC_CALLER_ID:
        {
            NBPersonIMCell * cell = [[NBPersonIMCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            [cell registerForKeyboardDismiss];
            
            //Build up the title label
            UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 10.5, 75, cell.contentView.bounds.size.height/2)];
            [label setTextAlignment:NSTextAlignmentRight];
            [label setTextColor:FONT_COLOR_LABEL];
            [label setFont:FONT_LABEL];
            [label setBackgroundColor:[UIColor clearColor]];
            cell.cellLabel = label;
            [cell.contentView addSubview:label];
            
            //Set the section type
            [cell setSection:indexPath.section];
            
            //Make the input textfield
            UITextField * textField = [[UITextField alloc]initWithFrame:CGRectMake(85, 0, SIZE_TEXTVIEW_WIDTH, cell.frame.size.height)];
            [textField setBackgroundColor:[UIColor clearColor]];
            [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
            [textField setFont:[UIFont boldSystemFontOfSize:14]];
            [textField setPlaceholder:cellInfo.textfieldPlaceHolder];
            [textField setText:cellInfo.textValue];
            [textField setEnabled:self.tableView.isEditing];
            [textField setTag:indexPath.section];
            [textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [cell.contentView addSubview:textField];
            
            //If the value was merged
            if (cellInfo.isMergedField)
            {
                [textField setTextColor:FONT_COLOR_MERGED];
            }
            
            //Remember the textfield and cell
            cellInfo.tableViewCell = cell;
            cell.cellTextfield = textField;
            
            return cell;
        }
        default:
            return nil;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Remember the cell if we do not have it yet
    NBPersonCellInfo* cellInfo = [personStructureManager getVisibleCellForIndexPath:indexPath];

    //Only the name-cells are indented extra
    if (indexPath.section == CC_FILLER)
    {
        //Get the cell
        NSString * cellIdentifier = @"CellFiller";
        UITableViewCell *cell = cellInfo.tableViewCell;
    
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cellInfo.tableViewCell = cell;
            [cell setHidden:YES];
        }
        return cell;
    }
    else if (indexPath.section == CC_NAME)
    {
        //Get the cell
        NBNameTableViewCell *cell = [cellInfo getNameTableViewCell];
        if (cell == nil)
        {
            cell = (NBNameTableViewCell*)[self getTableViewCellForIndexPath:indexPath];
            [cellInfo setTableViewCell:cell];
        }
        
        //If we're editing, hide these cells to show the name-label
        [cell setHidden:!tableView.editing];

        return cell;
    }
    //Handle detail-cells the same way
    else if (indexPath.section == CC_NUMBER ||
            indexPath.section == CC_EMAIL ||
            indexPath.section == CC_HOMEPAGE ||
            indexPath.section == CC_RELATED_CONTACTS ||
            indexPath.section == CC_SOCIAL)
    {
        NBDetailLineSeparatedCell * cell = [cellInfo getDetailCell];
        if (cell == nil)
        {
            cell = (NBDetailLineSeparatedCell*)[self getTableViewCellForIndexPath:indexPath];
            [cellInfo setTableViewCell:cell];
        }
        
        //For related contacts, also show the accessory view
        if (indexPath.section == CC_RELATED_CONTACTS)
        {
            [cell setEditingAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
        }
        
        //Always reload the title, since the user could have selected a new one
        [cell.cellLabel setText:cellInfo.labelTitle];
        return cell;
    }
    else if (indexPath.section == CC_RINGTONE)
    {
        NBPersonFieldTableCell * cell = [cellInfo getPersonFieldTableCell];
        UILabel * label;
        if (cell == nil)
        {
            cell = [[NBPersonFieldTableCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            [cell registerForKeyboardDismiss];
            
            //Build up the title label
            label = [[UILabel alloc]initWithFrame:CGRectMake(0, 10.5, 75, cell.contentView.bounds.size.height/2)];
            [label setTextAlignment:NSTextAlignmentRight];
            [label setTextColor:FONT_COLOR_LABEL];
            [label setFont:FONT_LABEL];
            [label setBackgroundColor:[UIColor clearColor]];
            cell.cellLabel = label;
            [cell.cellLabel setText:cellInfo.labelTitle];
            [cell.contentView addSubview:label];
            
            //Set the section type
            [cell setSection:indexPath.section];
            
            //Make the input textfield
            UITextField * textField = [[UITextField alloc]initWithFrame:CGRectMake(
                                                                                   85,
                                                                                   0,
                                                                                   SIZE_TEXTVIEW_WIDTH,
                                                                                   cell.contentView.bounds.size.height)];
            [textField setBackgroundColor:[UIColor clearColor]];
            [textField setFont:[UIFont boldSystemFontOfSize:15]];
            [textField setEnabled:NO];            
            textField.tag = indexPath.section;
            [textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];            
            textField.delegate = self;
            [cell.contentView addSubview:textField];
            
            //If the value was merged
            if (cellInfo.isMergedField)
            {
                [textField setTextColor:FONT_COLOR_MERGED];
            }
            
            //Give the cell an accessory type
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            [cell setEditingAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            
            //Remember the textfield and cell
            cellInfo.tableViewCell = cell;
            cell.cellTextfield = textField;
        }        
        
        //Always reload the value, since the user could have selected a new one
        [cell.cellTextfield setText:cellInfo.textValue];
        return cell;
    }
    else if (indexPath.section == CC_ADDRESS)
    {
        //In case of addresses, we have a little bit more extended info
        NBPersonCellAddressInfo * addressInfo = (NBPersonCellAddressInfo*)cellInfo;        
        NBAddressCell * addressCell =  [cellInfo getAddressCell];
        if (addressCell == nil)
        {
            addressCell = [[NBAddressCell alloc]initWithStyle:UITableViewCellStyleDefault];

            //Register for dismissal
            [addressCell registerForKeyboardDismiss];
            
            //Set the section type
            [addressCell setSection:indexPath.section];
            
            if (indexPath.row == [[personStructureManager.tableStructure objectAtIndex:CC_ADDRESS] count] - 1)
            {
                //The add-cell is created once and hidden rest of the time
                [addressCell.textLabel setText:addressInfo.labelTitle];
                [addressCell.textLabel setTextColor:FONT_COLOR_LABEL];
//                [addressCell.textLabel setHighlightedTextColor:[UIColor whiteColor]];
                [addressCell.textLabel setFont:[UIFont boldSystemFontOfSize:13]];
                
                //Hide it when we're not editing
                [addressInfo setVisible:tableView.isEditing];
            }
            else
            {                
                //Set the label
                UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 10.5, 75, addressCell.contentView.bounds.size.height/2)];
                [label setTextAlignment:NSTextAlignmentRight];
                [label setTextColor:FONT_COLOR_LABEL];
//                [label setHighlightedTextColor:[UIColor whiteColor]];
                [label setFont:FONT_LABEL];
                [label setBackgroundColor:[UIColor clearColor]];
                addressCell.cellLabel = label;
                [addressCell.contentView addSubview:label];
                
                //Set the vertical separator
                addressCell.lineView = [[UIView alloc] initWithFrame:CGRectMake((addressCell.contentView.bounds.size.width/4), 0, 1, [NBAddressCell determineAddressCellHeight:addressInfo.countryCode] + ( [addressInfo.streetLines count] * SIZE_CELL_HEIGHT))];
                addressCell.lineView.backgroundColor = FONT_COLOR_LIGHT_GREY;
                [addressCell.lineView setHidden:!tableView.isEditing];
                [addressCell.contentView addSubview:addressCell.lineView];
                
                //Format the cell for additional fields and separators
                [addressCell formatUsingType:addressInfo.countryCode];
                
                //Set any pre-known address info
                [addressCell.cityTextfield setText:addressInfo.city];
                [addressCell.stateTextfield setText:addressInfo.state];
                [addressCell.ZIPTextfield setText:addressInfo.ZIP];
                [addressCell.countryTextfield setText:addressInfo.country];
                for (NSString * street in addressInfo.streetLines)
                {
                    //Fill in the last street field
                    [[addressCell.streetTextfields lastObject] setText:street];
                    
                    //Enter a new street field
                    [addressCell addTextfieldForPosition:-1 andLineType:LT_FULL andTextfieldType:TT_STREET];
                }
                
                //Hide/show the address cell
                [addressCell setEditing:self.tableView.editing];
            }
            
            //Remember the cell
            [addressInfo setTableViewCell:addressCell];
        }
        
        //Update the label in case a new value was selected
        [addressCell.cellLabel setText:addressInfo.labelTitle];
        return addressCell;
    }
    else if ( indexPath.section == CC_BIRTHDAY || indexPath.section == CC_OTHER_DATES)
    {
        NBDateCell * dateCell = [cellInfo getDateCell];
        if (dateCell == nil)
        {
            dateCell = (NBDateCell*)[self getTableViewCellForIndexPath:indexPath];
            [cellInfo setTableViewCell:dateCell];
        }
        
        //Always reload the title, since the user could have selected a new one
        [dateCell.cellLabel setText:cellInfo.labelTitle];
        
        return dateCell;
    }
    else if ( indexPath.section == CC_NOTES)
    {
        NBNotesCell * notesCell = [cellInfo getNotesCell];
        if (notesCell == nil)
        {
            notesCell = (NBNotesCell*)[self getTableViewCellForIndexPath:indexPath];
            [cellInfo setTableViewCell:notesCell];
        }
        
        //Always allow notes-editing
        [notesCell.cellTextview setUserInteractionEnabled:YES];
        
        //Reposition the textview
        CGPoint centerPoint = notesCell.cellTextview.center;
        [notesCell.cellTextview setCenter:centerPoint];
        return notesCell;
    }
    else if (indexPath.section == CC_IM)
    {
        NBPersonIMCell * cell = [cellInfo getIMCell];
        if (cell == nil)
        {
            cell = (NBPersonIMCell*)[self getTableViewCellForIndexPath:indexPath];
            [cellInfo setTableViewCell:cell];
        }

        //Always reload the title, since the user could have selected a new one
        [cell.cellLabel setText:cellInfo.labelTitle];
        [cell.typeLabel setText:cellInfo.IMType];
        return cell;
    }
    else if (indexPath.section == CC_CALLER_ID)
    {
        NBPersonIMCell * cell = [cellInfo getIMCell];
        if (cell == nil)
        {
            cell = (NBPersonIMCell*)[self getTableViewCellForIndexPath:indexPath];
            [cellInfo setTableViewCell:cell];
        }
        
        //Always reload the title, since the user could have selected a new one
        [cell.cellLabel setText:cellInfo.labelTitle];
        [cell.typeLabel setText:cellInfo.IMType];
        return cell;
    }

    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //If we're editing, clear some space for the name label
    if (indexPath.section == CC_FILLER)
    {
        return tableHeaderSize;
    }
    //If it's the notes-field, dynamically determine the height
    else if (indexPath.section == CC_NOTES)
    {
        //Resize the textfield based on editing or not
        NBPersonCellInfo * cellInfo = [[personStructureManager.tableStructure objectAtIndex:CC_NOTES] objectAtIndex:0];
        int textViewSize = [self getNotesFieldSize];
        int cellheight = textViewSize < SIZE_CELL_HEIGHT ? SIZE_CELL_HEIGHT : textViewSize;
        cellheight += (SIZE_CELL_HEIGHT / 2);

        //Get the textview
        UITextView * textView = [cellInfo getNotesCell].cellTextview;
        if (textView != nil)
        {
            //Resize based on tableview editing
            CGRect textFrame = textView.frame;
            CGSize textSize = textView.frame.size;
            textSize.width = SIZE_TEXTVIEW_WIDTH;
            
            //Resize based on the content
            textSize.height = textViewSize;
            textView.frame = CGRectMake(textFrame.origin.x, textFrame.origin.y, textSize.width, textSize.height);
            
            //Resize the line as well (in case it exists)
            [UIView animateWithDuration:0.3f
                                  delay:0.0f
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations: ^(void){
                                 NBNotesCell * notesCell = [cellInfo getNotesCell];
                                 UIView * lineView = notesCell.lineView;
                                 CGRect lineFrame = lineView.frame;
                                 lineFrame.size.height = cellheight;
                                 [lineView setFrame:lineFrame];
                             }
                             completion:nil];
        }
        return cellheight;
    }
    else if (indexPath.section == CC_IM || indexPath.section == CC_CALLER_ID)
    {
        //Return double-size when editing to allow the user to change the IM-type
        return self.tableView.isEditing ? 2*SIZE_CELL_HEIGHT : 1*SIZE_CELL_HEIGHT;
    }
    //In case of address cells, the height is determined based on type and number of streets entered
    else if (indexPath.section == CC_ADDRESS)
    {
        NSArray * addressCells = [personStructureManager.tableStructure objectAtIndex:CC_ADDRESS];
        NBPersonCellAddressInfo * addressInfo = (NBPersonCellAddressInfo*)[addressCells objectAtIndex:indexPath.row];
        int cellHeight;
        if (indexPath.row == [addressCells count]-1)
        {
            //If it is the last cell, return default height
            cellHeight = SIZE_CELL_HEIGHT;
        }
        else
        {
            //If we're editing, return the size based on address celltype plus the number of streets entered
            if (self.tableView.editing)
            {
                cellHeight = [NBAddressCell determineAddressCellHeight:addressInfo.countryCode] + ([addressInfo.streetLines count] * SIZE_CELL_HEIGHT);
            }
            //Else return the labelsize plus half a cell-height
            else
            {                
                NSString * representationString = [NBAddressCell getStringForStreets:addressInfo.streetLines andState:addressInfo.state andZipCode:addressInfo.ZIP andCity:addressInfo.city andCountry:addressInfo.country];
                CGSize labelSize = [representationString sizeWithFont:FONT_ADDRESS
                                                    constrainedToSize:CGSizeMake(WIDTH_TEXTFIELD, 300)
                                                        lineBreakMode:NSLineBreakByWordWrapping];
                cellHeight = labelSize.height + (SIZE_CELL_HEIGHT/2);
            }
        }
        
        //Resize the vertical lineview of the cell as well
        UIView * lineView =  [addressInfo getAddressCell].lineView;
        CGRect lineFrame = lineView.frame;
        lineFrame.size.height = cellHeight;
        lineView.frame = lineFrame;
        
        return cellHeight;
    }
    //Else just return the default height]
    else
    {
        return SIZE_CELL_HEIGHT;
    }
}

//Clear tableview header and footer-height to make sure hidden sections don't take up space
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    //In case of the filler, no visible rows or the hidden name-cells when not editing, no header
    if(([[personStructureManager getVisibleRows:YES forSection:section] count] == 0
       || section == CC_FILLER
       || (section == CC_NAME && ![tableView isEditing])) )
    {
        return 0.01f;
    }
    else
    {
        return UITableViewAutomaticDimension;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    //In case of the filler, no visible rows or the hidden name-cells when not editing, no footer
    if(([[personStructureManager getVisibleRows:YES forSection:section] count] == 0
       || section == CC_FILLER
       || (section == CC_NAME && ![tableView isEditing])) )
    {
        return 0.01f;
    }
    else
    {
        return UITableViewAutomaticDimension;
    }
}

#pragma mark - Notes field size measurement
- (int)getNotesFieldSize
{
    //Determine the size of the textview based on the text
    int notesFieldSize = 0;
    NBPersonCellInfo * notesInfo = [[personStructureManager.tableStructure objectAtIndex:CC_NOTES] objectAtIndex:0];
    if (notesInfo != nil)
    {
        NSString * notesText = [notesInfo textValue];
        if ([notesText length] == 0)
            notesFieldSize = SIZE_CELL_HEIGHT;
        else
            notesFieldSize = [notesText sizeWithFont:FONT_NOTES constrainedToSize:CGSizeMake(SIZE_TEXTVIEW_WIDTH, 5000) lineBreakMode:NSLineBreakByWordWrapping].height;
    }
    
    notesFieldSize += (SIZE_CELL_HEIGHT / 2);
    
    return notesFieldSize;
}


#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NBPersonCellInfo * cellInfo = [personStructureManager getVisibleCellForIndexPath:indexPath];

    if (indexPath.section != CC_CALLER_ID)
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    //Determine if we should continue from the delegate
    BOOL shouldContinue = YES;
    if (personViewDelegate != nil && !self.tableView.isEditing)
    {
        //Determine the property and, in case of multivalue, the identifier
        ABPropertyID propertyID = 0;
        ABMultiValueIdentifier multiRefIdentifier = kABMultiValueInvalidIdentifier;
        switch (indexPath.section) {
            case CC_NUMBER:
            {
                //Set the property
                propertyID = kABPersonPhoneProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, propertyID)), indexPath.row);
                break;
            }
            case CC_EMAIL:
            {
                //Set the property
                propertyID = kABPersonEmailProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, propertyID)), indexPath.row);
                break;
            }
            case CC_HOMEPAGE:
            {
                //Set the property
                propertyID = kABPersonURLProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, propertyID)), indexPath.row);
                break;
            }
            case CC_ADDRESS:
            {
                //Set the property
                propertyID = kABPersonAddressProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, propertyID)), indexPath.row);
                break;
            }
            case CC_BIRTHDAY:
            {
                //Set the property
                propertyID = kABPersonBirthdayProperty;
                break;
            }
            case CC_OTHER_DATES:
            {
                //Set the property
                propertyID =kABPersonDateProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, kABPersonDateProperty)), indexPath.row);
                break;
            }
            case CC_RELATED_CONTACTS:
            {
                //Set the property
                propertyID = kABPersonRelatedNamesProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, propertyID)), indexPath.row);
                break;
            }
            case CC_SOCIAL:
            {
                //Set the property
                propertyID = kABPersonSocialProfileProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, propertyID)), indexPath.row);
                break;
            }
            case CC_IM:
            {
                //Set the property
                propertyID = kABPersonInstantMessageProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, propertyID)), indexPath.row);
                break;
            }
            case CC_NOTES:
            {
                //Set the property
                propertyID = kABPersonNoteProperty;
                break;
            }
            case CC_CALLER_ID:
            {
                propertyID = 0;
                break;
            }
            default:
            {
                break;
            }
        }

        //Determine if we should continue according to the person delegate
        if (shouldContinue && self.personViewDelegate != nil)
        {
            shouldContinue = [self.personViewDelegate personViewController:self
                                       shouldPerformDefaultActionForPerson:self.contact.contactRef
                                                                  property:propertyID
                                                                identifier:multiRefIdentifier];
        }
    }

    if (shouldContinue)
    {
        switch (indexPath.section)
        {
            case CC_NUMBER:
            {
                NSString * phoneNumber = [((NBPersonCellInfo*)[[personStructureManager.tableStructure objectAtIndex:CC_NUMBER] objectAtIndex:indexPath.row]) textValue];
                [NBContact makePhoneCall:phoneNumber withContactID:[self contactId] completion:^(CallableData* selectedCallable)
                {
                    if (selectedCallable != nil)
                    {
                        NSIndexPath* callerIdIndexPath = [NSIndexPath indexPathForRow:0 inSection:CC_CALLER_ID];
                        NBPersonIMCell* cell = (NBPersonIMCell*)[self.tableView cellForRowAtIndexPath:callerIdIndexPath];
                        cell.cellTextfield.text = selectedCallable.name;
                    }
                }];

                if ([self isKindOfClass:[NBRecentContactViewController class]])
                {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                                   dispatch_get_main_queue(), ^
                                   {
                                       [self.navigationController popToRootViewControllerAnimated:NO];
                                   });
                }
                break;
            }
            case CC_EMAIL:
            {
                NSString* text = [cellInfo.textValue stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
                NSURL*    url  = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"mailto:?to=%@", text]];

                [[UIApplication sharedApplication] openURL:url];
                break;
            }
            case CC_RINGTONE:
            {
                //Set the type and load the list of available ringtones
                [NBValueListTableViewController setLabelType:(indexPath.row == 0 ? LT_RINGTONE : LT_VIBRATION)];
                [NBValueListTableViewController setTargetIndexPath:indexPath];
                [self displayValuePicker];
                break;
            }
            case CC_HOMEPAGE:
            {
                NSString* text = [cellInfo.textValue stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
                NSURL*    url  = [[NSURL alloc] initWithString:text];

                if (url.scheme.length == 0)
                {
                    text = [@"http://" stringByAppendingString:text];
                    url  = [NSURL URLWithString:text];
                }

                [[UIApplication sharedApplication] openURL:url];
                break;
            }
            case CC_ADDRESS:
            {
                NBPersonCellAddressInfo * addressInfo = (NBPersonCellAddressInfo*)cellInfo;

                NSString* addressString = @"http://maps.apple.com/?q=";
                for (NSString* street in addressInfo.streetLines)
                {
                    addressString = [addressString stringByAppendingFormat:@"%@+", street];
                }

                if (addressInfo.city.length > 0)
                {
                    addressString = [addressString stringByAppendingFormat:@"%@+", addressInfo.city];
                }

                if (addressInfo.state.length > 0)
                {
                    addressString = [addressString stringByAppendingFormat:@"%@+", addressInfo.state];
                }

                if (addressInfo.ZIP.length > 0)
                {
                    addressString = [addressString stringByAppendingFormat:@"%@+", addressInfo.ZIP];
                }

                if (addressInfo.country.length > 0)
                {
                    addressString = [addressString stringByAppendingFormat:@"%@+", addressInfo.country];
                }

                addressString = [addressString stringByReplacingOccurrencesOfString:@" " withString:@"+"];

                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:addressString]];
                break;
            }
            case CC_OTHER_DATES:
            case CC_BIRTHDAY:
                break;

            case CC_SOCIAL:
            case CC_IM:
                //If we're editing, show the options. Else, attempt to 'launch' the cell
                break;
                
            case CC_CALLER_ID:
            {
                [[NBAddressBookManager sharedManager].delegate selectCallerIdForContactId:[self contactId]
                                                                     navigationController:self.navigationController
                                                                               completion:^(CallableData* selectedCallable)
                {
                    NBPersonIMCell* cell = (NBPersonIMCell*)cellInfo.tableViewCell;
                    cell.cellTextfield.text = selectedCallable.name;
                    
                    if ([[NBAddressBookManager sharedManager].delegate callerIdIsShownForContactId:[self contactId]])
                    {
                        cell.cellTextfield.placeholder = NSLocalizedString(@"CI_USES_DEFAULT", @"");
                    }
                    else
                    {
                        cell.cellTextfield.placeholder = NSLocalizedString(@"CI_IS_NOT_SHOWN", @"");
                    }

                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                }];
                break;
            }
            case CC_RELATED_CONTACTS:
                break;

            default:
                break;
        }
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    //In case of related contacts, do something. Else, just handle it as a tap
    if (indexPath.section == CC_RELATED_CONTACTS && self.tableView.isEditing)
    {
        //Remember the related-position
        indexPathForRelatedPerson = indexPath;
        
        //Display all contacts and allow the user to select an entry
        NBPeopleListViewController * listViewController = [[NBPeopleListViewController alloc]init];
        [listViewController setRelatedPersonDelegate:self];
        NBPeoplePickerNavigationController * navViewController = [[NBPeoplePickerNavigationController alloc]initWithRootViewController:listViewController];
        [self presentViewController:navViewController animated:YES completion:nil];
        
        //Indicate we merely are selecting a name
        [listViewController setAmSelectingName:YES];
        
        //Add a cancel-button for the navcontroller
        UIBarButtonItem * cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:listViewController action:@selector(cancelPressed)];
        [listViewController.navigationItem setRightBarButtonItem:cancelButtonItem];
    }
    //Forward this to row-selected
    else
    {
        UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell setTag:1];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
}


#pragma mark - Listen for selection of a related person
- (void)relatedPersonSelected:(NSString*)personName
{
    //Get the cell info
    NSMutableArray*   sectionArray = [personStructureManager.tableStructure objectAtIndex:CC_RELATED_CONTACTS];
    NBPersonCellInfo* cellInfo     = [sectionArray objectAtIndex:indexPathForRelatedPerson.row];
    
    //Set the name both in the model and textfield
    NSString* selectedName = personName;
    [cellInfo setTextValue:selectedName];
    [[[cellInfo getPersonFieldTableCell] cellTextfield] setText:selectedName];
    
    //If this is the last cell, insert one below    
    NBPersonCellInfo* newCellInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:NSLocalizedString(@"PH_NAME", @"") andLabel:NSLocalizedString([personStructureManager findNextLabelInArray:RELATED_ARRAY usingSource:sectionArray], @"")];
    [sectionArray addObject:newCellInfo];
}

#pragma mark - Displaying the value picker (the target has to be statically pre-set before this)
- (void)displayValuePicker
{
    //Get the active address textfield (if there is one)
    changingLabel = YES;
    
    //Allow the user to add a new name-field
    NBValueListTableViewController * valueListController = [[NBValueListTableViewController alloc]initWithStyle:UITableViewStyleGrouped];
    [valueListController setStructureManager:personStructureManager];
    UINavigationController * navController = [[UINavigationController alloc]initWithRootViewController:valueListController];
    [self presentViewController:navController animated:YES completion:nil];
}


- (void)delayedReloadTable:(NSIndexPath*)indexPath
{
    //Only if we're still editing
    if (self.tableView.isEditing)
    {
        //Make a check to see if a new field is being selected. If so, modify the index if it's before this one
        NSIndexPath * targetIndexPath = [NBValueListTableViewController getTargetIndexPath];
        if (targetIndexPath.section == indexPath.section && targetIndexPath.row > indexPath.row)
        {
            [NBValueListTableViewController setTargetIndexPath:[NSIndexPath indexPathForRow:targetIndexPath.row-1 inSection:targetIndexPath.section]];
        }
        
        //Reload the table
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}


#pragma mark - Contact mutation
//Support method to start and stop listening for contact changes
- (void)listenForChanges:(BOOL)listen
{
    if (listen)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadContact) name:NF_RELOAD_CONTACT object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NF_RELOAD_CONTACT object:nil];
    }
}


- (NSString*)contactId
{
    return [NSString stringWithFormat:@"%d", ABRecordGetRecordID(self.contact.contactRef)];
}


#pragma mark - Tableview footer button delegates
- (void)firstFooterButtonPressed
{
#warning - ReplaceMe : Used to add the user to the first dummy group
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NF_ADD_TO_GROUP
     object:nil
     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
               [NSString stringWithFormat:@"%d", ABRecordGetRecordID(contact.contactRef)], NF_KEY_CONTACT_ID,
               @"Group1", NF_KEY_GROUPNAME, nil]];
}

- (void)secondFooterButtonPressed
{
#warning - ReplaceMe : Used to add the user to the second dummy group
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NF_ADD_TO_GROUP
     object:nil
     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
               [NSString stringWithFormat:@"%d", ABRecordGetRecordID(contact.contactRef)], NF_KEY_CONTACT_ID,
               @"Group2", NF_KEY_GROUPNAME, nil]];
}

- (void)thirdFooterButtonPressed
{
#warning - ReplaceMe : Used to add the user to the third dummy group
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NF_ADD_TO_GROUP
     object:nil
     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
               [NSString stringWithFormat:@"%d", ABRecordGetRecordID(contact.contactRef)], NF_KEY_CONTACT_ID,
               @"Group3", NF_KEY_GROUPNAME, nil]];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

