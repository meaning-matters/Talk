//
//  UILabel+CustomSytemFont.m
//  Talk
//
//  Created by Cornelis van der Bent on 19/01/2018.
//  Copyright © 2018 NumberBay Ltd. All rights reserved.
//

#import "UILabel+CustomSytemFont.h"

@implementation UILabel (CustomSytemFont)

- (void)setSubstituteFontName:(NSString*)name UI_APPEARANCE_SELECTOR
{
    self.font = [UIFont fontWithName:name size:self.font.pointSize];
}

@end
