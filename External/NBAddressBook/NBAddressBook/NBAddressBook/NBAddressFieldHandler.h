//
//  NBAddressFieldHandler.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/27/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NBAddressFieldHandler <NSObject>
- (void)addressTextfieldMutated:(UITextField*)textField inCell:(id)cell;
- (void)streetTextfieldEditEnded:(UITextField*)textField inCell:(id)cell;
@end
