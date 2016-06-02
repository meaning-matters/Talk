//
//  RecordingViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 19/04/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "RecordingViewController.h"
#import "RecordingControlsCell.h"
#import "Common.h"
#import "NSTimer+Blocks.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "DataManager.h"
#import "WebClient.h"
#import "BlockActionSheet.h"
#import "Settings.h"


//### TODO save recording to RecordingData.audio instead of on disk!!!

typedef enum
{
    TableSectionName         = 1UL << 0, // User-given name.
    TableSectionControls     = 1UL << 1,
    TableSectionDestinations = 1UL << 2,
} TableSections;


@interface RecordingViewController ()
{
    TableSections          sections;
    BOOL                   isNew;
    BOOL                   isForwarding;
    BOOL                   isReversing;
    BOOL                   isSliding;
    BOOL                   isPausedRecording;
    BOOL                   isPausedPlaying;
    float                  duration;
    BOOL                   tappedSave;

    AVAudioRecorder*       audioRecorder;
    AVAudioPlayer*         audioPlayer;
    NSTimer*               sliderTimer;
    NSTimer*               meteringTimer;

    RecordingControlsCell* controlsCell;

    NSMutableArray*        meterProgressViewsArray;

    id                     willResignActiveObserver;
    BOOL                   isDeleting;
}

@property (nonatomic, strong) NSURL* temporaryUrl;
@property (nonatomic, assign) BOOL   hasRecorded;

@end


//### Use DataManager!
@implementation RecordingViewController

