//
//  NBAddressCell.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/11/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBAddressCell.h"
#import <AddressBook/AddressBook.h>


@interface NBAddressCell () <UITextFieldDelegate>
@end


@implementation NBAddressCell

@synthesize streetTextfields, cityTextfield, ZIPTextfield, stateTextfield, countryTextfield, separators, applicableFields, representationLabel, editingTextfield;

- (instancetype)initWithStyle:(UITableViewCellStyle)style
{
    if (self = [super initWithStyle:style reuseIdentifier:nil])
    {
        streetTextfields = [[NSMutableArray alloc] init];
        separators = [[NSMutableArray alloc] init];
        applicableFields = [[NSMutableArray alloc] init];
        
        //The start-position for horizontal lines
        horiLineStartPosition = self.contentView.bounds.size.width/4;
        
        //The representationlabel
        self.representationLabel = [[UILabel alloc] initWithFrame:CGRectMake(LEFT_X_POS_TEXTFIELD, 12, WIDTH_TEXTFIELD, HEIGHT_MEASURE_SIZE)];
        [self.representationLabel setFont:FONT_ADDRESS];
//        [self.representationLabel setHighlightedTextColor:[UIColor whiteColor]];
        [self.representationLabel setBackgroundColor:[UIColor clearColor]];
        self.representationLabel.numberOfLines = 0;
        [self.representationLabel setHidden:YES];
        [self addSubview:self.representationLabel];
    }
    return self;
}

- (void)resignEditing
{
    [self endEditing:YES];
}

