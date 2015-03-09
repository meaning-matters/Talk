//
//  NBPersonCellAddressInfo.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/18/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBPersonCellInfo.h"
#import "NBAddressCell.h"

@interface NBPersonCellAddressInfo : NBPersonCellInfo

//Flag to indicate this is an add-button
@property (nonatomic) BOOL isAddButton;

//The number of streets entered into the cell
@property (nonatomic) NSMutableArray * streetLines;

@property (nonatomic) NSString * city;
@property (nonatomic) NSString * country;
@property (nonatomic) NSString * state;
@property (nonatomic) NSString * ZIP;
@property (nonatomic) NSString * countryCode;

- (void)setCountryUsingCountryCode;

@end