- (instancetype)initWithRecording:(RecordingData*)recording
             managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super initWithManagedObjectContext:managedObjectContext])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"RecordingView ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Recording",
                                                       @"Title of app screen with details of an audio recording\n"
                                                       @"[1 line larger font].");

        self.name                 = recording.name;
        self.recording            = recording;
        self.managedObjectContext = managedObjectContext;
        isNew                     = (recording == nil);

        sections |= TableSectionName;
        sections |= TableSectionControls;
        sections |= (self.recording.destinations.count > 0) ? TableSectionDestinations : 0;

        // Select initial audio route.
        NSError* error = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        if (error != nil)
        {
            NBLog(@"//### Failed to set audio-session category: %@", error.localizedDescription);
        }
        audioRouteChangeListener(NULL, kAudioSessionProperty_AudioRouteChange, 0, NULL);

        NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
        willResignActiveObserver = [center addObserverForName:UIApplicationWillResignActiveNotification
                                                       object:nil
                                                        queue:[NSOperationQueue mainQueue]
                                                   usingBlock:^(NSNotification* note)
        {
            [self pauseButtonAction:nil];
        }];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.temporaryUrl      = [NSURL fileURLWithPath:[Common pathForTemporaryFileWithExtension:@"m4a"]];
    NSDictionary* settings = @{ AVSampleRateKey          : @(16000.0),
                                AVNumberOfChannelsKey    : @(1),
                                AVFormatIDKey            : @(kAudioFormatMPEG4AAC) };
    NSError*      error;

    audioRecorder = [[AVAudioRecorder alloc] initWithURL:self.temporaryUrl settings:settings error:&error];
    [audioRecorder prepareToRecord];
    if (error == nil)
    {
        audioRecorder.meteringEnabled = YES;
        audioRecorder.delegate = self;
    }
    else
    {
        //### Check if user allowed use of microphone.
        //### Add microphone to device properties in .plist.
        NBLog(@"//### Failed to create audio recorder: %@", error.localizedDescription);
    }

    if (isNew)
    {
        // Create a new managed object context for the new recording; set its parent to the fetched results controller's context.
        NSManagedObjectContext* managedObjectContext;
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [managedObjectContext setParentContext:self.managedObjectContext];
        self.managedObjectContext = managedObjectContext;

        self.recording = [NSEntityDescription insertNewObjectForEntityForName:@"Recording"
                                                       inManagedObjectContext:self.managedObjectContext];
    }
    else
    {
        NSError*  error;
        NSString* path = [Common audioPathForFileName:[NSString stringWithFormat:@"%@.m4a", self.recording.uuid]];
        NSURL*    url  = [NSURL fileURLWithPath:path];
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        if (error == nil)
        {
            audioPlayer.delegate = self;
        }
        else
        {
            NBLog(@"//### Failed to create audio player: %@", error.localizedDescription);
        }

        [audioPlayer prepareToPlay];
        duration = audioPlayer.duration;
    }

    if (isNew)
    {
        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancelAction)];
        self.navigationItem.leftBarButtonItem = buttonItem;

        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                   target:self
                                                                   action:@selector(createAction)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }
    else
    {
        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                   target:self
                                                                   action:@selector(deleteAction)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }

    [self updateRightBarButtonItem];

    NSArray* topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"RecordingControlsCell" owner:self options:nil];
    controlsCell = [topLevelObjects objectAtIndex:0];

    self.meterProgressView.progress = 0;
    self.timeSlider.value = 0;

   // if (isNew)
    {
        meterProgressViewsArray = [NSMutableArray array];
        self.meterProgressView.progressTintColor = [UIColor greenColor];
        [meterProgressViewsArray addObject:self.meterProgressView];
        CGRect  frame = self.meterProgressView.frame;
        for (int n = 1; n < 26; n++)
        {
            frame.origin.x += frame.size.width;
            UIProgressView* progressView = [[UIProgressView alloc] initWithFrame:frame];
            [meterProgressViewsArray addObject:progressView];
            [controlsCell.contentView addSubview:progressView];

            if ((n / 25.0f) < 0.25f)
            {
                progressView.progressTintColor = [UIColor greenColor];
            }
            else if ((n / 25.0f) < 0.8)
            {
                progressView.progressTintColor = [UIColor yellowColor];
            }
            else
            {
                progressView.progressTintColor = [UIColor redColor];
            }
        }
    }

    [self updateControls];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

  //  [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];

    OSStatus result = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange,
                                                      audioRouteChangeListener,
                                                      (__bridge void*)self);
    if (result != 0)
    {
        NBLog(@"//### Failed to set AudioRouteChange listener: %@", [Common stringWithOsStatus:result]);
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // Remove property listener because it interferes during a call.
    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange,
                                                   audioRouteChangeListener,
                                                   (__bridge void*)self);

    if ([self.navigationController.viewControllers indexOfObject:self] != NSNotFound)   // May not be future proof.
    {
        //###### Always do this and ...
        if (audioRecorder.isRecording || audioPlayer.isPlaying)
        {
            [self pauseButtonAction:nil];
        }
    }
    else
    {
        //###### move this to dealloc???

        // We're being popped, because self is no longer in the navigation stack.
        [audioRecorder stop];
        [audioPlayer stop];

        [[NSNotificationCenter defaultCenter] removeObserver:willResignActiveObserver];

        if (isNew && tappedSave == NO && duration > 0)
        {
            NSError*    error;
            [[NSFileManager defaultManager] removeItemAtURL:audioRecorder.url error:&error];
            if (error != nil)
            {
                NBLog(@"//### Failed to remove unused audio file: %@", error.localizedDescription);
            }
        }
    }
}


#pragma mark - TableView Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger   numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionName:
        {
            numberOfRows = 1;
            break;
        }
        case TableSectionControls:
        {
            numberOfRows = 1;
            break;
        }
        case TableSectionDestinations:
        {
            numberOfRows = self.recording.destinations.count;
            break;
        }
    }

    return numberOfRows;
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    CGFloat height;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
        {
            height = 44;
            break;
        }
        case TableSectionControls:
        {
            height = 150;
            break;
        }
        case TableSectionDestinations:
        {
            height = 44;
            break;
        }
    }

    return height;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString*   title = nil;

    if (self.showFootnotes == NO)
    {
        return nil;
    }

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionName:
        {
            if (isNew)
            {
                title = [Strings nameFooterString];
            }
            
            break;
        }
        case TableSectionControls:
        {
            if (isNew)
            {
                title = NSLocalizedStringWithDefaultValue(@"RecordingView:Controls SectionFooter", nil,
                                                          [NSBundle mainBundle],
                                                          @"After you have saved the recording, it can not be "
                                                          @"changed afterwards.",
                                                          @"....");
            }
            
            break;
        }
    }
    
    return title;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
        {
            cell = [self nameCellForRowAtIndexPath:indexPath];
            break;
        }
        case TableSectionControls:
        {
            cell = [self controlsCellForIndexPath:indexPath];
            break;
        }
        case TableSectionDestinations:
        {
            break;
        }
    }
    
    return cell;
}


