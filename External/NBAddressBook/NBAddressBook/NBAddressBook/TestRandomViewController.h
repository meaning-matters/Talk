//
//  TestRandomViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/29/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestRandomViewController : UIViewController <UITextFieldDelegate>
{
    UITextField * numberTextfield;
    UIButton * callButton;
    UISwitch * incomingSwitch;
}

@end
