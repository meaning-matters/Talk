//
//  SoundWaveView.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/07/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "SoundWaveView.h"
#import "Skinning.h"

#define LINE_WIDTH 3.0


@interface SoundWaveView ()

@property (nonatomic, assign) BOOL nextEnabled;

@end


@implementation SoundWaveView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor clearColor];
        self.alpha           = 0.0;
    }

    return self;
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    UIBezierPath* path;

    CGFloat radius = self.bounds.size.height / 2.0;

    switch (self.direction)
    {
        case SoundWaveRight:
        {
            CGFloat x = self.bounds.size.width - radius - (LINE_WIDTH / 2.0);
            path      = [UIBezierPath bezierPathWithArcCenter:CGPointMake(x, radius)
                                                       radius:radius
                                                   startAngle:-M_PI_4
                                                     endAngle:+M_PI_4
                                                    clockwise:YES];
            break;
        }
        case SoundWaveLeft:
        {
            CGFloat x = radius + (LINE_WIDTH / 2.0);
            path      = [UIBezierPath bezierPathWithArcCenter:CGPointMake(x, radius)
                                                       radius:radius
                                                   startAngle:-M_PI_4 + M_PI
                                                     endAngle:+M_PI_4 + M_PI
                                                    clockwise:YES];
            break;
        }
    }

    [[UIColor clearColor] setFill];
    [path fill];
    [[Skinning tintColor] setStroke];
    path.lineWidth    = LINE_WIDTH;
    path.lineCapStyle = kCGLineCapRound;
    [path stroke];
}


- (void)startNextWithColor:(UIColor*)color
{
    self.nextEnabled = YES;

    [UIView animateWithDuration:(1.0 / 16) animations:^
    {
        self.alpha = 1.0;
    }
                     completion:^(BOOL finished)
    {
        if (self.nextEnabled == NO)
        {
            return;
        }

        [self.next startNextWithColor:color];

        [UIView animateWithDuration:0.4 animations:^
        {
            self.alpha = 0.0;
        }];
    }];
}


- (void)stop
{
    self.nextEnabled = NO;

    [self.layer removeAllAnimations];
    
    self.alpha = 0.0;   // This stops the animation.
}

@end
