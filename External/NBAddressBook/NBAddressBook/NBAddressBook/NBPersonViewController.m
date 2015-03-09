//
//  NBPersonViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/3/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBPersonViewController.h"
#import "NBPersonCellAddressInfo.h"
#import "NBPeopleListViewController.h"
#import "NBPeoplePickerNavigationController.h"
#import "NBRecentContactViewController.h"
#import "UIImage+Resize.h"


@implementation NBPersonViewController

@synthesize contact, aNewContactDelegate, peoplePickerDelegate, allowsActions, allowsEditing, displayedPerson, personViewDelegate;

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
    
    //Create the buttons
    doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
    cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
    editButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editPressed:)];
    
    //Set the bar frame and take both the navigation controller and tabbar into consideration
    CGRect appFrame = self.view.bounds;
    self.view.frame = CGRectMake( 0, 0, appFrame.size.width, appFrame.size.height);
    self.tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [self.tableView setFrame:self.view.frame];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    [self.tableView setAllowsSelectionDuringEditing:YES];
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
    
//DEPRECATED
    //Make the delete button graphic in the footer
//    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    UIImage * deleteImage = [UIImage imageNamed:@"deleteButton.png"];
//    [self.deleteButton setFrame:CGRectMake(6, 6, self.view.bounds.size.width - 16, 45)];
//    [self.deleteButton setTitle:NSLocalizedString(@"BL_DELETE_CONTACT", @"") forState:UIControlStateNormal];
//    [[self.deleteButton titleLabel] setFont:[UIFont boldSystemFontOfSize:20]];
//    [self.deleteButton setBackgroundImage:[deleteImage stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] forState:UIControlStateNormal];
//    [self.deleteButton addTarget:self action:@selector(deleteContactPressed) forControlEvents:UIControlEventTouchUpInside];
//    [footerView addSubview:self.deleteButton];
    
    //Create the date-picker
    self.datePicker = [[UIDatePicker alloc]initWithFrame:CGRectMake(0, 0, 320, 0)];
    [self.datePicker addTarget:self action:@selector(dateSelected) forControlEvents:UIControlEventValueChanged];
    [self.datePicker setDatePickerMode:UIDatePickerModeDate];
    [self.datePicker setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.datePicker];
    
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
    [portraitButton addTarget:self action:@selector(portraitTapped:) forControlEvents:UIControlEventTouchUpInside];
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
    
    //Create the photo picker for the portrait
    portraitPicker = [[UIImagePickerController alloc] init];
    portraitPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [portraitPicker setDelegate:self];
    portraitPicker.allowsEditing = YES;
    
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
    
    //If we are merging, also set the new number
    if (self.contactToMergeWith != nil)
    {
        [personStructureManager fillWithContactToMergeWith:self.contactToMergeWith];
    }
    
    //If we're merging, start in edit-mode, else start in viewing-mode
    [self enableEditMode:(self.contactToMergeWith != nil)];
    
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
    
    //Check if we need to focus on this item
    if (indexPathToFocusOn != nil)
    {
        [self.tableView scrollToRowAtIndexPath:indexPathToFocusOn atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    //If we're not in a superview, cleanup
    if ([self.view superview] == nil)
        [self dismissView];
}

#pragma mark - Clear keyboard responder
-(void)clearKeyboardResponder
{
    indexPathToFocusOn = nil;
    [self.view endEditing:NO];
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
        [self enableEditMode:(self.contactToMergeWith != nil)];
        
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
             if (indexPathToFocusOn != nil)
             {
                 [self.tableView scrollToRowAtIndexPath:indexPathToFocusOn
                                       atScrollPosition:UITableViewScrollPositionNone
                                               animated:YES];
                 indexPathToFocusOn = nil;
             }
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
    //Set the navigation bar and portrait
    if (enable)
    {
        //Set the navigation buttons
        [self.navigationItem setLeftBarButtonItem:cancelButton animated:YES];
        [self.navigationItem setRightBarButtonItem:doneButton animated:YES];
    }
    else
    {
        //Set the navigation buttons
        [self.navigationItem setLeftBarButtonItem:backButton animated:YES];
        
        //If we allow for editing
        if (self.allowsEditing)
        {
            [self.navigationItem setRightBarButtonItem:editButton animated:YES];
        }
        //Update the name label (since the name cells disappear in non-edit mode)
        [self setNameLabel];
    }
    
    //Mutate the bottom button's visibility
    [firstFooterButton setHidden:enable];
    [secondFooterButton setHidden:enable];
    [thirdFooterButton setHidden:enable];
    
    //If we're merging a contact, always hide the footer
    [self.tableView.tableFooterView setHidden:self.contactToMergeWith!=nil];
    
//DEPRECATED
    //Mutate the delete button visibility
//    [self.deleteButton setHidden:!enable];
    
    //Always hide the date picker
    [self showDatePicker:NO animated:NO];
    
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
    
    //Mutate the add-field button
    [[[personStructureManager.tableStructure objectAtIndex:CC_NEW_FIELD] objectAtIndex:0] setVisible:enable];
    
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
        [indexSet addIndex:CC_NEW_FIELD];
        [indexSet addIndex:CC_DELETE];
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
    
    CGSize labelSize = [nameLabel.text sizeWithFont:nameLabel.font
                                  constrainedToSize:nameLabel.frame.size
                                      lineBreakMode:NSLineBreakByWordWrapping];
    return labelSize.height;
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [personStructureManager.tableStructure count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    
    int numRows = 0;
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
            numRows = [[personStructureManager getVisibleRows:YES ForSection:section] count];
        }
        else
        {
            numRows = 0;
        }
    }
    else if (section == CC_NUMBER || section == CC_EMAIL || section == CC_HOMEPAGE)
    {
        numRows = [[personStructureManager getVisibleRows:YES ForSection:section] count];
    }
    else if (section == CC_NEW_FIELD)
    {
        //Only show this row if we're editing
        if (self.tableView.editing)
        {
            numRows = 1;
        }
        else
        {
            numRows = 0;
        }
    }
    else if (section == CC_OTHER_DATES)
    {
        numRows = [[personStructureManager.tableStructure objectAtIndex:CC_OTHER_DATES] count] - (self.tableView.isEditing ? 0 : 1);
    }
    else if (section == CC_DELETE)
    {
        numRows = self.tableView.isEditing ? 1 : 0;
    }
    else
    {
        numRows = [[personStructureManager getVisibleRows:YES ForSection:section] count];
    }
    
    //Return the number of rows
    return numRows;
}