- (UITableViewCell*)controlsCellForIndexPath:(NSIndexPath*)indexPath
{
    return controlsCell;
}


#pragma mark - Actions

- (void)createAction
{
    self.recording.name = self.name;
    self.navigationItem.rightBarButtonItem.enabled = NO;

    NSData* data = [NSData dataWithContentsOfURL:self.temporaryUrl];
    [[WebClient sharedClient] createAudioWithData:data
                                             name:self.name
                                            reply:^(NSError *error, NSString *uuid)
    {
        if (error == nil)
        {
            self.recording.uuid = uuid;

            NSString* path = [Common audioPathForFileName:[NSString stringWithFormat:@"%@.m4a", uuid]];
            [Common moveFileFromPath:[self.temporaryUrl path] toPath:path];


            NSURL*    url  = [NSURL URLWithString:path];
            audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];


            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
        }
        else
        {
            [self showSaveError:error];
        }
    }];

    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)saveAction
{
    NSData* data = nil;

    if ([self.name isEqualToString:self.recording.name] == YES || self.hasRecorded == NO)
    {
        // Nothing has changed.
        return;
    }

    if (self.hasRecorded)
    {
        NSString* path = [Common audioPathForFileName:[NSString stringWithFormat:@"%@.m4a", self.recording.uuid]];
        data           = [NSData dataWithContentsOfFile:path];
    }

    [[WebClient sharedClient] updateAudioForUuid:self.recording.uuid
                                            data:data
                                            name:self.name
                                           reply:^(NSError *error)
    {
        if (error == nil)
        {
            self.recording.name = self.name;

            NSString* path = [Common audioPathForFileName:[NSString stringWithFormat:@"%@.m4a", self.recording.uuid]];
            [Common moveFileFromPath:[self.temporaryUrl absoluteString] toPath:path];

            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
        }
        else
        {
            self.name = self.recording.name;
            [self showSaveError:error];
        }
    }];
}


- (void)deleteAction
{
    if (self.recording.destinations.count == 0)
    {
        NSString* buttonTitle = NSLocalizedStringWithDefaultValue(@"RecordingView DeleteTitle", nil,
                                                                  [NSBundle mainBundle], @"Delete Recording",
                                                                  @"...\n"
                                                                  @"[1/3 line small font].");

        [BlockActionSheet showActionSheetWithTitle:nil
                                        completion:^(BOOL cancelled, BOOL destruct, NSInteger buttonIndex)
        {
            if (destruct == YES)
            {
                isDeleting = YES;

                [self.recording deleteWithCompletion:^(BOOL succeeded)
                 {
                     if (succeeded)
                     {
                         [self.navigationController popViewControllerAnimated:YES];
                     }
                     else
                     {
                         isDeleting = NO;
                     }
                 }];
            }
        }
                                 cancelButtonTitle:[Strings cancelString]
                            destructiveButtonTitle:buttonTitle
                                 otherButtonTitles:nil];
    }
    else
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"RecordingView CantDeleteTitle", nil, [NSBundle mainBundle],
                                                    @"Can't Delete Recording",
                                                    @"...\n"
                                                    @"[1/3 line small font].");
        message = NSLocalizedStringWithDefaultValue(@"RecordingView CantDeleteMessage", nil, [NSBundle mainBundle],
                                                    @"This Recording can't be deleted because it's used by one "
                                                    @"or more Destinations.",
                                                    @"Table footer that app can't be deleted\n"
                                                    @"[1 line larger font].");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
}


