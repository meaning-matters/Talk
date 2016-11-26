//
//  NBAddressBook.h
//  Talk
//
//  Created by Cornelis van der Bent on 14/10/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#ifndef Talk_NBAddressBook_h
#define Talk_NBAddressBook_h

#import <Foundation/Foundation.h>
#import "Skinning.h"


//Hide or show ringtines
//#define NB_HAS_RING_TONES

//Animation speed (used for switching between cell states)
#define ANIMATION_SPEED 0.3f

//Used for string measurement
#define SIZE_NAME_LABEL_MEASURE   200
#define SIZE_NAME_LABEL_MIN        60

//Cell and textfield heights
#define SIZE_CELL_HEIGHT           44
#define SIZE_TEXTVIEW_WIDTH       210

//Fonts and colors used
#define FONT_LABEL              [UIFont systemFontOfSize:13]
#define FONT_ADDRESS            [UIFont boldSystemFontOfSize:14]
#define FONT_NOTES              [UIFont boldSystemFontOfSize:15]
#define FONT_COLOR_MY_NUMBER    [UIColor colorWithRed: 91/255.0f green:108/255.0f blue:132/255.0f alpha:1.0f]
#define FONT_COLOR_LABEL        [Skinning tintColor]
#define FONT_COLOR_LIGHT_GREY   [UIColor colorWithRed:204/255.0f green:204/255.0f blue:204/255.0f alpha:1.0f]

#define PERSON_BACKGROUND_COLOR [UIColor colorWithRed:191/255.0f green:191/255.0f blue:196/255.0f alpha:1.0f]

//The section for this tableview
typedef enum  : NSUInteger
{
    CC_FILLER             =  0,
    CC_NAME               =  1,
    CC_NUMBER             =  2,
    CC_EMAIL              =  3,
    CC_RINGTONE           =  4,
    CC_HOMEPAGE           =  5,
    CC_ADDRESS            =  6,
    CC_BIRTHDAY           =  7,
    CC_OTHER_DATES        =  8,
    CC_RELATED_CONTACTS   =  9,
    CC_SOCIAL             = 10,
    CC_IM                 = 11,
    CC_NOTES              = 12,
    CC_CALLER_ID          = 13,
    CC_NUMBER_OF_SECTIONS = 14, // This is valid when start at 0, and use every value 0, 1, ...
} ContactCell;

//Possible 'New' fields
typedef enum : NSUInteger
{
    NF_NAME     = 0,
    NF_SOCIAL   = 1,
    NF_IM       = 2,
    NF_BIRTHDAY = 3,
    NF_DATES    = 4,
    NF_RELATED  = 5,
    NF_NOTES    = 6
} NewField;

//Name components
typedef enum : NSUInteger
{
    NC_PREFIX           = 0,
    NC_FIRST_NAME       = 1,
    NC_PHONETIC_FIRST   = 2,
    NC_MIDDLE_NAME      = 3,
    NC_LAST_NAME        = 4,
    NC_PHONETIC_LAST    = 5,
    NC_SUFFIX           = 6,
    NC_NICKNAME         = 7,
    NC_JOB_TITLE        = 8,
    NC_DEPARTMENT       = 9,
    NC_COMPANY          = 10
} NameComponent;

//Flag to indicate a type of label
typedef enum : NSUInteger
{
    LT_NUMBER       = 0,
    LT_EMAIL        = 1,
    LT_WEBSITE      = 2,
    LT_RINGTONE     = 3,
    LT_VIBRATION    = 4,
    LT_SOCIAL       = 5,
    LT_IM_LABEL     = 6,
    LT_IM_SERVICE   = 7,
    LT_RELATED      = 8,
    LT_ADDRESS      = 9,
    LT_DATE         = 10
} LabelType;

//'Unknown Contact' sections
typedef enum : NSUInteger
{
    UP_FILLER   = 0,
    UP_EMAIL    = 1,
    UP_CONTACT  = 2,
    UP_ADD      = 3,
    UP_SHARE    = 4
} UnknownContactSection;

//Constants used for address buildup
#define ADDRESS_KEY_STREET  @"Street"
#define ADDRESS_KEY_CITY    @"City"
#define ADDRESS_KEY_ZIP     @"ZIP"
#define ADDRESS_KEY_COUNTRY @"Country"
#define ADDRESS_KEY_STATE   @"State"
#define ADDRESS_KEY_COUNTRY_CODE @"CountryCode"

//UserDefaults keys for custom arrays of labels
#define UD_NUMBER_CUSTOM_LABELS_ARRAY   @"UD_NUMBER_CUSTOM_LABELS"
#define UD_MAIL_CUSTOM_LABELS_ARRAY     @"UD_MAIL_CUSTOM_LABELS"
#define UD_WEBSITE_CUSTOM_LABELS_ARRAY  @"UD_WEBSITE_CUSTOM_LABELS"
#define UD_SOCIAL_CUSTOM_LABELS_ARRAY   @"UD_SOCIAL_CUSTOM_LABELS"
#define UD_IM_CUSTOM_LABELS_ARRAY       @"UD_IM_CUSTOM_LABELS"
#define UD_IM_CUSTOM_SERVICES_ARRAY     @"UD_IM_CUSTOM_SERVICES"
#define UD_RELATED_CUSTOM_LABELS_ARRAY  @"UD_RELATED_CUSTOM_LABELS_ARRAY"
#define UD_ADDRESS_CUSTOM_LABELS_ARRAY  @"UD_ADDRESS_CUSTOM_LABELS_ARRAY"
#define UD_DATE_CUSTOM_LABELS_ARRAY     @"UD_DATE_CUSTOM_LABELS_ARRAY"