//Support-method to quickly scroll to a given row
- (void)scrollToRow:(id)object
{
    NSIndexPath * indexPath;
    if ([object isKindOfClass:[NSIndexPath class]])
    {
        indexPath = (NSIndexPath*)object;
    }
    else if ([object isKindOfClass:[NBAddressCell class]])
    {
        NBAddressCell * addressCell = (NBAddressCell*)object;
        NBPersonCellAddressInfo * addressInfo = [personStructureManager getCellInfoForCell:addressCell inSection:CC_ADDRESS];
        int row = [[personStructureManager.tableStructure objectAtIndex:CC_ADDRESS] indexOfObject:addressInfo];
        indexPath = [NSIndexPath indexPathForRow:row inSection:CC_ADDRESS];
    }
    else
    {
        return;
    }
    
    //Check if we need to create a cell for this field
    NBPersonCellInfo * cellInfo = [personStructureManager getVisibleCellForIndexPath:indexPath];
    if (cellInfo.tableViewCell == nil)
    {
        [cellInfo setTableViewCell:[self getTableViewCellForIndexPath:indexPath]];
    }
    
    //If we need to scroll to the dates-field
    if (indexPath.section == CC_OTHER_DATES || indexPath.section == CC_BIRTHDAY)
    {
        datePickerTargetRow = indexPath;
    }
    
    //Remember the row to focus on
    indexPathToFocusOn = indexPath;
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
            UITextField * textField = textField = [[UITextField alloc] initWithFrame:CGRectMake(34, 0, self.tableView.isEditing ? SIZE_TEXTVIEW_EDIT_WIDTH : SIZE_TEXTVIEW_WIDTH, cell.frame.size.height)];
            [textField setBackgroundColor:[UIColor clearColor]];
            [textField setTextAlignment:NSTextAlignmentLeft];
            [textField setReturnKeyType:UIReturnKeyDone];
            [textField setDelegate:self];
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
            break;
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
            UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 12, 75, cell.contentView.bounds.size.height/2)];
            [label setTextAlignment:NSTextAlignmentRight];
            [label setTextColor:FONT_COLOR_LABEL];
            [label setFont:FONT_LABEL];
            [label setBackgroundColor:[UIColor clearColor]];            