- (void)saveAction_
{
    self.recording.name = self.name;

    //### Send to server (look at DestinationViewController's saveAction.

    [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];

    tappedSave = YES; // Prevents removal of file in viewWillDisappear.
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)showSaveError:(NSError*)error
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"Recording SaveErrorTitle", nil, [NSBundle mainBundle],
                                                @"Failed To Save",
                                                @"....\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"Recording SaveErroMessage", nil, [NSBundle mainBundle],
                                                @"Failed to save this Recording: %@",
                                                @"...\n"
                                                @"[iOS alert message size]");
    [BlockAlertView showAlertViewWithTitle:title
                                   message:[NSString stringWithFormat:message, [error localizedDescription]]
                                completion:nil
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


- (IBAction)timeSliderDownAction:(id)sender
{
    isSliding = YES;
    [self updateControls];
}


- (IBAction)timeSliderUpAction:(id)sender
{
    isSliding = NO;
    [self updateControls];
}


- (IBAction)reverseButtonDownAction:(id)sender
{
    isReversing = YES;
    [self updateSlider];
    [self updateControls];
}


- (IBAction)reverseButtonUpAction:(id)sender
{
    isReversing = NO;
    [self updateControls];
}


- (IBAction)recordButtonAction:(id)sender
{
    if (self.hasRecorded)
    {
        NSString* title;
        NSString* message;
        NSString* button;

        title   = NSLocalizedStringWithDefaultValue(@"RecordingView OverwriteTitle", nil,
                                                    [NSBundle mainBundle], @"Discard Recording",
                                                    @"Alert title asking if existing audio recording can be overwritten\n"
                                                    @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"RecordingView OverwriteMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"Do you want to overwrite the existing recording you just made?\n"
                                                    @"The new recoding starts immediately after you confirm.",
                                                    @"Alert message explaing that existing recording will be overwritten\n"
                                                    @"[iOS alert message size]");

        button  = NSLocalizedStringWithDefaultValue(@"RecordingView RecordButtonTitle", nil,
                                                    [NSBundle mainBundle], @"Record",
                                                    @"Button title for starting an audio recording\n"
                                                    @"[iOS alert button size 1/2 alert width].");

        [BlockAlertView showAlertViewWithTitle:title message:message completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            if (buttonIndex == 1)
            {
                [self startRecording];
            }
        }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:button, nil];
    }
    else
    {
        [self startRecording];
    }
}


- (IBAction)stopButtonAction:(id)sender
{
    if (audioRecorder.isRecording || isPausedRecording)
    {
        [self stopRecording];
    }

    if (audioPlayer.isPlaying || isPausedPlaying)
    {
        [self stopPlaying];
    }
}


- (IBAction)playButtonAction:(id)sender
{
    if (isPausedPlaying == NO && isNew)
    {
        NSError* error;
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioRecorder.url error:&error];
        if (error == nil)
        {
            audioPlayer.delegate = self;
        }
        else
        {
            NBLog(@"//### Failed to create audio player: %@", error.localizedDescription);
        }
    }

    sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^
    {
        [self updateSlider];
    }];

    if ([audioPlayer play] == NO)
    {
        NBLog(@"//### Failed to start playing");
    }

    isPausedPlaying = NO;

    // For some reason the durations are not constant.
    self.timeSlider.maximumValue = MIN(duration, audioPlayer.duration) - 0.15;

    [self updateControls];
}


- (IBAction)pauseButtonAction:(id)sender
{
    if (audioRecorder.isRecording)
    {
        [self pauseRecording];
    }

    if (audioPlayer.isPlaying)
    {
        [self pausePlaying];
    }
}


- (IBAction)continueButtonAction:(id)sender
{
    if ([audioRecorder record] == NO)
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"RecordingView CantContinueTitle", nil,
                                                    [NSBundle mainBundle], @"Recording Stopped",
                                                    @"A recording could not be continued after a pause\n"
                                                    @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"RecordingView OverwriteMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"This recording could not be continued after the pause, and "
                                                    @"was stopped.",
                                                    @"Alert message: audio recording stopped due to problem.\n"
                                                    @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }

    isPausedRecording = NO;

    meteringTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^
    {
        [self updateMeter];
    }];

    [self updateControls];
}


- (IBAction)forwardButtonDownAction:(id)sender
{
    isForwarding = YES;
    [self updateSlider];
    [self updateControls];
}


- (IBAction)forwardButtonUpAction:(id)sender
{
    isForwarding = NO;
    [self updateControls];
}


#pragma mark - Recorder Delegate

- (void)audioRecorderBeginInterruption:(AVAudioRecorder*)recorder
{    
    [self pauseRecording];
}


- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder*)recorder error:(NSError*)error
{
    NBLog(@"//### Audio recorder encoding error: %@", error.localizedDescription);
}


- (void)audioRecorderDidFinishRecording:(AVAudioRecorder*)recorder successfully:(BOOL)flag
{
    self.hasRecorded = flag;
    [self updateControls];
}


