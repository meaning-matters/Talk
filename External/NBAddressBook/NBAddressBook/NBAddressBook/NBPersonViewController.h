//
//  NBPersonViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/3/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//
//  Class to represent viewing and editing a person
//  NewPerson and UnknowPerson controllers inherit from this class to use a subset of its functionality

#import <UIKit/UIKit.h>
#import "NBContactStructureManager.h"
#import <AddressBook/AddressBook.h>
#import "NBValueListTableViewController.h"
#import "NSMutableString+Appending.h"
#import "NBContact.h"
#import "NSString+Common.h"
#import <QuartzCore/QuartzCore.h>
#import "NBRelatedPersonDelegate.h"
#import "NBPeoplePickerNavigationControllerDelegate.h"
#import "NBPersonViewControllerDelegate.h"

#define FACEBOOK_PREFIX @"facebook___"
#define FACEBOOK_SUFFIX @"(Facebook)"


@interface NBPersonViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, NBRelatedPersonDelegate>
{
    //The bar button items
    UIBarButtonItem * backButton;
    
    //Portrait controls
    UIButton * portraitButton;                  //The pressable button  (in edit-mode)
    UIImageView * portraitImageView;            //The non-pressable portrait edge (in non-edit mode)
    UIImage * portraitLine;         //The dotted line when editing the photo
    UIImage * portraitNoPhoto;      //The photo used when none is available
    UIImage * portraitCompanyNoPhoto; //The photo used when a company doesn't have a picture
    UIImage * portraitBackground;   //The portrait frame
    UILabel * addLabel;             //The Add-picture label in cae a pictue doesn't exist
    UIView * editLabelView;         //The edit-picture label in case a picture exists
    UIImage * selectedImage;        //The image selected by the user
    
    //Name label
    UILabel * nameLabel;
    
    //The structure representation
    NBContactStructureManager * personStructureManager;
    
    //The table header size
    int tableHeaderSize;
    
    //Target section for the date picker
    NSIndexPath * datePickerTargetRow;
    
    //Indicator for the initial load
    BOOL tableViewHasLoaded;

    //Index to set the related person in
    NSIndexPath * indexPathForRelatedPerson;
    
    //The three bottom buttons
    UIButton * firstFooterButton;
    UIButton * secondFooterButton;
    UIButton * thirdFooterButton;
    
    //Flag to indicate we're changing label (don't delete cell)
    BOOL changingLabel;
    
    //Keyboard management
    BOOL keyboardShown;
    CGFloat keyboardOverlap;
}

//Date picker for birthday and other anniversaries
@property (nonatomic) UIDatePicker *datePicker;

//The title table-view
@property (nonatomic) UITableView *tableView;

//The contact to show info for
@property (nonatomic) ABRecordRef displayedPerson;
@property (nonatomic) NBContact * contact;

//Contact to merge with (phone number only)
@property (nonatomic) NBContact * contactToMergeWith;

//The person view controller delegate
@property (nonatomic) id<NBPersonViewControllerDelegate> personViewDelegate;

//Wether the buttons at the bottom of the page are used
@property (nonatomic) BOOL allowsActions;

- (void)firstFooterButtonPressed;
- (void)secondFooterButtonPressed;
- (void)thirdFooterButtonPressed;

//Method to set the name label
- (void)setNameLabel;
- (int)measureLabelHeight:(NSString*)stringToMeasure usingFont:(UIFont*)font;

@end