//            [label setHighlightedTextColor:[UIColor whiteColor]];
            [cell setCellLabel:label];
            [cell.contentView addSubview:label];
            
            //Add and remember a vertical separator
            cell.lineView = [[UIView alloc] initWithFrame:CGRectMake((cell.contentView.bounds.size.width/4), 0, 1, cell.contentView.bounds.size.height)];
            cell.lineView.backgroundColor = FONT_COLOR_LIGHT_GREY;
            [cell.lineView setHidden:!self.tableView.editing];
            [cell.contentView addSubview:cell.lineView];
            
            //Make the input textfield
            UITextField * textField = [[UITextField alloc]initWithFrame:CGRectMake(85, 0, self.tableView.isEditing ? SIZE_TEXTVIEW_EDIT_WIDTH : SIZE_TEXTVIEW_WIDTH, cell.frame.size.height)];
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
            [textField setDelegate:self];
            [cell.contentView addSubview:textField];
            
            //Disallow selection
            [cell setTag:0];
            
            //Set the keyboard type
            switch (indexPath.section) {
                case CC_NUMBER:
                    [textField setKeyboardType:UIKeyboardTypePhonePad];
                    break;
                case CC_EMAIL:
                    [textField setKeyboardType:UIKeyboardTypeEmailAddress];
                    break;
                case CC_HOMEPAGE:
                    [textField setKeyboardType:UIKeyboardTypeURL];
                    break;
                default:
                    break;
            }
            
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
            break;
        case CC_IM:
        {
            NBPersonIMCell * cell = [[NBPersonIMCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            [cell registerForKeyboardDismiss];
            
            //Build up the title label
            UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 12, 75, cell.contentView.bounds.size.height/2)];
            [label setTextAlignment:NSTextAlignmentRight];
            [label setTextColor:FONT_COLOR_LABEL];
            [label setFont:FONT_LABEL];
            [label setBackgroundColor:[UIColor clearColor]];
            cell.cellLabel = label;
            [cell.contentView addSubview:label];
            
            //Set the section type
            [cell setSection:indexPath.section];
            
            //Add and remember a vertical separator
            cell.vertiLineView = [[UIView alloc] initWithFrame:CGRectMake((cell.contentView.bounds.size.width/4), 0, 1, cell.contentView.bounds.size.height*2)];
            cell.vertiLineView.backgroundColor = FONT_COLOR_LIGHT_GREY;
            [cell.vertiLineView setHidden:!self.tableView.editing];
            [cell.contentView addSubview:cell.vertiLineView];
            
            //Add and remember a horizontal separator
            cell.horiLineView = [[UIView alloc] initWithFrame:CGRectMake((cell.contentView.bounds.size.width/4), cell.contentView.bounds.size.height, cell.contentView.bounds.size.width*0.59f, 1)];
            cell.horiLineView.backgroundColor = FONT_COLOR_LIGHT_GREY;
            [cell.horiLineView setHidden:!self.tableView.editing];
            [cell.contentView addSubview:cell.horiLineView];
            
            //Make the input textfield
            UITextField * textField = [[UITextField alloc]initWithFrame:CGRectMake(85, 0, self.tableView.isEditing ? SIZE_TEXTVIEW_EDIT_WIDTH : SIZE_TEXTVIEW_WIDTH, cell.frame.size.height)];
            [textField setBackgroundColor:[UIColor clearColor]];
            [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
            [textField setFont:[UIFont boldSystemFontOfSize:14]];
            [textField setPlaceholder:cellInfo.textfieldPlaceHolder];
            [textField setText:cellInfo.textValue];
            [textField setEnabled:self.tableView.isEditing];
            [textField setTag:indexPath.section];
            [textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [textField setDelegate:self];
            [cell.contentView addSubview:textField];
            
            //Add the type of cell-label
            UILabel * typeLabel = [[UILabel alloc]initWithFrame:CGRectMake((cell.contentView.bounds.size.width/3.8f), cell.contentView.bounds.size.height * 1.15f, (cell.contentView.bounds.size.width*0.59f), 30)];
            [typeLabel setBackgroundColor:[UIColor clearColor]];
            [typeLabel setFont:[UIFont boldSystemFontOfSize:16]];
            [typeLabel setHidden:!self.tableView.editing];
            [typeLabel setUserInteractionEnabled:YES];
            [cell.contentView addSubview:typeLabel];
            [cell setTypeLabel:typeLabel];
            
            //Make the label tappable
            UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectServiceForIM:)];
            singleTap.numberOfTapsRequired = 1;
            [typeLabel addGestureRecognizer:singleTap];
            
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
            break;
        case CC_OTHER_DATES:
        case CC_BIRTHDAY:
        {
            //Create the cell and label for date
            NBDateCell * dateCell = [[NBDateCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            [dateCell registerForKeyboardDismiss];
            
            //Build up the title label
            UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 12, 75, dateCell.contentView.bounds.size.height/2)];
            [label setTextAlignment:NSTextAlignmentRight];
            [label setTextColor:FONT_COLOR_LABEL];
            [label setFont:FONT_LABEL];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setText:cellInfo.labelTitle];
            dateCell.cellLabel = label;
            [dateCell.contentView addSubview:label];
            
            //Set the section type
            [dateCell setSection:indexPath.section];
            
            //Add and remember a vertical separator
            dateCell.lineView = [[UIView alloc] initWithFrame:CGRectMake((dateCell.contentView.bounds.size.width/4), 0, 1, dateCell.contentView.bounds.size.height)];
            dateCell.lineView.backgroundColor = FONT_COLOR_LIGHT_GREY;
            [dateCell.lineView setHidden:!self.tableView.editing];
            [dateCell.contentView addSubview:dateCell.lineView];
            
            //Create a textfield for the date
            UITextField * textField = [[UITextField alloc]initWithFrame:CGRectMake(85, 0, self.tableView.isEditing ? SIZE_TEXTVIEW_EDIT_WIDTH : SIZE_TEXTVIEW_WIDTH, dateCell.frame.size.height)];
            [textField setBackgroundColor:[UIColor clearColor]];
            [textField setFont:[UIFont boldSystemFontOfSize:14]];
            [textField setPlaceholder:cellInfo.textfieldPlaceHolder];
            if (cellInfo.dateValue != nil)
            {
                [textField setText:[NSString formatToShortDate:cellInfo.dateValue]];
            }
            textField.tag = indexPath.section;
            textField.delegate = self;
            [textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [dateCell.contentView addSubview:textField];
            [textField setEnabled:YES];
            [textField setUserInteractionEnabled:YES];
            
            //Remember the cell and textfield
            [dateCell setCellTextfield:textField];
            [cellInfo setTableViewCell:dateCell];
            return dateCell;
        }
            break;
        case CC_NOTES:
        {
            //Create the cell and textview
            NBNotesCell * notesCell = [[NBNotesCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            [notesCell registerForKeyboardDismiss];
            
            //Build up the title label
            UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 12, 75, notesCell.contentView.bounds.size.height/2)];
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
            
            //Add and remember a vertical separator
            notesCell.lineView = [[UIView alloc] initWithFrame:CGRectMake((notesCell.contentView.bounds.size.width/4), 0, 1, notesHeight)];
            notesCell.lineView.backgroundColor = FONT_COLOR_LIGHT_GREY;
            [notesCell.lineView setHidden:!self.tableView.editing];
            [notesCell.contentView addSubview:notesCell.lineView];
            
            //Make the input textfield
            UITextView * textView = [[UITextView alloc]initWithFrame:CGRectMake(90, 4, self.tableView.editing ? SIZE_TEXTVIEW_EDIT_WIDTH : SIZE_TEXTVIEW_WIDTH, notesHeight)];
            [textView setBackgroundColor:[UIColor clearColor]];
            [textView setScrollEnabled:NO];
            [textView setFont:FONT_NOTES];
            [textView setUserInteractionEnabled:YES];
            textView.tag = indexPath.section;
            textView.delegate = self;
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
            break;
        default:
            return nil;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Remember the cell if we do not have it yet
    NBPersonCellInfo * cellInfo;
    
    if( indexPath.section != CC_DELETE )
        cellInfo = [personStructureManager getVisibleCellForIndexPath:indexPath];
    
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
            label = [[UILabel alloc]initWithFrame:CGRectMake(0, 12, 75, cell.contentView.bounds.size.height/2)];
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
                                                                                   self.tableView.isEditing ? SIZE_TEXTVIEW_EDIT_WIDTH : SIZE_TEXTVIEW_WIDTH,
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
            addressCell = [[NBAddressCell alloc]initWithStyle:UITableViewCellStyleDefault andDelegate:self];

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
                UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 12, 75, addressCell.contentView.bounds.size.height/2)];
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
    else if (indexPath.section == CC_NEW_FIELD)
    {
        NBPersonFieldTableCell * cell = [cellInfo getPersonFieldTableCell];
        if (cell == nil)
        {
            cell = [[NBPersonFieldTableCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];

            //Set the section type
            [cell setSection:indexPath.section];
            
            [cell.textLabel setText:cellInfo.labelTitle];
            [cell.textLabel setTextColor:FONT_COLOR_LABEL];
            [cell.textLabel setFont:[UIFont boldSystemFontOfSize:13]];
            
            [cellInfo setTableViewCell:cell];
        }
        
        return cell;
    }
    else if (indexPath.section == CC_DELETE)
    {
        UITableViewCell * deleteCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        [deleteCell.textLabel setText:NSLocalizedString(@"BL_DELETE_CONTACT", @"")];
        [deleteCell.textLabel setTextColor:[UIColor colorWithRed:255.0f/255.0f green:59.0f/255.0f blue:48.0f/255.0f alpha:1]];
        return deleteCell;
    }
    return nil;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == CC_NAME)
    {
        return UITableViewCellEditingStyleNone;
    }
    else if (indexPath.section == CC_ADDRESS)
    {
        //If it is the add-button, set an insert-icon
        NSArray * addressArray = [personStructureManager.tableStructure objectAtIndex:CC_ADDRESS];
        NBPersonCellAddressInfo * addressInfo = [addressArray objectAtIndex:indexPath.row];
        if (addressInfo.isAddButton)
        {
            return UITableViewCellEditingStyleInsert;
        }
        else
        {
            if ([[personStructureManager getVisibleRows:YES ForSection:CC_ADDRESS] lastObject] == addressInfo)
            {
                //If we haven't entered anything, don't allow for deletion yet
                if ([addressInfo.city length] == 0 &&
                    [addressInfo.streetLines count] == 0 &&
                    [addressInfo.state length] == 0 &&
                    [addressInfo.ZIP length] == 0)
                {
                    return UITableViewCellEditingStyleNone;
                }
                else
                {
                    return UITableViewCellEditingStyleDelete;
                }
            }
            else
            {
                return UITableViewCellEditingStyleDelete;
            }
        }
    }
    else if (indexPath.section == CC_NUMBER ||
             indexPath.section == CC_EMAIL ||
             indexPath.section == CC_HOMEPAGE ||
             indexPath.section == CC_OTHER_DATES ||
             indexPath.section == CC_SOCIAL ||
             indexPath.section == CC_IM ||
             indexPath.section == CC_RELATED_CONTACTS)
    {
        //Don't allow deletion when :
        //  - It is the first cell and there are no additional cells
        //  - It is the last cell
        int numVisibleCellsInSection = [[personStructureManager getVisibleRows:YES ForSection:indexPath.section] count];
        if (indexPath.section == CC_ADDRESS && indexPath.row == numVisibleCellsInSection -1)
        {
            return UITableViewCellEditingStyleInsert;
        }
        else
        {
            if (indexPath.row < numVisibleCellsInSection-1 && numVisibleCellsInSection > 0)
            {
                return UITableViewCellEditingStyleDelete;
            }
            else
            {
                return UITableViewCellEditingStyleNone;
            }
        }
    }
    else if (indexPath.section == CC_NEW_FIELD)
    {
        return UITableViewCellEditingStyleInsert;
    }
    else if (indexPath.section == CC_NOTES)
    {
        return UITableViewCellEditingStyleDelete;
    }
    else
    {
        return UITableViewCellEditingStyleNone;
    }
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.isEditing)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the row from the model and view
        [tableView beginUpdates];
        NSMutableArray * sectionArray = [personStructureManager.tableStructure objectAtIndex:indexPath.section];
        [sectionArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        //If the add-row is not visible, insert it
        if (indexPath.section == CC_ADDRESS)
        {
            NBPersonCellAddressInfo * addCell = [[personStructureManager.tableStructure objectAtIndex:CC_ADDRESS] lastObject];
            if (addCell.isAddButton && !addCell.visible)
            {
                [addCell setVisible:YES];
                [tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
        [tableView endUpdates];
        
        //Reload the view to avoid weird glitches
        [tableView reloadData];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell setTag:1];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return NO;
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
        cellheight += (SIZE_CELL_HEIGHT/2);

        //Get the textview
        UITextView * textView = [cellInfo getNotesCell].cellTextview;
        if (textView != nil)
        {
            //Resize based on tableview editing
            CGRect textFrame = textView.frame;
            CGSize textSize = textView.frame.size;
            textSize.width = self.tableView.editing ? SIZE_TEXTVIEW_EDIT_WIDTH : SIZE_TEXTVIEW_WIDTH;
            
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
    else if (indexPath.section == CC_IM)
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
    //The delete button
    else if( indexPath.section == CC_DELETE )
    {
        return SIZE_CELL_HEIGHT;
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
    if( section != CC_DELETE && (
       [[personStructureManager getVisibleRows:YES ForSection:section] count] == 0
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
    if( section != CC_DELETE && (
       [[personStructureManager getVisibleRows:YES ForSection:section] count] == 0
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

#pragma mark - Cell focussing
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Focus on this indexpath (it'll exist since this is called after cellForRowAtIndexPath
    NBPersonCellInfo * cellInfo;
    if( indexPath.section != CC_DELETE )
        cellInfo = [personStructureManager getVisibleCellForIndexPath:indexPath];
    if ([cellInfo makeFirstResponder])
    {
        //Only do this once
        [cellInfo setMakeFirstResponder:NO];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            //Apply the selection
            switch (indexPath.section)
            {            
                case CC_NAME:
                {
                   [[[cellInfo getNameTableViewCell] cellTextfield] becomeFirstResponder];
                }
                   break;
                case CC_BIRTHDAY:
                case CC_OTHER_DATES:
                {
                   //Make the date the first responder
                   [self showDatePicker:YES animated:YES];
                   
                   //Also set the initial value
                   [self dateSelected];
                }
                   break;
                case CC_RELATED_CONTACTS:
                {
                   //Translate the row to the visible one and make it the first responder
                   [[cellInfo getDetailCell].cellTextfield becomeFirstResponder];
                }
                   break;
                case CC_SOCIAL:
                {
                   //Translate the row to the visible one and make it the first responder
                   [[cellInfo getDetailCell].cellTextfield becomeFirstResponder];
                }
                   break;
                case CC_IM:
                {
                   //Translate the row to the visible one and make it the first responder
                   [[cellInfo getIMCell].cellTextfield becomeFirstResponder];
                }
                   break;
                case CC_NOTES:
                {
                   //Translate the row to the visible one and make it the first responder
                   [[cellInfo getNotesCell].cellTextview becomeFirstResponder];
                }
                   break;
                case CC_ADDRESS:
                {                
                    //Focus on the primary cell
                    [[[cellInfo getAddressCell] topTextfield] becomeFirstResponder];
                }
                    break;
                default:
                    break;
            }
        });
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
            notesFieldSize = [notesText sizeWithFont:FONT_NOTES constrainedToSize:CGSizeMake(self.tableView.editing ? SIZE_TEXTVIEW_EDIT_WIDTH : SIZE_TEXTVIEW_WIDTH, 5000) lineBreakMode:NSLineBreakByWordWrapping].height;
    }
    
    notesFieldSize += (SIZE_CELL_HEIGHT / 2);
    
    return notesFieldSize;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    //Determine if we should continue from the delegate
    BOOL shouldContinue = YES;
    if (( self.peoplePickerDelegate != nil || personViewDelegate != nil) && !self.tableView.isEditing)
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
            }
                break;
            case CC_EMAIL:
            {
                //Set the property
                propertyID = kABPersonEmailProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, propertyID)), indexPath.row);
            }
                break;
            case CC_HOMEPAGE:
            {
                //Set the property
                propertyID = kABPersonURLProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, propertyID)), indexPath.row);
            }
                break;
            case CC_ADDRESS:
            {
                //Set the property
                propertyID = kABPersonAddressProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, propertyID)), indexPath.row);
            }
                break;
            case CC_BIRTHDAY:
            {
                //Set the property
                propertyID = kABPersonBirthdayProperty;
            }
                break;
            case CC_OTHER_DATES:
            {
                //Set the property
                propertyID =kABPersonDateProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, kABPersonDateProperty)), indexPath.row);
            }
                break;
            case CC_RELATED_CONTACTS:
            {
                //Set the property
                propertyID = kABPersonRelatedNamesProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, propertyID)), indexPath.row);
            }
                break;
            case CC_SOCIAL:
            {
                //Set the property
                propertyID = kABPersonSocialProfileProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, propertyID)), indexPath.row);
            }
                break;
            case CC_IM:
            {
                //Set the property
                propertyID = kABPersonInstantMessageProperty;
                
                //It's a multivalue
                multiRefIdentifier = ABMultiValueGetIdentifierAtIndex((ABRecordCopyValue(contact.contactRef, propertyID)), indexPath.row);
            }
                break;
            case CC_NOTES:
            {
                //Set the property
                propertyID = kABPersonNoteProperty;
            }
                break;
            default:
                break;
        }
        
        //Determine if we should continue according to the nav delegate
        if (self.peoplePickerDelegate != nil)
        {
            shouldContinue = [self.peoplePickerDelegate peoplePickerNavigationController:(NBPeoplePickerNavigationController*)self.navigationController shouldContinueAfterSelectingPerson:self.contact.contactRef property:propertyID identifier:multiRefIdentifier];
        }
        
        //Determine if we should continue according to the person delegate
        if (shouldContinue && self.personViewDelegate != nil)
        {
            shouldContinue = [self.personViewDelegate personViewController:self shouldPerformDefaultActionForPerson:self.contact.contactRef property:propertyID identifier:multiRefIdentifier];
        }
    }
    else
    {
        if( indexPath.section == CC_DELETE )
        {
            [self deleteContactPressed];
            return;
        }
    }

    if (shouldContinue)
    {
        NBNewFieldTableViewController* newFieldController;
        UINavigationController*        navController;
        switch (indexPath.section)
        {
            //Display picker with fields
            case CC_NEW_FIELD:
                //End any editing so far
                [self.tableView endEditing:YES];
                
                //Allow the user to add a new name-field
                 newFieldController = [[NBNewFieldTableViewController alloc]initWithStyle:UITableViewStyleGrouped];
                [newFieldController setStructureManager:personStructureManager];
                [newFieldController setPersonViewDelegate:self];
                navController = [[UINavigationController alloc]initWithRootViewController:newFieldController];
                [self presentViewController:navController animated:YES completion:nil];
                break;

            case CC_NUMBER:
                //If we're editing, show the options. Else, attempt to call the number
                if (self.tableView.isEditing)
                {
                    //Set the type and load the list
                    [NBValueListTableViewController setLabelType:LT_NUMBER];
                    [NBValueListTableViewController setTargetIndexPath:indexPath];
                    [self displayValuePicker];
                }
                else
                {
                    NSString * phoneNumber = [((NBPersonCellInfo*)[[personStructureManager.tableStructure objectAtIndex:CC_NUMBER] objectAtIndex:indexPath.row]) textValue];
                    [NBContact makePhoneCall:phoneNumber withContactID:[NSString stringWithFormat:@"%d", ABRecordGetRecordID(self.contact.contactRef)]];

                    if ([self isKindOfClass:[NBRecentContactViewController class]])
                    {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                                       dispatch_get_main_queue(), ^
                        {
                            [self.navigationController popToRootViewControllerAnimated:NO];
                        });
                    }
                }
                break;

            case CC_EMAIL:
                //If we're editing, show the options. Else, attempt to open email
                if (self.tableView.isEditing)
                {
                    //Set the type and load the list
                    [NBValueListTableViewController setLabelType:LT_EMAIL];
                    [NBValueListTableViewController setTargetIndexPath:indexPath];
                    [self displayValuePicker];
                }
                break;

            case CC_RINGTONE:
                //Set the type and load the list of available ringtones
                [NBValueListTableViewController setLabelType:(indexPath.row == 0 ? LT_RINGTONE : LT_VIBRATION)];
                [NBValueListTableViewController setTargetIndexPath:indexPath];
                [self displayValuePicker];
                break;

            case CC_HOMEPAGE:
                //If we're editing, show the options. Else, attempt to open website
                if (self.tableView.isEditing)
                {
                    //Set the type and load the list
                    [NBValueListTableViewController setLabelType:LT_WEBSITE];
                    [NBValueListTableViewController setTargetIndexPath:indexPath];
                    [self displayValuePicker];
                }
                break;

            case CC_ADDRESS:
                if (self.tableView.editing)
                {
                    //If the last cell is tapped and it is an add-address cell, insert another address input
                    NSMutableArray * addressArray = [personStructureManager.tableStructure objectAtIndex:CC_ADDRESS];
                    if (indexPath.row == [addressArray count] - 1)
                    {
                        //Also add an entry into the model
                        NBPersonCellAddressInfo * cellInfo = [[NBPersonCellAddressInfo alloc]initWithPlaceholder:nil andLabel:nil];
                        [cellInfo setCountryCode:[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]];
                        [cellInfo setCountryUsingCountryCode];
                        
                        //Focus on the cell as soon as it is rendered
                        [cellInfo setMakeFirstResponder:YES];
                        
                        //Set the label type
                        [cellInfo setLabelTitle:NSLocalizedString([personStructureManager findNextLabelInArray:HWO_ARRAY usingSource:[personStructureManager.tableStructure objectAtIndex:CC_ADDRESS]], @"")];
                        [cellInfo setVisible:YES];
                        [addressArray insertObject:cellInfo atIndex:[addressArray count]-1];
                        
                        //Hide the new-address address cell
                        [[addressArray lastObject] setVisible:NO];

                        //Update the tableview
                        [self.tableView beginUpdates];
                        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[addressArray count] - 2 inSection:CC_ADDRESS]] withRowAnimation:UITableViewRowAnimationAutomatic];
                        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[addressArray indexOfObject:cellInfo] inSection:CC_ADDRESS]] withRowAnimation:UITableViewRowAnimationAutomatic];
                        [self.tableView endUpdates];
                    }
                    //Else allow for changing the label
                    else
                    {
                        //Set the type and load the list
                        [NBValueListTableViewController setLabelType:LT_ADDRESS];
                        [NBValueListTableViewController setTargetIndexPath:indexPath];
                        [self displayValuePicker];
                    }
                }
                break;

            case CC_OTHER_DATES:
            case CC_BIRTHDAY:
                if (self.tableView.isEditing)
                {
                    //Set the type and load the list
                    [NBValueListTableViewController setLabelType:LT_DATE];
                    [NBValueListTableViewController setTargetIndexPath:indexPath];
                    [self displayValuePicker];
                }
                break;

            case CC_SOCIAL:
            case CC_IM:
                //If we're editing, show the options. Else, attempt to 'launch' the cell
                if (self.tableView.isEditing)
                {
                    //Set the type and load the list
                    [NBValueListTableViewController setLabelType:indexPath.section == CC_SOCIAL ? LT_SOCIAL : LT_IM_LABEL];
                    [NBValueListTableViewController setTargetIndexPath:indexPath];
                    [self displayValuePicker];
                }
                break;

            case CC_RELATED_CONTACTS:
                if (self.tableView.isEditing)
                {
                    //Set the type and load the list
                    [NBValueListTableViewController setLabelType:LT_RELATED];
                    [NBValueListTableViewController setTargetIndexPath:indexPath];
                    [self displayValuePicker];
                }
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


