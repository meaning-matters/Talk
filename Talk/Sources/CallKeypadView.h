//
//  CallKeypadView.h
//  Talk
//
//  Created by Cornelis van der Bent on 29/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KeypadKey.h"
#import "CallKeypadButton.h"


@class CallKeypadView;

@protocol CallKeypadViewDelegate <NSObject>

- (void)callKeypadView:(CallKeypadView*)keypadView pressedDigitKey:(KeypadKey)key;

@end


@interface CallKeypadView : UIView

@property (nonatomic, strong) IBOutlet UIView*              view;
@property (nonatomic, strong) IBOutlet CallKeypadButton*   key1Button;
@property (nonatomic, strong) IBOutlet CallKeypadButton*    key2Button;
@property (nonatomic, strong) IBOutlet CallKeypadButton*    key3Button;
@property (nonatomic, strong) IBOutlet CallKeypadButton*    key4Button;
@property (nonatomic, strong) IBOutlet CallKeypadButton*    key5Button;
@property (nonatomic, strong) IBOutlet CallKeypadButton*    key6Button;
@property (nonatomic, strong) IBOutlet CallKeypadButton*    key7Button;
@property (nonatomic, strong) IBOutlet CallKeypadButton*    key8Button;
@property (nonatomic, strong) IBOutlet CallKeypadButton*    key9Button;
@property (nonatomic, strong) IBOutlet CallKeypadButton*    keyStarButton;
@property (nonatomic, strong) IBOutlet CallKeypadButton*    key0Button;         // '0' or '+'
@property (nonatomic, strong) IBOutlet CallKeypadButton*    keyHashButton;

@property (nonatomic, assign) id<CallKeypadViewDelegate>    delegate;


- (IBAction)keyPressAction:(id)sender;

- (IBAction)keyReleaseAction:(id)sender;

@end
