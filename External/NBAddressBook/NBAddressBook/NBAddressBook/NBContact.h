//
//  NBContact.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//
//  Wrapper-class for easy contact manipulation

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "NSMutableString+Appending.h"
#import "NBPersonCellInfo.h"
#import "NBPersonCellAddressInfo.h"
#import "NBAddressBookManager.h"
#import "CallRecordData.h"


@interface NBContact : NSObject
{
    UIImage * selectedImage;
}

//The contact to load and save with
@property (nonatomic) ABRecordRef contactRef;

//Flag to indicate this is a new contact
@property (nonatomic) BOOL isNewContact;

//Contact initialization
- (instancetype)initWithContact:(ABRecordRef)contact;

//Image management
- (UIImage*)getImage:(BOOL)original;
- (void)setImage:(UIImage*)image;

//Company check
- (BOOL)isCompany;

//Saving the tableview's values to the system
- (void)save:(NSMutableArray*)personCellStructure;
- (void)saveNotes:(NSString*)notesString;

//Representation support
+ (NSMutableAttributedString*)getListRepresentation:(ABRecordRef)contact;
+ (NSString*)getStringProperty:(ABPropertyID)property forContact:(ABRecordRef)contactRef;
+ (NSString*)getSortingProperty:(ABRecordRef)contactRef mustFormatNumber:(BOOL)mustFormatNumber;
+ (NSString*)getAvailableProperty:(ABPropertyID)property from:(ABRecordRef)contactRef;

//Call support
+ (void)makePhoneCall:(NSString*)phoneNumber
        withContactID:(NSString*)contactId;

@end