#pragma mark - Selection of service

- (void)selectServiceForIM:(UITapGestureRecognizer*)gesture
{
    //The label tapped
    UILabel* tappedLabel = (UILabel*)gesture.view;
    int rowIndex = [[personStructureManager.tableStructure objectAtIndex:CC_IM] indexOfObject:[personStructureManager getCellInfoForIMLabel:tappedLabel]];
    
    //Set the type and load the list
    [NBValueListTableViewController setLabelType:LT_IM_SERVICE];
    [NBValueListTableViewController setTargetIndexPath:[NSIndexPath indexPathForRow:rowIndex inSection:CC_IM]];
    [self displayValuePicker];
}


#pragma mark - Date picker showing/hiding

//Only called when the tableview is editing
- (void)showDatePicker:(BOOL)show animated:(BOOL)animated
{
    //Determine if the picker is already shown
    BOOL pickerShown = self.datePicker.center.y < self.view.bounds.size.height;
    if ((show && !pickerShown) || ( !show && pickerShown))
    {
        if (show)
        {
            //Resign any textfield
            [self.view endEditing:YES];
     
            //Shift the tableview so we can clearly see the cell
            UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, self.datePicker.bounds.size.height, 0.0);
            self.tableView.contentInset = contentInsets;
            self.tableView.scrollIndicatorInsets = contentInsets;
            
            //Also scroll to the cell
            [self.tableView scrollToRowAtIndexPath:datePickerTargetRow atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
        else
        {
            UIEdgeInsets contentInsets = UIEdgeInsetsZero;
            self.tableView.contentInset = contentInsets;
            self.tableView.scrollIndicatorInsets = contentInsets;
        }
        
        //Reposition the datepicker animated
        CGPoint targetCenter = show ? CGPointMake( self.datePicker.center.x, self.view.bounds.size.height - self.datePicker.bounds.size.height/2) : CGPointMake( self.datePicker.center.x, self.view.bounds.size.height + self.datePicker.bounds.size.height/2);
        if (animated)
        {
            [UIView animateWithDuration:0.3f
                                  delay:0.0f
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations: ^(void)
            {
                [self.datePicker setCenter:targetCenter];
            }
                             completion:nil];
        }
        else
        {
            [self.datePicker setCenter:targetCenter];
        }
    }
}

#pragma mark - Address fields callback
- (void)addressTextfieldMutated:(UITextField*)textField inCell:(NBAddressCell*)cell
{
    NSArray*                 addressArray = [personStructureManager getVisibleRows:YES ForSection:CC_ADDRESS];
    NBPersonCellAddressInfo* cellInfo     = [personStructureManager getCellInfoForCell:cell inSection:CC_ADDRESS];
    
    BOOL hadNoData = ([cellInfo.streetLines count] == 0 &&
                      [cellInfo.city length]       == 0 &&
                      [cellInfo.state length]      == 0 &&
                      [cellInfo.ZIP length]        == 0);
    
    if ([addressArray containsObject:cellInfo])
    {
        int cellIndex = [addressArray indexOfObject:cellInfo];
        
        //If text was typed and this street is the last of street
        int textfieldPosition = [cell.streetTextfields indexOfObject:textField];
        if (textField.tag == TT_CITY ||
            textField.tag == TT_ISLAND_NAME)
        {
            [cellInfo setCity:textField.text];
        }
        else if (textField.tag == TT_POSTAL_CODE ||
                 textField.tag == TT_ZIP         ||
                 textField.tag == TT_PIN)
        {
            [cellInfo setZIP:textField.text];
        }
        else if (textField.tag == TT_PROVINCE   ||
                 textField.tag == TT_SUBURB     ||
                 textField.tag == TT_STATE      ||
                 textField.tag == TT_GOVERNATE  ||
                 textField.tag == TT_DEPARTMENT ||
                 textField.tag == TT_DISTRICT   ||
                 textField.tag == TT_PREFECTURE ||
                 textField.tag == TT_COUNTY     ||
                 textField.tag == TT_REGION     ||
                 textField.tag == TT_POSTAL_DISTRICT)
        {
            [cellInfo setState:textField.text];
        }
        else if (textField.tag == TT_COUNTRY)
        {
            [cellInfo setCountry:textField.text];
    #warning - Also set the countryCode here (depends on how country selection is handled
            [cellInfo setCountryCode:@"NL"];
        }
        else if (textField.tag == TT_STREET ||
                   textField.tag == TT_FURTHER)
        {
            if (textField.text != nil      &&
               [textField.text length] > 0 &&
               textfieldPosition == ([cell.streetTextfields count] - 1))
            {
                //Insert a new street textfield
                [cell addTextfieldForPosition:-1 andLineType:LT_FULL andTextfieldType:TT_STREET];
                
                //Also insert the street into the model
                [cellInfo.streetLines addObject:[NSString string]];
                
                //Reload the table
                [self.tableView beginUpdates];
                [self.tableView endUpdates];
            }
            
            //If we need to remove the street line
            if ((textField.text == nil ||
                 [textField.text length] == 0) &&
                 textfieldPosition != [cell.streetTextfields count] - 1 &&
                 !textField.isFirstResponder)
            {
                //Remove the street textfield
                [cell removeStreetfield:textField];
                
                //Also remove the street from the model
                [cellInfo.streetLines removeObjectAtIndex:textfieldPosition];
                
                //Reload the table
                [self.tableView beginUpdates];
                [self.tableView endUpdates];
            }
            else
            {
                //Update the line typed
                switch (textField.tag)
                {
                    case TT_STREET:
                        if ([textField.text length] > 0)
                        {
                            if ([cellInfo.streetLines count] < (textfieldPosition + 1))
                            {
                                [cellInfo.streetLines addObject:textField.text];
                            }
                            else
                            {
                                [cellInfo.streetLines replaceObjectAtIndex:textfieldPosition withObject:textField.text];
                            }
                        }
                        break;

                    default:
                        break;
                }
            }
        }
        
        if (!changingLabel)
        {
            //Check if all lines were cleared and we're not changing the label. If so, remove the address cell
            if ([cellInfo.streetLines count] == 0 &&
                [cellInfo.city  length]      == 0 &&
                [cellInfo.state length]      == 0 &&
                [cellInfo.ZIP   length]      == 0)
            {
                //If we're deleting the last address cell, show the add-address button
                [self.tableView beginUpdates];
                if (cellIndex == [addressArray count] - 1)
                {
                    [[[personStructureManager.tableStructure objectAtIndex:CC_ADDRESS] lastObject] setVisible:YES];
                    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:cellIndex inSection:CC_ADDRESS]] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                
                //Delete the cell from model
                [[personStructureManager.tableStructure objectAtIndex:CC_ADDRESS] removeObjectAtIndex:cellIndex];
                
                //Reload the table
                [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:cellIndex inSection:CC_ADDRESS]] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
            }
            else
            {
                //If we had no data and do now, reload the table
                if (hadNoData)
                {
                    [self.tableView setEditing:NO];
                    [self.tableView setEditing:YES];
                }
                
                //If we were editing the last address cell        
                if (cellIndex == [addressArray count]-1 && !cellInfo.isAddButton && self.tableView.isEditing )
                {
                    //Else, there is text so there should be an add-button at the end. If not, insert it
                    NBPersonCellAddressInfo * lastCell = [[personStructureManager.tableStructure objectAtIndex:CC_ADDRESS] lastObject];
                    if (!lastCell.visible)
                    {
                        [lastCell setVisible:YES];
                        
                        //Reload the table UI
                        [self.tableView beginUpdates];
                        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[[personStructureManager.tableStructure objectAtIndex:CC_ADDRESS] count] - 1 inSection:CC_ADDRESS]] withRowAnimation:UITableViewRowAnimationAutomatic];
                        [self.tableView endUpdates];
                    }
                }
            }
        }
    }
}

