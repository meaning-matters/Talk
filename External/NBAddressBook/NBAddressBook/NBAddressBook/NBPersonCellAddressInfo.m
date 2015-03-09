//
//  NBPersonCellAddressInfo.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/18/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBPersonCellAddressInfo.h"

@implementation NBPersonCellAddressInfo

@synthesize streetLines, city, country, ZIP, countryCode, state, isAddButton;

- (instancetype)initWithPlaceholder:(NSString*)placeHolderParam andLabel:(NSString*)labelTitleParam
{
    if (self = [super initWithPlaceholder:placeHolderParam andLabel:labelTitleParam])
    {
        self.streetLines = [NSMutableArray array];
    }
    return self;
}


- (void)setCountryUsingCountryCode
{
    self.country = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:self.countryCode];
}
@end