#pragma mark - Player Delegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag
{
    [sliderTimer invalidate];
    sliderTimer = nil;

    audioPlayer.currentTime = 0.0;
    [self updateSlider];

    [self updateControls];
}


- (void)audioPlayerBeginInterruption:(AVAudioPlayer*)player
{
    [self pausePlaying];
}


- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer*)player error:(NSError*)error
{
    NBLog(@"//### Audio player decoding error: %@", error.localizedDescription);
}


#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch
{
    if ([touch.view isKindOfClass:[UITextField class]] ||
        [touch.view isKindOfClass:[UIButton class]])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}


#pragma mark - TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];

    return YES;
}


- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    self.name = [textField.text stringByReplacingCharactersInRange:range withString:string];

    [self updateRightBarButtonItem];

    return YES;
}


#pragma mark - Helper Methods

- (void)startRecording
{
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    if ([audioRecorder record] == NO)
    {
        NBLog(@"//### Failed to start recording.");

        return;
    }

    meteringTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^
    {
        [self updateMeter];
    }];

    [self updateControls];
}


- (void)pauseRecording
{
    [audioRecorder pause];
    isPausedRecording = YES;

    [meteringTimer invalidate];
    meteringTimer = nil;

    [self setMeterLevel:0.0f];

    [self updateControls];
}


- (void)stopRecording
{
    [audioRecorder stop];
    int options = AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation;
    [[AVAudioSession sharedInstance] setActive:NO withOptions:options error:nil];

    isPausedRecording = NO;

    [meteringTimer invalidate];
    meteringTimer = nil;
    
    self.meterProgressView.progress = 0;
    
    [self updateControls];
}


- (void)pausePlaying
{
    [audioPlayer pause];
    isPausedPlaying = YES;

    [sliderTimer invalidate];
    sliderTimer = nil;

    [self updateControls];
}


- (void)stopPlaying
{
    [audioPlayer stop];
    isPausedPlaying = NO;

    [sliderTimer invalidate];
    sliderTimer = nil;

    audioPlayer.currentTime = 0;
    [self updateSlider];

    [self updateControls];
}


- (void)updateMeter
{
    if (audioRecorder.isRecording)
    {
        [audioRecorder updateMeters];

        // Code below is a rework of MeterTable, found in Apple's SpeakHere sample.
        // But where Apple works with double's, I do all calculations in float.
        float   minDecibels = -80.0f;
        float   level;
        float   decibels    = [audioRecorder averagePowerForChannel:0];
        if (decibels < minDecibels)
        {
            level = 0.0f;
        }
        else if (decibels >= 0.0f)
        {
            level = 1.0f;
        }
        else
        {
            float   root            = 2.0f;
            float   minAmp          = powf(10.0f, 0.05f * minDecibels);
            float   inverseAmpRange = 1.0f / (1.0f - minAmp);
            float   amp             = powf(10.0f, 0.05f * decibels);
            float   adjAmp          = (amp - minAmp) * inverseAmpRange;

            level = powf(adjAmp, 1.0f / root);
        }

        [self setMeterLevel:level];

        duration = audioRecorder.currentTime;

#warning Localize these times!
        self.timeLabel.text = [NSString stringWithFormat:@"%ds", (int)duration];
    }
}


- (void)setMeterLevel:(float)level
{
    for (int n = 0; n < meterProgressViewsArray.count; n++)
    {
        UIProgressView* progressView = meterProgressViewsArray[n];
        progressView.progress = (level * meterProgressViewsArray.count > n) ? 1 : 0;
    }
}


- (void)updateSlider
{
    if (audioPlayer.isPlaying)
    {
        if (isReversing)
        {
            NSTimeInterval  currentTime = audioPlayer.currentTime;

            currentTime -= ((duration / 25) + 0.2);
            currentTime = (currentTime < 0.0) ? 0.0 : currentTime;

            audioPlayer.currentTime = currentTime;
        }

        if (isForwarding)
        {
            NSTimeInterval  currentTime = audioPlayer.currentTime;

            currentTime += (duration / 25);
            currentTime = (currentTime > duration) ? duration : currentTime;

            audioPlayer.currentTime = currentTime;
        }

        if (isSliding)
        {
            audioPlayer.currentTime = self.timeSlider.value;
        }

        self.timeLabel.text = [NSString stringWithFormat:@"%ds / %ds",
                               (int)audioPlayer.currentTime, (int)duration];
    }

    self.timeSlider.value = audioPlayer.currentTime;
}