//Check if a street textfield needs removal
- (void)streetTextfieldEditEnded:(UITextField*)textField inCell:(NBAddressCell*)cell
{    
    //If we need to remove the street line
    int textfieldPosition = [cell.streetTextfields indexOfObject:textField];    
    if (( textField.text == nil ||
        [textField.text length] == 0) &&
        textfieldPosition != [cell.streetTextfields count] - 1 &&
        !textField.isFirstResponder)
    {
        //Remove the street textfield
        [cell removeStreetfield:textField];
        
        //Also remove the street from the model
        NBPersonCellAddressInfo * cellInfo = [personStructureManager getCellInfoForCell:cell inSection:CC_ADDRESS];
        [cellInfo.streetLines removeObjectAtIndex:textfieldPosition];
        
        //Reload the table
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
}


#pragma mark - Textview delegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    //Scroll to this row (if we need to)
    indexPathToFocusOn = [NSIndexPath indexPathForRow:0 inSection:CC_NOTES];
    
    //Hide the datePicker
    [self showDatePicker:NO animated:YES];
}


- (BOOL)textView:(UITextView*)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString*)text
{
    //Grow the cell if the textview doesn't fit
    NSString* resultString = [textView.text stringByReplacingCharactersInRange:range withString:text];
    [[[personStructureManager.tableStructure objectAtIndex:CC_NOTES] objectAtIndex:0] setTextValue:resultString];
    
    //Reload the notes
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC), dispatch_get_main_queue(), ^
    {
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    });
    
    //Always store this straight away, since editing the notes should be a direct change when not editing
    if (!self.tableView.isEditing)
    {
        [contact saveNotes:resultString];
    }
    
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    //Check if we should delete the model
    NSString * resultString = textView.text;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if ([resultString length] == 0)
        {
            //Delete model and view
            [[personStructureManager.tableStructure objectAtIndex:CC_NOTES] removeAllObjects];
        }        
    });
}

