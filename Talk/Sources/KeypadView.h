//
//  KeypadView.h
//  Talk
//
//  Created by Cornelis van der Bent on 13/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KeypadKey.h"


@class KeypadView;

@protocol KeypadViewDelegate <NSObject>

- (void)keypadView:(KeypadView*)keypadView pressedDigitKey:(KeypadKey)key;

- (void)keypadViewPressedOptionKey:(KeypadView*)keypadView;

- (void)keypadViewPressedCallKey:(KeypadView*)keypadView;

- (void)keypadViewPressedEraseKey:(KeypadView*)keypadView;

@end


@interface KeypadView : UIView

@property (nonatomic, strong) IBOutlet UIView*              view;
@property (nonatomic, weak) IBOutlet UIButton*              key1Button;
@property (nonatomic, weak) IBOutlet UIButton*              key2Button;
@property (nonatomic, weak) IBOutlet UIButton*              key3Button;
@property (nonatomic, weak) IBOutlet UIButton*              key4Button;
@property (nonatomic, weak) IBOutlet UIButton*              key5Button;
@property (nonatomic, weak) IBOutlet UIButton*              key6Button;
@property (nonatomic, weak) IBOutlet UIButton*              key7Button;
@property (nonatomic, weak) IBOutlet UIButton*              key8Button;
@property (nonatomic, weak) IBOutlet UIButton*              key9Button;
@property (nonatomic, weak) IBOutlet UIButton*              keyStarButton;
@property (nonatomic, weak) IBOutlet UIButton*              key0Button;         // '0' or '+'
@property (nonatomic, weak) IBOutlet UIButton*              keyHashButton;
@property (nonatomic, weak) IBOutlet UIButton*              keyOptionButton;
@property (nonatomic, weak) IBOutlet UIButton*              keyCallButton;
@property (nonatomic, weak) IBOutlet UIButton*              keyEraseButton;

@property (nonatomic, weak) IBOutlet UIGestureRecognizer*   longPress0Recognizer;
@property (nonatomic, weak) IBOutlet UIGestureRecognizer*   longPressEraseRecognizer;

@property (nonatomic, assign) id<KeypadViewDelegate>        delegate;


- (IBAction)digitKeyPressAction:(id)sender;

- (IBAction)digitKeyReleaseAction:(id)sender;

- (IBAction)key0LongPressAction:(id)sender;

- (IBAction)keyOptionPressAction:(id)sender;

- (IBAction)keyCallPressAction:(id)sender;

- (IBAction)keyEraseLongPressAction:(id)sender;

- (IBAction)keyEraseReleaseAction:(id)sender;

@end
