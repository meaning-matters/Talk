//
//  NBPersonViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/3/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//
//  Class to represent viewing and editing a person
//  NewPerson and UnknowPerson controllers inherit from this class to use a subset of its functionality

#import <UIKit/UIKit.h>
#import "NBContactStructureManager.h"
#import <AddressBook/AddressBook.h>
#import "NBNewFieldTableViewController.h"
#import "NBValueListTableViewController.h"
#import "NSMutableString+Appending.h"
#import "NBContact.h"
#import "NSString+Common.h"
#import "NBAddressFieldHandler.h"
#import "NBEditPhotoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NBRelatedPersonDelegate.h"
#import "NBPeoplePickerNavigationControllerDelegate.h"
#import "NBPersonViewControllerDelegate.h"
#import "NBNewPersonViewControllerDelegate.h"

#define FACEBOOK_PREFIX @"facebook"
#define FACEBOOK_SUFFIX @"(Facebook)"

//Flag to indicate a type of label
typedef enum
{
    AS_PHOTO            = 0,
    AS_PHOTO_EXISTING   = 1,
    AS_DELETE_PHOTO     = 2,
    AS_DELETE_CONTACT   = 3
} ActionSheetType;

@interface NBPersonViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIActionSheetDelegate, NBAddressFieldHandler, NBPersonViewDelegate, NBPhotoDelegate, NBRelatedPersonDelegate>
{
    //The bar button items
    UIBarButtonItem * doneButton;
    UIBarButtonItem * editButton;
    UIBarButtonItem * backButton;
    UIBarButtonItem * cancelButton;
    
    //Portrait controls
    UIButton * portraitButton;                  //The pressable button  (in edit-mode)
    UIImageView * portraitImageView;            //The non-pressable portrait edge (in non-edit mode)
    UIImagePickerController * portraitPicker;   //Picker for the image
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
    
    //Index path to focus on and its active responder
    NSIndexPath * indexPathToFocusOn;
    
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

//DEPRECATED
//The delete-button when editing a contact
//@property (weak, nonatomic) UIButton *deleteButton;

//The delegate to inform we added/updated this contact
@property (nonatomic) id<NBNewPersonViewControllerDelegate> aNewContactDelegate;

//The navigation controller delegate
@property (nonatomic) id<NBPeoplePickerNavigationControllerDelegate> peoplePickerDelegate;

//The person view controller delegate
@property (nonatomic) id<NBPersonViewControllerDelegate> personViewDelegate;

//Wether the buttons at the bottom of the page are used
@property (nonatomic) BOOL allowsActions;

//Wether the record allows for editing
@property (nonatomic) BOOL allowsEditing;

- (void)firstFooterButtonPressed;
- (void)secondFooterButtonPressed;
- (void)thirdFooterButtonPressed;

//Method to set the name label
- (void)setNameLabel;
- (int)measureLabelHeight:(NSString*)stringToMeasure usingFont:(UIFont*)font;

//Methods shared with inheriting classes
- (void)enableEditMode:(BOOL)enable;
- (void)showDatePicker:(BOOL)show animated:(BOOL)animated;

//Button delegates
- (void)editPressed:(id)sender;
- (void)cancelPressed:(id)sender;
- (void)donePressed:(id)sender;
- (void)continueDonePressed;
@end