#pragma mark - Textfield delegate
//Determine wether to allow editing
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    //Check if we should focus on this cell
    NBPersonCellInfo * cellInfo = [personStructureManager getCellInfoForTextfield:textField];
    NSArray * visibleRows =[personStructureManager getVisibleRows:YES ForSection:textField.tag];
    int row = [visibleRows indexOfObject:cellInfo];
    indexPathToFocusOn = [NSIndexPath indexPathForRow:row inSection:textField.tag];
    
    if (textField.tag == CC_OTHER_DATES || textField.tag == CC_BIRTHDAY)
    {
        NBPersonCellInfo * cellInfo = [personStructureManager getCellInfoForTextfield:textField];
        int row = [[personStructureManager.tableStructure objectAtIndex:textField.tag] indexOfObject:cellInfo];
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:textField.tag];
        
        //Begin date editing
        if (indexPath.section == CC_OTHER_DATES && indexPath.row == [[personStructureManager.tableStructure objectAtIndex:CC_OTHER_DATES] count] - 1)
        {
            //Insert a new entry in the model, make it responder
            NBPersonCellInfo * cellInfo = [[NBPersonCellInfo alloc]initWithPlaceholder:nil andLabel:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABOtherLabel))];
            [cellInfo setVisible:YES];
            NSMutableArray * datesArray = [personStructureManager.tableStructure objectAtIndex:CC_OTHER_DATES];
            [datesArray insertObject:cellInfo atIndex:[datesArray count]-1];
            
            //Create a cell for the date
            [self getTableViewCellForIndexPath:indexPath];

            //Update the tableview
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];

            //Set the initial date for this new row
            datePickerTargetRow = indexPath;
            [self dateSelected];
        }
        //We selected a date-cell, show the picker
        else
        {
            if (!(indexPath.section == CC_OTHER_DATES && indexPath.row == [[personStructureManager.tableStructure objectAtIndex:CC_OTHER_DATES] count] - 1))
            {
                datePickerTargetRow = indexPath;
                if ([self.tableView isEditing])
                {
                    [self showDatePicker:YES animated:YES];
                }
            }
        }
        
        return NO;
    }
    else
    {
        return YES;
    }
}

