//
//  SignalDotView.m
//  Talk
//
//  Created by Cornelis van der Bent on 29/11/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "SignalDotView.h"


@interface SignalDotView ()

@property (nonatomic, weak) IBOutlet SignalDotView* next;
@property (nonatomic, weak) IBOutlet SignalDotView* previous;

@property (nonatomic, assign)        BOOL           nextEnabled;
@property (nonatomic, assign)        BOOL           previousEnabled;

@property (nonatomic, strong)        UIColor*       defaultColor;

@end


@implementation SignalDotView

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.defaultColor = [UIColor colorWithWhite:0.3 alpha:0.7];

    self.layer.cornerRadius = self.bounds.size.width / 2.0;

    self.backgroundColor = self.defaultColor;
}


- (void)startNextWithColor:(UIColor*)color
{
    self.nextEnabled = YES;

    [UIView animateWithDuration:(1.0 / 8) animations:^
    {
        self.backgroundColor = color;
    }
                     completion:^(BOOL finished)
    {
        if (self.nextEnabled == NO)
        {
            return;
        }

        self.delegate ? [self.delegate signalDotDidStart:self] : 0;

        [self.next startNextWithColor:color];

        [UIView animateWithDuration:0.3 animations:^
        {
            self.backgroundColor = self.defaultColor;
        }];
    }];
}


- (void)startPreviousWithColor:(UIColor*)color
{
    self.previousEnabled = YES;

    [UIView animateWithDuration:(1.0 / 8) animations:^
    {
         self.backgroundColor = color;
    }
                     completion:^(BOOL finished)
    {
        if (self.previousEnabled == NO)
        {
            return;
        }

        [self.previous startPreviousWithColor:color];

        [UIView animateWithDuration:0.3 animations:^
        {
            self.backgroundColor = self.defaultColor;
        }];
    }];
}


- (void)stop
{
    self.nextEnabled     = NO;
    self.previousEnabled = NO;

    [self.layer removeAllAnimations];

    self.backgroundColor = self.defaultColor;   // This stops the animation.
}

@end
