//
//  TestRandomViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/29/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "TestRandomViewController.h"
#import "NBRecentContactEntry.h"
#import "NBAppDelegate.h"

@implementation TestRandomViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    //Create a textfield where the number can be inputted
    numberTextfield = [[UITextField alloc]initWithFrame:CGRectMake(0, 100, 200, 30)];
    [numberTextfield setTextAlignment:NSTextAlignmentCenter];
    [numberTextfield setPlaceholder:@"Enter a phone number"];
    [numberTextfield setBackgroundColor:[UIColor whiteColor]];
    [numberTextfield setClearButtonMode:UITextFieldViewModeAlways];
    [numberTextfield setDelegate:self];
    CGPoint textCenter = numberTextfield.center;
    textCenter.x = self.view.center.x;
    numberTextfield.center = textCenter;
    [numberTextfield setBorderStyle:UITextBorderStyleBezel];
    [self.view addSubview:numberTextfield];
    
    //Create a switch indicating if it's outgoing or incoming    
    incomingSwitch = [[UISwitch alloc]initWithFrame:CGRectMake(0, 200, 200, 20)];
    CGPoint switchCenter = incomingSwitch.center;
    switchCenter.x = self.view.center.x + 50;
    incomingSwitch.center = switchCenter;
    [self.view addSubview:incomingSwitch];
    
    //Add the label
    UILabel * outgoingLabel = [[UILabel alloc]initWithFrame:incomingSwitch.frame];
    [outgoingLabel setTextColor:[UIColor whiteColor]];
    [outgoingLabel setBackgroundColor:[UIColor clearColor]];
    [outgoingLabel setFont:[UIFont boldSystemFontOfSize:14]];
    [outgoingLabel setText:@"Outgoing?"];
    CGPoint labelCenter = outgoingLabel.center;
    labelCenter.x -= 100;
    outgoingLabel.center = labelCenter;
    [self.view addSubview:outgoingLabel];
    
    //Create a call button
    callButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [callButton setFrame:CGRectMake(0, 300, 200, 30)];
    CGPoint buttonCenter = callButton.center;
    buttonCenter.x = self.view.center.x;
    callButton.center = buttonCenter;
    [callButton setTitle:@"Call" forState:UIControlStateNormal];
    [callButton addTarget:self action:@selector(callPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:callButton];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [numberTextfield setText:[NSString stringWithFormat:@"%d", arc4random() % 999999999]];    
}

-(void)callPressed
{
    if( [numberTextfield.text length] > 0 )
    {
        //Create random entries
        NSManagedObjectContext * context = [(NBAppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext];
        NBRecentContactEntry * recentContactEntry = [NSEntityDescription insertNewObjectForEntityForName:@"NBRecentContactEntry" inManagedObjectContext:context];
        [recentContactEntry setNumber:numberTextfield.text];
        [recentContactEntry setStatus:[NSNumber numberWithInt:(arc4random()%4)]];
        
        //Set the date for this entry from within the last 7 days
        [recentContactEntry setDate:[NSDate date]];
        [recentContactEntry setTimeZone:[[NSTimeZone defaultTimeZone] abbreviation]];
        
        //Set the direction
        [recentContactEntry setDirection:[NSNumber numberWithInt:incomingSwitch.isOn ? CallDirectionOutgoing : CallDirectionIncoming]];
        
        //Give it a random duration
        if( [recentContactEntry.status intValue] == CallStatusSuccess)
        {
            [recentContactEntry setDuration:[NSNumber numberWithInteger:(arc4random()%60)+1]];
        }

        [context save:nil];
    }
    
    [self.view endEditing:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    return YES;
}

@end
