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

// The delegate is expected to asynchronously set mute, speaker and hold, after
// having been informed by the corresponding delegate method.  In the mean time
// CallOptionsView will flash the corresponding button, while waiting for the
// delegate to set the final state.  During this wait interval no new call to the
// delegate method will be made.
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