- (void)updateControls
{
    BOOL isPlaying   = audioPlayer.isPlaying;
    BOOL isRecording = audioRecorder.isRecording;
    BOOL canPlay     = (isNew && self.hasRecorded) ||
                       ([audioRecorder.url checkResourceIsReachableAndReturnError:nil] && !isNew);

    // These expressions are negated so that they are about when an UI item is visible (instead of hidden). 
    self.meterProgressView.hidden = !(!canPlay || isRecording || isPausedRecording);
    self.timeSlider.hidden        = !self.meterProgressView.hidden;
    self.recordButton.hidden      = !(!isRecording && !isPausedRecording && !isPlaying && !isPausedPlaying);
    self.stopButton.hidden        = !self.recordButton.hidden;
    self.pauseButton.hidden       = !(isRecording || isPlaying);
    self.continueButton.hidden    = !(isPausedRecording);
    self.playButton.hidden        = (isRecording || isPlaying || isPausedRecording);

    // These expressions are only correct for when the UI item is visible.
    self.timeSlider.enabled       = isPlaying && !isForwarding && !isReversing && !isPausedPlaying;
    self.reverseButton.enabled    = isPlaying && !isForwarding && !isSliding;
    self.stopButton.enabled       = (isRecording || isPausedRecording || isPlaying || isPausedPlaying) &&
                                     !isForwarding && !isReversing && !isSliding;
    self.recordButton.enabled     = !isPlaying;
    self.playButton.enabled       = canPlay;
    self.pauseButton.enabled      = (isRecording || isPlaying) && !isForwarding && !isReversing && !isSliding;
    self.forwardButton.enabled    = isPlaying && !isReversing && !isSliding;

    [self updateRightBarButtonItem];

    for (int n = 1; n < meterProgressViewsArray.count; n++)
    {
        UIProgressView* progressView = meterProgressViewsArray[n];
        progressView.hidden = self.meterProgressView.hidden;
    }

    if (isPausedRecording)
    {
        self.timeLabel.text = NSLocalizedStringWithDefaultValue(@"RecordingView RecordingPausedLabel", nil,
                                                                [NSBundle mainBundle], @"Recording is paused",
                                                                @"Label saying that recording audio is paused\n"
                                                                @"[1 line].");
    }
    else if (isPausedPlaying)
    {
        self.timeLabel.text = NSLocalizedStringWithDefaultValue(@"RecordingView RecordingPausedLabel", nil,
                                                                [NSBundle mainBundle], @"Playing is paused",
                                                                @"Label saying that playing audio is paused\n"
                                                                @"[1 line].");
    }
    else if (canPlay && !isRecording && !isPlaying)
    {
        self.timeLabel.text = [NSString stringWithFormat:@"%ds", (int)duration];
    }
}


- (void)updateRightBarButtonItem
{
    BOOL hasRecording = ([audioRecorder.url checkResourceIsReachableAndReturnError:nil] == YES);

    self.navigationItem.rightBarButtonItem.enabled = (self.name.length > 0) && ((hasRecording && !isPausedRecording) || !isNew);
}


static void audioRouteChangeListener(
    void*                  inClientData,
    AudioSessionPropertyID inID,
    UInt32                 inDataSize,
    const void*            inData)
{
    if (inID == kAudioSessionProperty_AudioRouteChange)
    {
        CFStringRef newRoute;
        UInt32      size = sizeof(CFStringRef);

        AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute);
        if (newRoute)
        {
            if (CFStringCompare(newRoute, CFSTR("ReceiverAndMicrophone"), (UInt32)NULL) == kCFCompareEqualTo)
            {
                UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
                AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,
                                        sizeof(audioRouteOverride),
                                        &audioRouteOverride);
            }
            else if (CFStringCompare(newRoute, CFSTR("HeadsetInOut"), (UInt32)NULL) == kCFCompareEqualTo)
            {
                UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
                AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,
                                        sizeof(audioRouteOverride),
                                        &audioRouteOverride);
            }
        }
    }
}


#pragma mark - Baseclass Override

- (void)save
{
    if (isNew == NO && isDeleting == NO)
    {
        [self saveAction];
    }
}


- (void)update
{
    [self updateRightBarButtonItem];
}

@end
