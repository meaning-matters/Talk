//
//  ProofTypes.m
//  Talk
//
//  Created by Cornelis van der Bent on 16/12/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "ProofTypes.h"


@interface ProofTypes ()

@property (nonatomic, strong) Salutation*   salutation;

@property (nonatomic, strong) NSDictionary* person;
@property (nonatomic, strong) NSDictionary* company;

@end


@implementation ProofTypes

- (instancetype)initWithPerson:(NSDictionary*)person company:(NSDictionary*)company salutation:(Salutation*)salutation
{
    if (self = [super init])
    {
        self.person     = person;
        self.company    = company;
        self.salutation = salutation;
    }

    return self;
}


- (NSString*)localizedAddressProofsString
{
    NSArray* types = self.salutation.isPerson ? self.person[@"addressProofTypes"]
                                              : self.company[@"addressProofTypes"];
    return [self localizedProofsStringWithTypes:types];
}


- (NSString*)localizedIdentityProofsString
{
    NSArray* types = self.salutation.isPerson ? self.person[@"identityProofTypes"]
                                              : self.company[@"identityProofTypes"];
    return [self localizedProofsStringWithTypes:types];
}


- (NSString*)localizedProofsStringWithTypes:(NSArray*)types
{
    NSMutableArray* strings = [NSMutableArray array];

    if ([types containsObject:@"UTILITY"])
    {
        [strings addObject:NSLocalizedStringWithDefaultValue(@"ProofType Utility", nil, [NSBundle mainBundle],
                                                             @"GAS/ELECTRICITY/... BILL, BANK STATEMENT, or OTHER "
                                                             @"DOCUMENT FROM A LARGE ORGANISATION THAT ONLY YOU "
                                                             @"CAN RECEIVE",
                                                             @"\n"
                                                             @"[One line].")];
    }

    if ([types containsObject:@"COMPANY"])
    {
        [strings addObject:NSLocalizedStringWithDefaultValue(@"ProofType Company", nil, [NSBundle mainBundle],
                                                             @"COMPANY REGISTRATION",
                                                             @"\n"
                                                             @"[One line].")];
    }

    if ([types containsObject:@"PASSPORT"])
    {
        [strings addObject:NSLocalizedStringWithDefaultValue(@"ProofType Passport", nil, [NSBundle mainBundle],
                                                             @"PASSPORT",
                                                             @"\n"
                                                             @"[One line].")];
    }

    if ([types containsObject:@"ID_CARD"])
    {
        [strings addObject:NSLocalizedStringWithDefaultValue(@"ProofType ID Card", nil, [NSBundle mainBundle],
                                                             @"ID CARD",
                                                             @"\n"
                                                             @"[One line].")];
    }

    if (strings.count != types.count)
    {
        NBLog(@"Unknown proof type(s) in: %@.", types);
    }

    return [self stringWithStrings:strings];
}


- (BOOL)requiresAddressProof
{
    return [(self.salutation.isPerson ? self.person[@"addressProofTypes"] : self.company[@"addressProofTypes"]) count] > 0;
}


- (BOOL)requiresIdentityProof
{
    return [(self.salutation.isPerson ? self.person[@"identityProofTypes"] : self.company[@"identityProofTypes"]) count] > 0;
}


#pragma mark - Helpers

- (NSString*)stringWithStrings:(NSArray*)strings
{
    NSString* resultString = nil;

    if (strings.count == 0)
    {
        resultString = @"";
    }
    else
    {
        for (NSString* string in strings)
        {
            if (resultString == nil)
            {
                resultString = string;
            }
            else
            {
                NSString* orString = NSLocalizedString(@"or", @"This 'or' that.");
                resultString = [resultString stringByAppendingFormat:@" %@ %@", orString, string];
            }
        }
    }

    return resultString;
}

@end
