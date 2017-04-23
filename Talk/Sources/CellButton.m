//
//  CellButton.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/04/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "CellButton.h"

/// Button that highlights immediately to be used on `UITableViewCell`. See http://stackoverflow.com/a/35479755/1971013
@implementation CellButton

- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    self.highlighted = true;
    [super touchesBegan:touches withEvent:event];
}


- (void)touchesEnded:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    self.highlighted = false;
    [super touchesEnded:touches withEvent:event];
}


- (void)touchesCancelled:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    self.highlighted = false;
    [super touchesCancelled:touches withEvent:event];
}

@end