//Remember the active keyboard for view manipulation to display the content
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //Hide the datePicker
    [self showDatePicker:NO animated:YES];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    //If we're editing one of the sections that results in a new row(numbers, email or homepages), insert that row 
    NSString * resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (textField.tag == CC_NUMBER ||
       textField.tag == CC_EMAIL ||
       textField.tag == CC_HOMEPAGE ||
       textField.tag == CC_SOCIAL ||
       textField.tag == CC_IM ||
       textField.tag == CC_RELATED_CONTACTS)
    {
        if ([resultString length] > 0)
        {
            //Check to insert a row below this one
            int cellIndex = [personStructureManager checkToInsertCellBelowCellWithTextfield:textField];
            if (cellIndex != -1)
            {
                //Insert the row
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:cellIndex inSection:textField.tag]] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
                
                //Update the accessory type
                [self.tableView setEditing:NO animated:NO];
                [self.tableView setEditing:YES animated:NO];
            }
        }
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    //Check if we need to remove a row (in case of numbers, email or homepages)
    if (textField.tag == CC_NUMBER ||
        textField.tag == CC_EMAIL ||
        textField.tag == CC_HOMEPAGE ||
        textField.tag == CC_IM ||
        textField.tag == CC_SOCIAL ||
        textField.tag == CC_RELATED_CONTACTS)
    {
        //If the textfield text is empty and we're not changing the label for the field
        if ([textField.text length] == 0 && !changingLabel)
        {
            //If there is no text and this is not the last cell
            NSArray * section = [personStructureManager.tableStructure objectAtIndex:textField.tag];
            NBPersonCellInfo * cellInfo = [personStructureManager getCellInfoForTextfield:textField];
            int cellPosition = [section indexOfObject:cellInfo];
            
            if (cellPosition != [section count] - 1 && [section count] > 1)
            {
                //Remove the row from the model and reload
                int removedIndex = [personStructureManager removeCellWithTextfield:textField];
                if (removedIndex != -1)
                {
                    //Call this delayed, so the textfield can resign                
                    [self performSelector:@selector(delayedReloadTable:) withObject:[NSIndexPath indexPathForRow:cellPosition inSection:textField.tag] afterDelay:0.25f];
                }
            }
        }
    }

    //Store the text value in the corresponding cellinfo
    NBPersonCellInfo * info = [personStructureManager getCellInfoForTextfield:textField];
    [info setTextValue:textField.text];

    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
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


#pragma mark - Date picker

- (void)dateSelected
{
    //Update the model and the cell label
    NBPersonCellInfo * cellInfo = [[personStructureManager.tableStructure objectAtIndex:datePickerTargetRow.section] objectAtIndex:datePickerTargetRow.row];
    [cellInfo setDateValue:self.datePicker.date];
    NBDateCell * dateCell = [cellInfo getDateCell];
    [[dateCell cellTextfield] setText:[NSString formatToShortDate:self.datePicker.date]];
}


#pragma mark - Portrait management

- (void)portraitTapped:(id)sender
{
    //Display the sheet to select a photo, or, if no camera available, the image gallery directly
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        //Check if a photo is already available
        BOOL photoAvailable = [contact getImage:NO] != nil;
        
        UIActionSheet *actionSheet;
        if (!photoAvailable)
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"NCT_CANCEL", @"")
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"NCT_TAKE_PHOTO", @""), NSLocalizedString(@"NCT_CHOOSE_PHOTO", @""), nil];
            actionSheet.tag = AS_PHOTO;
        }
        else
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"NCT_CANCEL", @"")
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:
                           NSLocalizedString(@"NCT_TAKE_PHOTO", @""),
                           NSLocalizedString(@"NCT_CHOOSE_PHOTO", @""),
                           NSLocalizedString(@"NCT_MODIFY_PHOTO", @""),
                           NSLocalizedString(@"NCT_DELETE_PHOTO", @""),
                           nil];
            actionSheet.tag = AS_PHOTO_EXISTING;
        }

        [actionSheet showInView:self.view];
    }
    else
    {
        [self clearKeyboardResponder];
        [self presentViewController:portraitPicker animated:YES completion:nil];
    }
}


//Delegate method to pass the picture to the image picker for modification and setting
- (void)photoEdited:(UIImage*)editedPhoto
{
    [self imagePickerController:nil didFinishPickingMediaWithInfo:[NSDictionary dictionaryWithObject:editedPhoto forKey:UIImagePickerControllerEditedImage]];
}