#pragma mark - Textfield frame support
- (UITextField*)addTextfieldForPosition:(int)position andLineType:(LineType)lineType andTextfieldType:(TextfieldType)textfieldType
{
    //If -1 was given for a position, we need to dynamically determine the location of a street-cell
    UITextField * lastStreetfield = nil;
    if (position == -1)
    {
        for (UITextField * textField in applicableFields)
        {
            if (textField.tag == TT_STREET)
            {
                lastStreetfield = textField;
            }
        }
        //Calculate the relative position of the new part of the cell 
        position = floor( lastStreetfield.frame.origin.y / SIZE_CELL_HEIGHT) + 1;
    }

    //Build up the frame
    CGRect frame = CGRectMake(
                              lineType == LT_RIGHT ? RIGHT_X_POS_TEXTFIELD : LEFT_X_POS_TEXTFIELD,
                              position*SIZE_CELL_HEIGHT,
                              lineType == LT_FULL ? WIDTH_TEXTFIELD : WIDTH_TEXTFIELD / 2.1f,
                              SIZE_CELL_HEIGHT);
    
    //Build up the field
    UITextField * textField = [[UITextField alloc] initWithFrame:frame];
    [textField setClearButtonMode:UITextFieldViewModeNever];
    switch (textfieldType) {
        case TT_STREET:
        {
            [textField setPlaceholder:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonAddressStreetKey))];
        
            //Remember the textfield
            [streetTextfields addObject:textField];
            break;
        }
        case TT_CITY:
        {
            cityTextfield = textField;
            [textField setPlaceholder:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonAddressCityKey))];
            break;
        }
        case TT_COUNTRY:
        {
            countryTextfield = textField;
            
            //Allow for country selection
            UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectCountry)];
            singleTap.numberOfTapsRequired = 1;
            [textField addGestureRecognizer:singleTap];
            break;
        }
        case TT_POSTAL_CODE:
        {
            [textField setPlaceholder:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonAddressZIPKey))];
            ZIPTextfield = textField;
            
            //Set the keyboard type to numbers
            [textField setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
            break;
        }
        case TT_PROVINCE:
        {
            [textField setPlaceholder:@"Province"];
            stateTextfield = textField;
            break;
        }
        case TT_SUBURB:
        {
            [textField setPlaceholder:@"XSuburb"];
            stateTextfield = textField;
        }
            break;
        case TT_STATE:
        {            
            [textField setPlaceholder:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonAddressStateKey))];
            //In case of Australia, a country can have both a state and suburb, so we'll reuse the city-textfield
            if (stateTextfield != nil)
            {
                cityTextfield = textField;
            }
            else
            {
                stateTextfield = textField;
            }
            break;
        }
        case TT_ZIP:
        {
            [textField setPlaceholder:(__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonAddressZIPKey))];
            ZIPTextfield = textField;
            
            //Set the keyboard type to numbers
            [textField setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
            break;
        }
        case TT_ISLAND_NAME:
        {
            [textField setPlaceholder:@"Island name"];            
            stateTextfield = textField;
            break;
        }
        case TT_POSTAL_DISTRICT:
        {
            [textField setPlaceholder:@"Postal district"];
            stateTextfield = textField;
            break;
        }
        case TT_GOVERNATE:
        {
            [textField setPlaceholder:@"Governate"];
            stateTextfield = textField;
            break;
        }
        case TT_DEPARTMENT:
        {
            [textField setPlaceholder:@"Department"];
            stateTextfield = textField;
            break;
        }
        case TT_DISTRICT:
        {
            [textField setPlaceholder:@"District"];
            stateTextfield = textField;
            break;
        }
        case TT_PREFECTURE:
        {
            [textField setPlaceholder:@"Prefecture"];
            stateTextfield = textField;
            break;
        }
        case TT_FURTHER:
        {
            [textField setPlaceholder:@"Further"];
            stateTextfield = textField;
            break;
        }
        case TT_COUNTY:
        {
            [textField setPlaceholder:@"County"];            
            stateTextfield = textField;
            break;
        }
        case TT_REGION:
        {
            [textField setPlaceholder:@"Region"];
            stateTextfield = textField;
            break;
        }
        case TT_PIN:
        {
            [textField setPlaceholder:@"Pin Code"];
            ZIPTextfield = textField;
            
            //Set the keyboard type to numbers
            [textField setKeyboardType:UIKeyboardTypeNumberPad];
            break;
        }
        default:
        {
            break;
        }
    }
    
    //If this is the top textfield, remember it so we can focus on it later on
    if (position == 0)
    {
        self.topTextfield = textField;
    }
    
    //Remember this textfield was used
    if (textfieldType == TT_STREET)
    {
        //Find the last street-textfield
        NSUInteger newStreetIndex = [applicableFields count];
        for (int pos = 0; pos < [applicableFields count]; pos++)
        {
            UITextField * tv = [applicableFields objectAtIndex:pos];
            if (tv.tag == TT_STREET)
            {
                newStreetIndex = pos + 1;
            }
        }
        
        //If there are cells below the street, shift them down
        if (newStreetIndex != [applicableFields count])
        {
            //Shift the textfields
            for (NSUInteger shiftViewPos = newStreetIndex; shiftViewPos < [applicableFields count]; shiftViewPos++)
            {
                UITextField * textField = [applicableFields objectAtIndex:shiftViewPos];
                textField.center = CGPointMake( textField.center.x, textField.center.y + SIZE_CELL_HEIGHT);
            }
            
            //Shift the lines
            for (int sepPos = textfieldSeparatorPosition; sepPos < [separators count]; sepPos++)
            {
                UIView * curView = [separators objectAtIndex:sepPos];
                curView.center = CGPointMake( curView.center.x, curView.center.y + SIZE_CELL_HEIGHT);
            }
        }
        
        //Insert the field
        [applicableFields insertObject:textField atIndex:newStreetIndex];
    }
    else
    {
        //Just add it
        [applicableFields addObject:textField];
    }
    
    //Add a vertical line separator if it's a full-or right
    if (( lineType == LT_RIGHT || lineType == LT_FULL) && position != 0)
    {
        //Build up and display the separator
        int yPosition = position * SIZE_CELL_HEIGHT;
        UIView * lineView = [self getHorizontalLineviewWithFrame:CGRectMake(horiLineStartPosition,
                                                        yPosition,
                                                        188,
                                                        1)];
        
        //Remember the separator to mutate its position, visibility and existance
        if (textField.tag == TT_STREET)
        {
            [separators insertObject:lineView atIndex:textfieldSeparatorPosition];
            
            //Shift down the street position
            textfieldSeparatorPosition += 1;
        }
        else
        {
            [separators addObject:lineView];
        }
    }
    
    //In case of LT_LEFT types, add a separator
    if (lineType == LT_LEFT)
    {
        //Build up and display the separator
        UIView * lineView = [[UIView alloc] initWithFrame:
                             CGRectMake(RIGHT_X_POS_TEXTFIELD - 5,
                                        (position*SIZE_CELL_HEIGHT),
                                        1,
                                        SIZE_CELL_HEIGHT)];
        lineView.backgroundColor = FONT_COLOR_LIGHT_GREY;
        [self.contentView addSubview:lineView];
        
        //Remember the separator to mutate its position, visibility and existance
        [separators addObject:lineView];
    }
    
    //Set the textfield's font and add it
    [textField setBackgroundColor:[UIColor clearColor]];
    [textField setFont:[UIFont boldSystemFontOfSize:15]];
    [textField setTextAlignment:NSTextAlignmentLeft];
    [textField setTag:textfieldType];
    [textField setDelegate:self];
    [self.contentView addSubview:textField];
    
    //Center the textfield properly
    [textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    
    return textField;
}

