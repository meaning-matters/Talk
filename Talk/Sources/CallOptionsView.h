//
//  CallOptionsView.h
//  Talk
//
//  Created by Cornelis van der Bent on 29/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KeypadKey.h"
#import "CallOptionButton.h"


@class CallOptionsView;

@protocol CallOptionsViewDelegate <NSObject>

- (void)callOptionsViewPressedMuteKey:(CallOptionsView*)optionsView;

- (void)callOptionsViewPressedKeypadKey:(CallOptionsView*)optionsView;

- (void)callOptionsViewPressedSpeakerKey:(CallOptionsView*)optionsView;

- (void)callOptionsViewPressedAddKey:(CallOptionsView*)optionsView;

- (void)callOptionsViewPressedHoldKey:(CallOptionsView*)optionsView;

- (void)callOptionsViewPressedGroupsKey:(CallOptionsView*)optionsView;

@end


@interface CallOptionsView : UIView

@property (nonatomic, strong) IBOutlet UIView*              view;
@property (nonatomic, strong) IBOutlet CallOptionButton*    muteButton;
@property (nonatomic, strong) IBOutlet CallOptionButton*    keypadButton;
@property (nonatomic, strong) IBOutlet CallOptionButton*    speakerButton;
@property (nonatomic, strong) IBOutlet CallOptionButton*    addButton;
@property (nonatomic, strong) IBOutlet CallOptionButton*    holdButton;
@property (nonatomic, strong) IBOutlet CallOptionButton*    groupsButton;

@property (nonatomic, assign) BOOL                          onMute;
@property (nonatomic, assign) BOOL                          onSpeaker;
@property (nonatomic, assign) BOOL                          onHold;

@property (nonatomic, assign) id<CallOptionsViewDelegate>   delegate;


- (IBAction)muteAction:(id)sender;

- (IBAction)keypadAction:(id)sender;

- (IBAction)speakerAction:(id)sender;

- (IBAction)addAction:(id)sender;

- (IBAction)holdAction:(id)sender;

- (IBAction)groupsAction:(id)sender;

@end
