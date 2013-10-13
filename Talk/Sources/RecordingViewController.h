//
//  RecordingViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 19/04/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "RecordingData.h"


@interface RecordingViewController : UITableViewController <UITextFieldDelegate, UIGestureRecognizerDelegate,
                                                            AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (nonatomic, weak) IBOutlet UILabel*               timeLabel;
@property (nonatomic, weak) IBOutlet UIProgressView*        meterProgressView;
@property (nonatomic, weak) IBOutlet UISlider*              timeSlider;
@property (nonatomic, weak) IBOutlet UIButton*              reverseButton;
@property (nonatomic, weak) IBOutlet UIButton*              recordButton;
@property (nonatomic, weak) IBOutlet UIButton*              stopButton;
@property (nonatomic, weak) IBOutlet UIButton*              playButton;
@property (nonatomic, weak) IBOutlet UIButton*              pauseButton;
@property (nonatomic, weak) IBOutlet UIButton*              continueButton; // Continue recording.
@property (nonatomic, weak) IBOutlet UIButton*              forwardButton;

@property (nonatomic, strong) RecordingData*                recording;


- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController*)resultsController
                                       recording:(RecordingData*)recording;

- (IBAction)timeSliderDownAction:(id)sender;
- (IBAction)timeSliderUpAction:(id)sender;
- (IBAction)reverseButtonDownAction:(id)sender;
- (IBAction)reverseButtonUpAction:(id)sender;
- (IBAction)recordButtonAction:(id)sender;
- (IBAction)stopButtonAction:(id)sender;
- (IBAction)playButtonAction:(id)sender;
- (IBAction)pauseButtonAction:(id)sender;
- (IBAction)continueButtonAction:(id)sender;
- (IBAction)forwardButtonDownAction:(id)sender;
- (IBAction)forwardButtonUpAction:(id)sender;

@end
