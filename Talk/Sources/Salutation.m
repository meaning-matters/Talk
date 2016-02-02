//
//  Salutation.m
//  Talk
//
//  Created by Cornelis van der Bent on 01/02/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "Salutation.h"


@implementation Salutation

- (instancetype)initWithString:(NSString*)string
{
    if (self = [super init])
    {
        if ([string isEqualToString:@"MS"])
        {
            _value = SalutationValueMs;
        }

        if ([string isEqualToString:@"MR"])
        {
            _value = SalutationValueMr;
        }

        if ([string isEqualToString:@"COMPANY"])
        {
            _value = SalutationValueCompany;
        }

        if (_value == 0)
        {
            NSAssert(0, @"Invalid Salutation string: %@.", string);
        }
    }

    return self;
}


- (instancetype)initWithValue:(SalutationValue)value
{
    if (self = [super init])
    {
        _value = value;
    }

    return self;
}


- (NSString*)string
{
    switch (self.value)
    {
        case SalutationValueMs:
        {
            return @"MS";
        }
        case SalutationValueMr:
        {
            return @"MR";
        }
        case SalutationValueCompany:
        {
            return @"COMPANY";
        }
    }
}


- (NSString*)localizedString
{
    return [Salutation localizedStringForValue:self.value];
}


- (BOOL)isPerson
{
    return (self.value == SalutationValueMs || self.value == SalutationValueMr);
}


- (BOOL)isCompany
{
    return (self.value == SalutationValueCompany);
}


+ (NSString*)localizedStringForValue:(SalutationValue)value
{
    switch (value)
    {
        case SalutationValueMs:
        {
            return NSLocalizedStringWithDefaultValue(@"Salutation Miss", nil, [NSBundle mainBundle],
                                                     @"Ms.",
                                                     @"Title for woman (miss), both married or not married.\n"
                                                     @"[One line].");
        }
        case SalutationValueMr:
        {
            return NSLocalizedStringWithDefaultValue(@"Salutation Mister", nil, [NSBundle mainBundle],
                                                     @"Mr.",
                                                     @"Title for man (mister), both married or not married.\n"
                                                     @"[One line].");
        }
        case SalutationValueCompany:
        {
            return NSLocalizedStringWithDefaultValue(@"Salutation Company", nil, [NSBundle mainBundle],
                                                     @"Company",
                                                     @"Title indicating a company (opposed to personal Mr. or Ms.).\n"
                                                     @"[One line].");
        }
    }
}

@end
