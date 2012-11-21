//
//  KeypadView.h
//  Talk
//
//  Created by Cornelis van der Bent on 13/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    KeypadKey1      = '1',
    KeypadKey2      = '2',
    KeypadKey3      = '3',
    KeypadKey4      = '4',
    KeypadKey5      = '5',
    KeypadKey6      = '6',
    KeypadKey7      = '7',
    KeypadKey8      = '8',
    KeypadKey9      = '9',
    KeypadKeyStar   = '*',
    KeypadKey0      = '0',
    KeypadKeyPlus   = '+',
    KeypadKeyHash   = '#',
    KeypadKeyOption = '?',  // Not used.
    KeypadKeyCall   = 'c',  // Not used.
    KeypadKeyErase  = '<',  // Not used.
} KeypadKey;


@class KeypadView;

@protocol KeypadViewDelegate <NSObject>

- (void)keypadView:(KeypadView*)keypadView pressedDigitKey:(KeypadKey)key;

- (void)keypadViewPressedOptionKey:(KeypadView*)keypadView;

- (void)keypadViewPressedCallKey:(KeypadView*)keypadView;

- (void)keypadViewPressedEraseKey:(KeypadView*)keypadView;

@end


@interface KeypadView : UIView

@property (nonatomic, strong) IBOutlet UIView*              view;
@property (nonatomic, strong) IBOutlet UIButton*            key1Button;
@property (nonatomic, strong) IBOutlet UIButton*            key2Button;
@property (nonatomic, strong) IBOutlet UIButton*            key3Button;
@property (nonatomic, strong) IBOutlet UIButton*            key4Button;
@property (nonatomic, strong) IBOutlet UIButton*            key5Button;
@property (nonatomic, strong) IBOutlet UIButton*            key6Button;
@property (nonatomic, strong) IBOutlet UIButton*            key7Button;
@property (nonatomic, strong) IBOutlet UIButton*            key8Button;
@property (nonatomic, strong) IBOutlet UIButton*            key9Button;
@property (nonatomic, strong) IBOutlet UIButton*            keyStarButton;
@property (nonatomic, strong) IBOutlet UIButton*            key0Button;         // '0' or '+'
@property (nonatomic, strong) IBOutlet UIButton*            keyHashButton;
@property (nonatomic, strong) IBOutlet UIButton*            keyOptionButton;
@property (nonatomic, strong) IBOutlet UIButton*            keyCallButton;
@property (nonatomic, strong) IBOutlet UIButton*            keyEraseButton;

@property (nonatomic, strong) IBOutlet UIGestureRecognizer* longPress0Recognizer;
@property (nonatomic, strong) IBOutlet UIGestureRecognizer* longPressEraseRecognizer;

@property (nonatomic, assign) id<KeypadViewDelegate>        delegate;

- (IBAction)digitKeyPressAction:(id)sender;

- (IBAction)digitKeyReleaseAction:(id)sender;

- (IBAction)key0LongPressAction:(id)sender;

- (IBAction)keyOptionPressAction:(id)sender;

- (IBAction)keyCallPressAction:(id)sender;

- (IBAction)keyEraseLongPressAction:(id)sender;

- (IBAction)keyEraseReleaseAction:(id)sender;

@end
