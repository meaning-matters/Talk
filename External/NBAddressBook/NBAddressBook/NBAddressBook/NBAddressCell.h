//
//  NBAddressCell.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/11/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBDetailLineSeparatedCell.h"
#import <math.h>

//All possible celltypes
typedef enum
{
    AT_TYPE_0   = 0,
    AT_TYPE_1   = 1,
    AT_TYPE_2   = 2,
    AT_TYPE_3   = 3,
    AT_TYPE_4   = 4,
    AT_TYPE_5   = 5,
    AT_TYPE_6   = 6,
    AT_TYPE_7   = 7,
    AT_TYPE_8   = 8,
    AT_TYPE_9   = 9,
    AT_TYPE_10   = 10,
    AT_TYPE_11   = 11,
    AT_TYPE_12   = 12,
    AT_TYPE_13   = 13,
    AT_TYPE_14   = 14,
    AT_TYPE_15   = 15,
    AT_TYPE_16   = 16,
    AT_TYPE_17   = 17,
    AT_TYPE_18   = 18,
    AT_TYPE_19   = 19,
    AT_TYPE_20   = 20,
    AT_TYPE_21   = 21,
    AT_TYPE_22   = 22,
    AT_TYPE_23   = 23,
    AT_TYPE_24   = 24,
    AT_TYPE_25   = 25,
    AT_TYPE_26   = 26,
    AT_TYPE_27   = 27,
    AT_TYPE_28   = 28,
    AT_TYPE_29   = 29,
    AT_TYPE_30   = 30,
    AT_TYPE_31   = 31,
    AT_TYPE_32   = 32,
    AT_TYPE_33   = 33
} AddressType;

//All possible celltypes
typedef enum
{
    LT_FULL   = 0,
    LT_LEFT   = 1,
    LT_RIGHT  = 2
} LineType;

//All possible celltypes
typedef enum
{
    TT_STREET   = 0,
    TT_CITY     = 1,
    TT_COUNTRY  = 2,
    TT_POSTAL_CODE = 3,
    TT_PROVINCE = 4,
    TT_SUBURB   = 5,
    TT_STATE    = 6,
    TT_ZIP      = 7,
    TT_ISLAND_NAME  = 8,
    TT_POSTAL_DISTRICT = 9,
    TT_GOVERNATE    = 10,
    TT_DEPARTMENT   = 11,
    TT_DISTRICT     = 12,
    TT_PREFECTURE   = 13,
    TT_FURTHER      = 14,
    TT_COUNTY       = 15,
    TT_REGION       = 16,
    TT_PIN          = 17
} TextfieldType;

//Static positions of textfields
#define LEFT_X_POS_TEXTFIELD   85
#define RIGHT_X_POS_TEXTFIELD  180
#define WIDTH_TEXTFIELD        180

//Measure size for the label
#define HEIGHT_MEASURE_SIZE     20

@interface NBAddressCell : NBDetailLineSeparatedCell
{    
    //Indicator to show where in the array the separators start
    int textfieldSeparatorPosition;
    
    //The start-position for lines
    int horiLineStartPosition;
    
    //The current address type
    AddressType currentType;
}

//Collection of street-textfields
@property (nonatomic) NSMutableArray * streetTextfields;
@property (nonatomic) UITextField * cityTextfield;
@property (nonatomic) UITextField * ZIPTextfield;
@property (nonatomic) UITextField * stateTextfield;
@property (nonatomic) UITextField * countryTextfield;

//A single label representing the cell when not editing
@property (nonatomic) UILabel * representationLabel;

//Collection of separators
@property (nonatomic) NSMutableArray * separators;

//Collection of applicable textfields
@property (nonatomic) NSMutableArray * applicableFields;

//Flag to indicate that though the user might've switched textfields, this cell is still 'selected' and shouldn't be removed
@property (nonatomic) UITextField * editingTextfield;

//The top cell to focus on in case this field is newly added
@property (nonatomic) UITextField * topTextfield;

//Overloaded constructor
- (instancetype)initWithStyle:(UITableViewCellStyle)style;

//Adding/removing a new field post-creation
- (UITextField*)addTextfieldForPosition:(int)position andLineType:(LineType)lineType andTextfieldType:(TextfieldType)textfieldType;
- (void)removeStreetfield:(UITextField*)textfield;
- (void)setEditing:(BOOL)editing;

//Public methods for formatting and height
- (void)formatUsingType:(NSString*)countryCode;
+ (CGFloat)determineAddressCellHeight:(NSString*)countryCode;
+ (int)determineAddressTypeCountryCode:(NSString*)countryCode;
+ (NSString*)getStringForStreets:(NSArray*)streets andState:(NSString*)state andZipCode:(NSString*)zipCode andCity:(NSString*)city andCountry:(NSString*)country;
@end