//Called when selecting or editing a picture
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //Hide the statusbar in this situation
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    //Set the portrait and dismiss the picker
    UIImage *pickedImage = info[UIImagePickerControllerEditedImage];
    
    //If an image was picked, save it and show the label
    if (pickedImage != nil)
    {
        // Set desired maximum height and calculate width
        CGFloat height = 640.0f;  // or whatever you need
        CGFloat width = (height / pickedImage.size.height) * pickedImage.size.width;

        // Resize the image
        UIImage * image = [pickedImage resizedImage:CGSizeMake(width, height) interpolationQuality:kCGInterpolationDefault];
        //Reload the portrait-controls
        [contact setImage:image];
        [self enableEditMode:YES];

        /*
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
        {
            //Reload the portrait-controls
            [contact setImage:pickedImage];
            [self enableEditMode:YES];
        });
         */
    }

    [portraitPicker dismissViewControllerAnimated:YES completion:NO];
}

#pragma mark - Actionsheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == AS_PHOTO || actionSheet.tag == AS_PHOTO_EXISTING)
    {
        //Take a picture for the portrait
        if (buttonIndex == 0)
        {
            //Force the camera to full-screen so the bars are automatically made translucant
            [self clearKeyboardResponder];
            portraitPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            
#warning - TO CHOOSE SOLUTION
            //OPTIE 2 (OPTIE 1 = decommented)
            //Scale the camera to fit the screen
//            portraitPicker.cameraViewTransform = CGAffineTransformMakeScale(1.3f, 1.3f);
            [self presentViewController:portraitPicker animated:YES completion:nil];
        }
        //Select a picture from the gallery
        else if (buttonIndex == 1)
        {
            [self clearKeyboardResponder];
            portraitPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:portraitPicker animated:YES completion:nil];
        }
        else if (actionSheet.tag == AS_PHOTO_EXISTING)
        {
            //Modify existing
            if (buttonIndex == 2)
            {
                [self clearKeyboardResponder];
                NBEditPhotoViewController * editPhotoViewController = [[NBEditPhotoViewController alloc]init];
                [editPhotoViewController setImageToEdit:[contact getImage:NO]];
                
                //Set a delegate (we can't use notifications, since the other tabs might be listening)
                [editPhotoViewController setPhotoDelegate:self];

                [self presentViewController:editPhotoViewController animated:YES completion:nil];
            }
            //Delete existing
            else if (buttonIndex == 3)
            {
                [self clearKeyboardResponder];
                UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                         delegate:self
                                                                cancelButtonTitle:NSLocalizedString(@"NCT_CANCEL", @"")
                                                           destructiveButtonTitle:NSLocalizedString(@"NCT_DELETE_PHOTO", @"")
                                                                otherButtonTitles:nil];
                actionSheet.tag = AS_DELETE_PHOTO;
                [actionSheet showInView:self.view];
            }
        }
    }
    else if (actionSheet.tag == AS_DELETE_PHOTO)
    {
        if (buttonIndex == 0)
        {
            //Delete the picture
            [self clearKeyboardResponder];
            [contact setImage:nil];
            [self setPortrait:YES];
        }
    }
    else if (actionSheet.tag == AS_DELETE_CONTACT)
    {
        if (buttonIndex == 0)
        {
            //Notify of the delete
            [[NSNotificationCenter defaultCenter] postNotificationName:NF_USER_DELETED object:[NSString stringWithFormat:@"%d", ABRecordGetRecordID(contact.contactRef)]];
            
            ABAddressBookRef addressBook = [[NBAddressBookManager sharedManager] getAddressBook];
            ABAddressBookRemoveRecord(addressBook, self.contact.contactRef, nil);
            ABAddressBookSave(addressBook, nil);
            
            //Reload the list
            [[NSNotificationCenter defaultCenter] postNotificationName:NF_RELOAD_CONTACTS object:nil];

            
            [self performSelector:@selector(delayedDismiss) withObject:nil afterDelay:0.5f];
        }
    }
}

- (void)delayedDismiss
{
    [self.navigationController popToRootViewControllerAnimated:YES];
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

#pragma mark - Button delegates
- (void)cancelPressed:(id)sender
{
    //If we're merging, dismiss the view, else end editing
    if (self.contactToMergeWith != nil)
    {
        [self dismissView];
    }
    else
    {
        //Re-fill with the contactref we have
        [personStructureManager reset];
        [personStructureManager fillWithContact:contact];
        
        //Disable edit mode
        [self enableEditMode:NO];
    }
}

- (void)donePressed:(id)sender
{
    //Signal for keyboards to resign
    [[NSNotificationCenter defaultCenter] postNotificationName:NF_RESIGN_EDITING object:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self continueDonePressed];
    });
}

- (void)continueDonePressed
{
    //When adding, dismiss after completion
    BOOL dismissAfterDone = NO;
    if (self.contact.isNewContact)
    {
        dismissAfterDone = YES;
    }
    
    //Save the contact
    [self.contact save:personStructureManager.tableStructure];
    
    //If we were merging, save and dismiss. Else, switch to non-edit mode
    if (self.contactToMergeWith != nil || dismissAfterDone)
    {
        [self dismissView];
    }
    else
    {
        [self enableEditMode:NO];
    }
    
    //Inform a delegate that we might have
    if (aNewContactDelegate != nil)
    {
        [aNewContactDelegate newPersonViewController:(NBNewPersonViewController*)self didCompleteWithNewPerson:self.contact.contactRef];
    }
    
    //Call for a reload of the list of contacts
    [[NSNotificationCenter defaultCenter] postNotificationName:NF_RELOAD_CONTACTS object:nil];
}

- (void)editPressed:(id)sender
{        
    [self enableEditMode:YES];
}

- (void)deleteContactPressed
{
    UIActionSheet * actionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"NCT_CANCEL", @"") destructiveButtonTitle:NSLocalizedString(@"BL_DELETE_CONTACT", @"") otherButtonTitles:nil];
    actionSheet.tag = AS_DELETE_CONTACT;
    [actionSheet showInView:self.tableView];
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

#pragma mark - Cleanup
- (void)dismissView
{
    //Resign all textfield delegates
    for (NSArray * infoArray in personStructureManager.tableStructure)
    {
        for (NBPersonCellInfo * cellInfo in infoArray)
        {
            NBPersonFieldTableCell * cell = [cellInfo getPersonFieldTableCell];
            if ([cell isKindOfClass:[NBPersonFieldTableCell class]])
            {
                [[cell cellTextfield] setDelegate:nil];
            }
        }
    }
    
    //Resign address delegates
    NSArray * addressArray = [personStructureManager.tableStructure objectAtIndex:CC_ADDRESS];
    for (NBPersonCellAddressInfo * addressInfo in addressArray)
    {
        [[addressInfo getAddressCell] setFieldDelegate:nil];
    }
    
    //Resign the portrait picker delegate
    [portraitPicker setDelegate:nil];
    
    //Resign notes delegate
    NSArray * notesArray = [personStructureManager.tableStructure objectAtIndex:CC_NOTES];
    if ([notesArray count] > 0)
    {
        [[[[notesArray lastObject] getNotesCell] cellTextview] setDelegate:nil];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