- (void)removeStreetfield:(UITextField*)textfield
{    
    //Shift up the frames and textfields below this textfield
    NSUInteger textfieldPosition = [applicableFields indexOfObject:textfield];
    for (NSInteger shiftPos = textfieldPosition; shiftPos < [applicableFields count]; shiftPos++)
    {
        UIView * view = [applicableFields objectAtIndex:shiftPos];
        view.center = CGPointMake( view.center.x, view.center.y - SIZE_CELL_HEIGHT);
    }
    
    //Remove the textfield and line
    [textfield removeFromSuperview];
    [applicableFields removeObject:textfield];
    [streetTextfields removeObject:textfield];
}


#pragma mark - Support to build up the address cell based on type
- (void)formatUsingType:(NSString*)countryCode
{
    //Clear the old fields
    NSArray * allFields = [[streetTextfields arrayByAddingObjectsFromArray:applicableFields] arrayByAddingObjectsFromArray:separators];
    for (UIView * view in allFields)
    {
        [view removeFromSuperview];
    }

    [streetTextfields removeAllObjects];
    [applicableFields removeAllObjects];
    [separators removeAllObjects];
    
    //Determine type based on locale
    currentType = [NBAddressCell determineAddressCellTypeCountryCode:countryCode];
    switch (currentType)
    {
        case AC_TYPE_0:
        {
            //(Albania)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_1:
        {
            //(Algaria)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_2:
        {
            //(Argentina)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_PROVINCE];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_3:
        {
            //(Argentina)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_SUBURB];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_STATE];
            [self addTextfieldForPosition:2 andLineType:LT_LEFT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:2 andLineType:LT_RIGHT andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_4:
        {
            //(Belize)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_PROVINCE];
            [self addTextfieldForPosition:3 andLineType:LT_RIGHT andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_5:
        {
            //(The Bahamas)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_ISLAND_NAME];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_6:
        {
            //(Bahrain)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_7:
        {
            //(Brazil)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_ZIP];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:2 andLineType:LT_LEFT andTextfieldType:TT_PROVINCE];
            [self addTextfieldForPosition:2 andLineType:LT_RIGHT andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_8:
        {
            //(Canada)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_PROVINCE];
            [self addTextfieldForPosition:2 andLineType:LT_LEFT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:2 andLineType:LT_RIGHT andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_9:
        {
            //(Cayman Islands)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_ISLAND_NAME];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_10:
        {
            //(China)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_PROVINCE];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_POSTAL_CODE];
            textfieldSeparatorPosition = 3;
            break;
        }
        case AC_TYPE_11:
        {
            //(Dominican Republic)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_POSTAL_DISTRICT];
            [self addTextfieldForPosition:2 andLineType:LT_LEFT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:2 andLineType:LT_RIGHT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_12:
        {
            //(Ecuador)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_13:
        {
            //(Egypt)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_DISTRICT];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_GOVERNATE];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_14:
        {
            //(El Salvador)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_DEPARTMENT];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_15:
        {
            //(Falkland Islands)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_16:
        {
            //(Fiji)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_POSTAL_DISTRICT];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_17:
        {
            //(French Pol)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:2 andLineType:LT_LEFT andTextfieldType:TT_ISLAND_NAME];
            [self addTextfieldForPosition:2 andLineType:LT_RIGHT andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_18:
        {
            //(Greenland)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_POSTAL_DISTRICT];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_19:
        {
            //(Hong Kong)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_REGION];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_DISTRICT];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_STREET];
            textfieldSeparatorPosition = 3;
            break;
        }
        case AC_TYPE_20:
        {
            //(Hungary)
            [self addTextfieldForPosition:0 andLineType:LT_LEFT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:0 andLineType:LT_RIGHT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 2;
            break;
        }
        case AC_TYPE_21:
        {
            //(India)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_PROVINCE];
            [self addTextfieldForPosition:2 andLineType:LT_LEFT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:2 andLineType:LT_RIGHT andTextfieldType:TT_PIN];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_22:
        {
            //(Ireland)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_COUNTY];
            [self addTextfieldForPosition:2 andLineType:LT_LEFT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:2 andLineType:LT_RIGHT andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_23:
        {
            //(Japan)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_PREFECTURE];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_COUNTY];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_FURTHER];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = NSIntegerMax;
            break;
        }
        case AC_TYPE_24:
        {
            //(Kazakhstan)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_POSTAL_DISTRICT];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_POSTAL_CODE];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_25:
        {
            //(South Korea)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            [self addTextfieldForPosition:2 andLineType:LT_LEFT andTextfieldType:TT_PROVINCE];
            [self addTextfieldForPosition:2 andLineType:LT_RIGHT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_STREET];
            textfieldSeparatorPosition = 4;
            break;
        }
        case AC_TYPE_26:
        {
            //(Macau)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_DISTRICT];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_STREET];
            textfieldSeparatorPosition = 3;
            break;
        }
        case AC_TYPE_27:
        {
            //(Malaysia)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:2 andLineType:LT_LEFT andTextfieldType:TT_STATE];
            [self addTextfieldForPosition:2 andLineType:LT_RIGHT andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_28:
        {
            //(Micronesia)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_STATE];
            [self addTextfieldForPosition:2 andLineType:LT_LEFT andTextfieldType:TT_ZIP];
            [self addTextfieldForPosition:2 andLineType:LT_RIGHT andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_29:
        {
            //(New Zealand)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];            
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_SUBURB];
            [self addTextfieldForPosition:2 andLineType:LT_LEFT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:2 andLineType:LT_RIGHT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_30:
        {
            //(Somalia)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_LEFT andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:1 andLineType:LT_RIGHT andTextfieldType:TT_REGION];
            [self addTextfieldForPosition:2 andLineType:LT_LEFT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:2 andLineType:LT_RIGHT andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_31:
        {
            //(Taiwan)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_ZIP];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_COUNTY];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_DISTRICT];
            [self addTextfieldForPosition:4 andLineType:LT_FULL andTextfieldType:TT_STREET];
            textfieldSeparatorPosition = 4;
            break;
        }
        case AC_TYPE_32:
        {
            //(Thailand)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_DISTRICT];
            [self addTextfieldForPosition:2 andLineType:LT_LEFT andTextfieldType:TT_PROVINCE];
            [self addTextfieldForPosition:2 andLineType:LT_RIGHT andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        case AC_TYPE_33:
        {
            //(United Kingdom)
            [self addTextfieldForPosition:0 andLineType:LT_FULL andTextfieldType:TT_STREET];
            [self addTextfieldForPosition:1 andLineType:LT_FULL andTextfieldType:TT_CITY];
            [self addTextfieldForPosition:2 andLineType:LT_FULL andTextfieldType:TT_COUNTY];
            [self addTextfieldForPosition:3 andLineType:LT_FULL andTextfieldType:TT_POSTAL_CODE];
            [self addTextfieldForPosition:4 andLineType:LT_FULL andTextfieldType:TT_COUNTRY];
            textfieldSeparatorPosition = 0;
            break;
        }
        default:
        {
            break;
        }
    }
}

- (UIView*)getHorizontalLineviewWithFrame:(CGRect)frame
{
    UIView * lineView = [[UIView alloc] initWithFrame:frame];
    lineView.backgroundColor = FONT_COLOR_LIGHT_GREY;
    [self.contentView addSubview:lineView];
    return lineView;
}

#pragma mark - Country selection
- (void)selectCountry
{
#warning - put your country-selection + flag here
    NBLog( @"Select your country");
}

#pragma mark - Editing handling
- (void)setEditing:(BOOL)editing
{
    //Don't do this for the add-cell
    if ([streetTextfields count] != 0)
    {
        //Show each of the textfields
        for (UITextField * textField in streetTextfields)
        {
            [textField setHidden:!editing];
        }
        [cityTextfield setHidden:!editing];
        [ZIPTextfield setHidden:!editing];
        [stateTextfield setHidden:!editing];
        [countryTextfield setHidden:!editing];
        
        //Show the lines only when editing
        for (UIView * line in separators)
        {
            [line setHidden:!editing];
        }
        
        //Show this label only when not editing
        [self.representationLabel setHidden:editing];
        
        //Build up a string-array for the streets to measure
        NSMutableArray * streetsArray = [NSMutableArray array];
        for (UITextField * tv in streetTextfields)
        {
            if ([tv.text length] > 0)
            {
                [streetsArray addObject:tv.text];
            }
        }
        NSString * representationString = [NBAddressCell getStringForStreets:streetsArray andState:stateTextfield.text andZipCode:ZIPTextfield.text andCity:cityTextfield.text andCountry:countryTextfield.text];
        
        //Split up the string based on newlines and measure it
        CGRect measureFrame = CGRectMake( 0, 0, WIDTH_TEXTFIELD, HEIGHT_MEASURE_SIZE);
        NSArray * splitArray = [representationString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        int labelHeight = 0;
        
        for (int n = 0; n < splitArray.count; n++)
        {
            CGSize labelSize = [representationString sizeWithFont:representationLabel.font
                                                constrainedToSize:measureFrame.size];
            labelHeight += ceil(labelSize.height);
        }
        
        CGRect labelFrame = self.representationLabel.frame;
        labelFrame.size.height = labelHeight;
        [representationLabel setFrame:labelFrame];
        [representationLabel setText:representationString];
    }
}

//These methods are static, because cells might not yet exist when we request the height and type
#pragma mark - Determining address cell type and height
+ (AddressCellType)determineAddressCellTypeCountryCode:(NSString*)countryCode
{
    //Read in mapping from country to address cell type
    NSDictionary * typeForCountryDictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"NBAddressCellTypes" ofType:@"plist"]];
    return [[typeForCountryDictionary objectForKey:countryCode] intValue];
}

+ (NSString*)getStringForStreets:(NSArray*)streets andState:(NSString*)state andZipCode:(NSString*)zipCode andCity:(NSString*)city andCountry:(NSString*)country
{
    //If we're not editing, set the label
    //The first part of the address, composed of streets
    NSMutableString * firstPart = [NSMutableString string];
    for (NSString * street in streets)
    {
        if ([street length] > 0)
        {
            [firstPart appendFormat:@"%@\n", street];
        }
    }
    
    //The second part of the address
    NSMutableString * secondPart = [NSMutableString string];
    if ([zipCode length] > 0)
    {
        [secondPart appendString:zipCode];
    }
    if ([city length] > 0)
    {
        if ([secondPart length] > 0)
        {
            [secondPart appendFormat:@" %@", city];
        }
        else
        {
            [secondPart appendString:city];
        }
    }
    if ([secondPart length] > 0)
    {
        [secondPart appendString:@"\n"];
    }
    
    //Total string (country always exists)
    return [NSString stringWithFormat:@"%@%@%@", firstPart, secondPart, country];
}


+ (CGFloat)determineAddressCellHeight:(NSString*)countryCode
{
    AddressCellType type = [NBAddressCell determineAddressCellTypeCountryCode:countryCode];
    switch (type)
    {
        case AC_TYPE_0:
        case AC_TYPE_1:
        case AC_TYPE_3:
        case AC_TYPE_5:
        case AC_TYPE_6:
        case AC_TYPE_7:
        case AC_TYPE_8:
        case AC_TYPE_9:
        case AC_TYPE_17:
        case AC_TYPE_18:
        case AC_TYPE_19:
        case AC_TYPE_20:
        case AC_TYPE_22:
        case AC_TYPE_26:
        case AC_TYPE_27:
        case AC_TYPE_28:
        case AC_TYPE_30:
        {
            return 3 * SIZE_CELL_HEIGHT;
            break;
        }
        case AC_TYPE_2:
        case AC_TYPE_4:
        case AC_TYPE_10:
        case AC_TYPE_11:
        case AC_TYPE_12:
        case AC_TYPE_13:
        case AC_TYPE_14:
        case AC_TYPE_15:
        case AC_TYPE_16:
        case AC_TYPE_21:
        case AC_TYPE_23:
        case AC_TYPE_24:
        case AC_TYPE_25:
        case AC_TYPE_29:
        case AC_TYPE_32:
        {
            return 4 * SIZE_CELL_HEIGHT;
            break;
        }
        case AC_TYPE_31:
        case AC_TYPE_33:
        {
            return 5*SIZE_CELL_HEIGHT;
            break;
        }
        default:
        {
            return SIZE_CELL_HEIGHT;
            break;
        }
    }
}

#pragma mark - State transitioning
- (void)willTransitionToState:(UITableViewCellStateMask)state
{
    //Check if we're animating
    BOOL confirmationAnimation = (state & UITableViewCellStateShowingDeleteConfirmationMask) && !isTransitioned;
    BOOL returnAnimation = (state & UITableViewCellStateShowingEditControlMask) && isTransitioned;
    if (confirmationAnimation || returnAnimation)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:ANIMATION_SPEED];
        animationBegun = YES;
    
        if (confirmationAnimation)
        {
            //Half all the horizontal lines
            for (UIView * separator in separators)
            {
                //Handle the horizontal separators
                CGRect sepFrame = separator.frame;
                if (sepFrame.size.width > 1)
                {
                    sepFrame.size.width /= 2;
                }
                //Handle the vertical separators
                else
                {
                    sepFrame.origin.x -= WIDTH_TEXTFIELD / 4;
                }
                
                separator.frame = sepFrame;
            }
            
            //Half all textfields
            for (UITextField * streetField in streetTextfields)
            {
                [self mutateTextfieldFrame:streetField half:YES];
            }
            [self mutateTextfieldFrame:cityTextfield half:YES];
            [self mutateTextfieldFrame:ZIPTextfield half:YES];
            [self mutateTextfieldFrame:stateTextfield half:YES];
            [self mutateTextfieldFrame:countryTextfield half:YES];
            
            //Shift textfields on the right side to the left half a cell
            NSMutableArray * textFieldsToCheck =  [@[cityTextfield, ZIPTextfield, stateTextfield, countryTextfield] mutableCopy];
            for (UITextField * textfield in textFieldsToCheck)
            {
                if (textfield.frame.origin.x > LEFT_X_POS_TEXTFIELD)
                {
                    textfield.frame = CGRectOffset(textfield.frame, - (WIDTH_TEXTFIELD/4), 0);
                }
            }
        }
        else if (returnAnimation)
        {
            //Half all the horizontal lines
            for (UIView * separator in separators)
            {
                //Handle the horizontal separators
                CGRect sepFrame = separator.frame;
                if (sepFrame.size.width > 1)
                {
                    sepFrame.size.width *= 2;
                }
                //Handle the vertical separators
                else
                {
                    sepFrame.origin.x += WIDTH_TEXTFIELD / 4;
                }
                
                separator.frame = sepFrame;
            }
            
            //Restore all textfields
            for (UITextField * streetField in streetTextfields)
            {
                [self mutateTextfieldFrame:streetField half:NO];
            }
            [self mutateTextfieldFrame:cityTextfield half:NO];
            [self mutateTextfieldFrame:ZIPTextfield half:NO];
            [self mutateTextfieldFrame:stateTextfield half:NO];
            [self mutateTextfieldFrame:countryTextfield half:NO];
            
            //Shift textfields on the right side to the left half a cell
            NSMutableArray * textFieldsToCheck =  [@[cityTextfield, ZIPTextfield, stateTextfield, countryTextfield] mutableCopy];
            for (UITextField * textfield in textFieldsToCheck)
            {
                if (textfield.frame.origin.x > LEFT_X_POS_TEXTFIELD)
                {
                    CGRect restoredFrame = textfield.frame;
                    restoredFrame.origin.x = RIGHT_X_POS_TEXTFIELD;
                    textfield.frame = restoredFrame;
                }
                
                //Resign the responder, in case we're editing
                [textfield resignFirstResponder];
            }
        }
    }
    
    //Call the superclass to scale the textfield and flip the boolean
    [super willTransitionToState:state];
}

@end
