//
//  AddressData.m
//  Talk
//
//  Created by Cornelis van der Bent on 18/11/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "AddressData.h"
#import "NumberData.h"


@implementation AddressData

// Mandatory.
@dynamic salutation;

// Optional.
@dynamic addressId;
@dynamic firstName;
@dynamic lastName;
@dynamic companyName;
@dynamic companyDescription;
@dynamic street;
@dynamic buildingNumber;
@dynamic buildingLetter;
@dynamic city;
@dynamic postcode;
@dynamic isoCountryCode;
@dynamic proofimage;
@dynamic idType;
@dynamic idNumber;
@dynamic fiscalIdCode;
@dynamic streetCode;
@dynamic municipalityCode;

// Relationship.
@dynamic numbers;

@end
