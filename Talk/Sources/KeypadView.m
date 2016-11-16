//
//  KeypadView.m
//  Talk
//
//  Created by Cornelis van der Bent on 13/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import "KeypadView.h"
#import "KeypadButton.h"
#import "Common.h"

@interface KeypadView ()
{
    NSTimer*    eraseTimer;
}

@end


@implementation KeypadView

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setUp];
    }
    
    return self;
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setUp];
}


- (void)setUp
{    
    [[NSBundle mainBundle] loadNibNamed:@"KeypadView" owner:self options:nil];
    CGRect frame = self.frame;
    self.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    [self addSubview:self.view];

    self.backgroundColor = [UIColor clearColor];

    for (int tag = 1; tag <= 15; tag++)
    {
        UIButton*   button = (UIButton*)[self.view viewWithTag:tag];

        // Clear XIB title and color; were only there to easy design.
        button.backgroundColor = [UIColor clearColor];
        [button setTitle:@"" forState:UIControlStateNormal];
    }
}


- (void)layoutSubviews
{
    [super layoutSubviews];

    // Check requirement that height is fivefold.
    // assert((int)self.frame.size.height % 5 == 0);

    CGFloat keyHeight = self.frame.size.height / 5;

    for (int tag = 1; tag <= 15; tag++)
    {
        UIView* view = [self.view viewWithTag:tag];

        [Common setHeight:keyHeight              ofView:view];
        [Common setY:((tag - 1) / 3) * keyHeight ofView:view];
    }
}


#pragma mark - UI Actions

- (IBAction)digitKeyPressAction:(id)sender
{
    KeypadKey   key = 0;

    key = (sender == self.key1Button)    ? KeypadKey1    : key;
    key = (sender == self.key2Button)    ? KeypadKey2    : key;
    key = (sender == self.key3Button)    ? KeypadKey3    : key;
    key = (sender == self.key4Button)    ? KeypadKey4    : key;
    key = (sender == self.key5Button)    ? KeypadKey5    : key;
    key = (sender == self.key6Button)    ? KeypadKey6    : key;
    key = (sender == self.key7Button)    ? KeypadKey7    : key;
    key = (sender == self.key8Button)    ? KeypadKey8    : key;
    key = (sender == self.key9Button)    ? KeypadKey9    : key;
    key = (sender == self.keyStarButton) ? KeypadKeyStar : key;
    key = (sender == self.key0Button)    ? KeypadKey0    : key;
    key = (sender == self.keyHashButton) ? KeypadKeyHash : key;

    // The key buttons were tagged in the XIB.
    for (int tag = 1; tag <= 12; tag++)
    {        
        if (tag != [sender tag])
        {
            ((UIButton*)[self.view viewWithTag:tag]).userInteractionEnabled = NO;
        }
    }

    [self.delegate keypadView:self pressedDigitKey:key];
}


- (IBAction)digitKeyReleaseAction:(id)sender
{
    for (int tag = 1; tag <= 12; tag++)
    {
        ((UIButton*)[self.view viewWithTag:tag]).userInteractionEnabled = YES;
    }
}


- (IBAction)key0LongPressAction:(id)sender
{
    UIGestureRecognizer*    recognizer = sender;

    switch ([recognizer state])
    {
        case UIGestureRecognizerStateBegan:
        {
            [self.delegate keypadViewPressedEraseKey:self];
            [self.delegate keypadView:self pressedDigitKey:KeypadKeyPlus];
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            // Once the gesture recognizer kicked in, digitKeyReleaseAction won't
            // be called anymore.  So we need to enable button here.
            [self digitKeyReleaseAction:nil];
            break;
        }
        default:
        {
            break;
        }
    }
}


- (IBAction)keyOptionPressAction:(id)sender
{
    [self.delegate keypadViewPressedOptionKey:self];
}


- (IBAction)keyCallPressAction:(id)sender
{
    [self.delegate keypadViewPressedCallKey:self];
}


- (IBAction)keyEraseLongPressAction:(id)sender
{
    UIGestureRecognizer* recognizer = sender;

    switch ([recognizer state])
    {
        case UIGestureRecognizerStateBegan:
        {
            eraseTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                          target:self.delegate
                                                        selector:@selector(keypadViewPressedEraseKey:)
                                                        userInfo:self
                                                         repeats:YES];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            [eraseTimer invalidate];
            eraseTimer = nil;
            break;
        }
        default:
        {
            break;
        }
    }
}


- (IBAction)keyEraseReleaseAction:(id)sender
{
    // The key release is consumed be the gesture recognizer.  So when we get
    // here it's certain that the repeat timer was not started yet; and we send
    // a single erase.
    [self.delegate keypadViewPressedEraseKey:self];
}

@end