//Notification for resigning keyboards
#define NF_RESIGN_EDITING @"NF_RESIGN_EDITING"

//Group management
#define NF_USER_DELETED     @"NF_USER_DELETED"
#define NF_SAVE_GROUPS      @"NF_SAVE_GROUPS"
#define UD_GROUPS           @"UD_GROUPS"
#define NF_ADD_TO_GROUP     @"NF_ADD_TO_GROUP"
#define NF_KEY_CONTACT_ID   @"NF_KEY_CONTACT_ID"
#define NF_KEY_GROUPNAME    @"NF_KEY_GROUPNAME"

#define PROP_GROUP_SELECTED @"PROP_GROUP_SELECTED"
#define PROP_GROUP_CONTACTS @"PROP_GROUP_CONTACTS"

//Notification for custom labels
#define NF_MUTATE_CUSTOM_LABEL  @"NF_MUTATE_CUSTOM_LABEL"
#define NF_KEY_LABEL_VALUE      @"NF_KEY_LABEL_VALUE"
#define NF_KEY_ADD_NEW_LABEL    @"NF_KEY_ADD_NEW_LABEL"

//Notification for address field modification
#define NF_KEY_CELL             @"NF_KEY_CELL"
#define NF_KEY_TEXTFIELD        @"NF_KEY_TEXTFIELD"

//Notification for address book reload
#define NF_RELOAD_CONTACTS @"NF_RELOAD_CONTACTS"

//Notification to just reload a contact
#define NF_RELOAD_CONTACT @"NF_RELOAD_CONTACT"

//String constants used
#define KEY_USERNAME    @"username"
#define KEY_SERVICE     @"service"

//Default values of labels
#define NUMBER_ARRAY    @[(NSString*)kABPersonPhoneMobileLabel, (NSString*)kABPersonPhoneIPhoneLabel, (NSString*)kABHomeLabel, (NSString*)kABWorkLabel, (NSString*)kABPersonPhoneMainLabel, (NSString*)kABPersonPhoneHomeFAXLabel, (NSString*)kABPersonPhoneWorkFAXLabel, (NSString*)kABPersonPhoneOtherFAXLabel, (NSString*)kABPersonPhonePagerLabel, (NSString*)kABOtherLabel]

#define RELATED_ARRAY   @[(NSString*)kABPersonMotherLabel, (NSString*)kABPersonFatherLabel, (NSString*)kABPersonParentLabel, (NSString*)kABPersonBrotherLabel, (NSString*)kABPersonSisterLabel, (NSString*)kABPersonChildLabel, (NSString*)kABPersonFriendLabel, (NSString*)kABPersonSpouseLabel, (NSString*)kABPersonPartnerLabel, (NSString*)kABPersonAssistantLabel, (NSString*)kABPersonManagerLabel, (NSString*)kABOtherLabel]

#define HWO_ARRAY       @[(NSString*)kABHomeLabel, (NSString*)kABWorkLabel, (NSString*)kABOtherLabel]

#define WEB_ARRAY       @[(NSString*)kABPersonHomePageLabel, (NSString*)kABHomeLabel, (NSString*)kABWorkLabel, (NSString*)kABOtherLabel]

#define SOCIAL_ARRAY    @[(NSString*)kABPersonSocialProfileServiceFacebook, (NSString*)kABPersonSocialProfileServiceTwitter, (NSString*)kABPersonSocialProfileServiceFlickr, (NSString*)kABPersonSocialProfileServiceLinkedIn, (NSString*)kABPersonSocialProfileServiceMyspace, (NSString*)kABPersonSocialProfileServiceSinaWeibo, (NSString*)kABOtherLabel]

#define IM_ARRAY        @[(NSString*)kABPersonInstantMessageServiceSkype, (NSString*)kABPersonInstantMessageServiceMSN, (NSString*)kABPersonInstantMessageServiceGoogleTalk, (NSString*)kABPersonInstantMessageServiceFacebook, (NSString*)kABPersonInstantMessageServiceAIM, (NSString*)kABPersonInstantMessageServiceYahoo, (NSString*)kABPersonInstantMessageServiceICQ, (NSString*)kABPersonInstantMessageServiceJabber, (NSString*)kABPersonInstantMessageServiceQQ, (NSString*)kABPersonInstantMessageServiceGaduGadu]

#define DATE_ARRAY  @[(NSString*)kABPersonAnniversaryLabel, (NSString*)kABOtherLabel];

#define RINGTONE_ARRAY  @[@"RT_DEFAULT", @"RT_NONE"]
#define VIBRATION_ARRAY @[@"RT_DEFAULT", @"RT_VIBRATION", @"RT_NONE"]

#endif
