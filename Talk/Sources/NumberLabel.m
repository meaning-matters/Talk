//
//  NumberLabel.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "NumberLabel.h"

@implementation NumberLabel

- (instancetype)initWithCoder:(NSCoder*)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setUp];
    }

    return self;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setUp];
    }

    return self;
}


- (void)setUp
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didHideEditMenu)
                                                 name:UIMenuControllerDidHideMenuNotification
                                               object:nil];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIMenuControllerDidHideMenuNotification
                                                  object:nil];
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(copy:))
    {
        return ([self.text length] > 0);
    }
    else if (self.hasPaste && action == @selector(paste:))
    {
        UIPasteboard*   pasteboard = [UIPasteboard generalPasteboard];

        if (pasteboard.string == nil)
        {
            return NO;
        }
        else
        {
            NSCharacterSet *stringSet = [NSCharacterSet characterSetWithCharactersInString:pasteboard.string];
            NSCharacterSet *allowedSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789+#*()-. \u00a0\t\n\r"];

            return [allowedSet isSupersetOfSet:stringSet];
        }
    }
    else
    {
        return NO;
    }
}


- (void)setText:(NSString*)text
{
    [super setText:text];
    self.highlighted = NO;
}


- (BOOL)canBecomeFirstResponder
{
    return YES;
}


- (BOOL)becomeFirstResponder
{
    if ([super becomeFirstResponder])
    {
        self.highlighted = YES;
        
        return YES;
    }
    else
    {
        return NO;
    }
}


- (void)copy:(id)sender
{
    UIPasteboard*   pasteboard = [UIPasteboard generalPasteboard];
    
    pasteboard.string = self.text;
    
    self.highlighted = NO;
    [self resignFirstResponder];
}


- (void)paste:(id)sender
{
    UIPasteboard*   pasteboard = [UIPasteboard generalPasteboard];
    NSCharacterSet* stripSet   = [NSCharacterSet characterSetWithCharactersInString:@"()-. \u00a0\t\n\r"];
    NSString*       strippedText;

    strippedText = [[pasteboard.string componentsSeparatedByCharactersInSet:stripSet] componentsJoinedByString:@""];
    
    self.text = strippedText;

    [self resignFirstResponder];
    [self.delegate numberLabelChanged:self];
}


- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    if ([self isFirstResponder])
    {
        self.highlighted = NO;
        UIMenuController* menu = [UIMenuController sharedMenuController];
        [menu setMenuVisible:NO animated:YES];
        [menu update];
        [self resignFirstResponder];
    }
    else if ([self becomeFirstResponder])
    {
        UIMenuController* menu = [UIMenuController sharedMenuController];
        if (CGRectIsEmpty(self.menuTargetRect) == YES)
        {
            [menu setTargetRect:self.bounds inView:self];
        }
        else
        {
            [menu setTargetRect:self.menuTargetRect inView:self];
        }
        
        [menu setMenuVisible:YES animated:YES];
    }
}


- (void)didHideEditMenu
{
    self.highlighted = NO;
    [self resignFirstResponder];
}

@end
