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


typedef enum
{
    TableSectionName        = 1UL << 0, // User-given name.
    TableSectionControls    = 1UL << 1,
    TableSectionForwardings = 1UL << 2,
} TableSections;


@interface RecordingViewController ()
{
    TableSections           sections;
    BOOL                    isNew;
    BOOL                    isForwarding;
    BOOL                    isReversing;
    BOOL                    isSliding;
    BOOL                    isPausedRecording;
    BOOL                    isPausedPlaying;
    float                   duration;
    BOOL                    tappedSave;

    NSString*               name;

    AVAudioRecorder*        audioRecorder;
    AVAudioPlayer*          audioPlayer;
    NSTimer*                sliderTimer;
    NSTimer*                meteringTimer;

    RecordingControlsCell* controlsCell;

    NSMutableArray*        meterProgressViewsArray;

    id                     willResignActiveObserver;
}

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;


@end


//### Use DataManager!
@implementation RecordingViewController

- (instancetype)initWithRecording:(RecordingData*)recording
             managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    self.recording = recording;
    isNew          = (recording == nil);

    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"RecordingView ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Recording",
                                                       @"Title of app screen with details of an audio recording\n"
                                                       @"[1 line larger font].");

        sections |= TableSectionName;
        sections |= TableSectionControls;
        sections |= (self.recording.forwardings.count > 0) ? TableSectionForwardings : 0;

        // Select initial audio route.
        audioRouteChangeListener(NULL, kAudioSessionProperty_AudioRouteChange, 0, NULL);

        NSNotificationCenter*   center = [NSNotificationCenter defaultCenter];
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

    if (isNew)
    {
        NSString*       uuid = [[NSUUID UUID] UUIDString];
        NSURL*          url  = [Common audioUrl:[NSString stringWithFormat:@"%@.aac", uuid]];
        NSError*        error;
        NSDictionary*   settings = @{ AVEncoderAudioQualityKey : @(AVAudioQualityMedium),
                                      AVNumberOfChannelsKey    : @(1),
                                      AVFormatIDKey            : @(kAudioFormatMPEG4AAC) };

        audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
        if (error == nil)
        {
            audioRecorder.meteringEnabled = YES;
            audioRecorder.delegate = self;
        }
        else
        {
            NBLog(@"//### Failed to create audio recorder: %@", error.localizedDescription);
        }

        // Create a new managed object context for the new recording; set its parent to the fetched results controller's context.
        NSManagedObjectContext* managedObjectContext;
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [managedObjectContext setParentContext:self.managedObjectContext];
        self.managedObjectContext = managedObjectContext;

        self.recording = [NSEntityDescription insertNewObjectForEntityForName:@"Recording"
                                                       inManagedObjectContext:self.managedObjectContext];
        self.recording.uuid      = uuid;
        self.recording.urlString = [url absoluteString];
    }
    else
    {
        NSError*    error;
        NSURL*      url = [NSURL URLWithString:self.recording.urlString];
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

    self.navigationItem.rightBarButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                            target:self
                                                                                            action:@selector(saveAction)];

    NSArray*    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"RecordingControlsCell" owner:self options:nil];
    controlsCell = [topLevelObjects objectAtIndex:0];

    // Let keyboard be hidden when user taps outside text fields.
    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:gestureRecognizer];

    self.meterProgressView.progress = 0;
    self.timeSlider.value = 0;

    if (isNew)
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

    [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];

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
        if (audioRecorder.isRecording || audioPlayer.isPlaying)
        {
            [self pauseButtonAction:nil];
        }
    }
    else
    {
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
            numberOfRows = 1;
            break;

        case TableSectionControls:
            numberOfRows = 1;
            break;

        case TableSectionForwardings:
            numberOfRows = self.recording.forwardings.count;
            break;
    }

    return numberOfRows;
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    CGFloat height;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
            height = 44;
            break;

        case TableSectionControls:
            height = 150;
            break;

        case TableSectionForwardings:
            height = 44;
            break;
    }

    return height;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionName:
            if (isNew)
            {
                title = [Strings nameFooterString];
            }
            break;

        case TableSectionControls:
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
    
    return title;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
            cell = [self nameCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionControls:
            cell = [self controlsCellForIndexPath:indexPath];
            break;

        case TableSectionForwardings:
            break;
    }
    
    return cell;
}


- (UITableViewCell*)nameCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    UITextField*        textField;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NameCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"NameCell"];
        textField = [Common addTextFieldToCell:cell delegate:self];
        textField.tag = TextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
    }

    textField.placeholder = [Strings requiredString];
    textField.text = self.recording.name;//### Must be edited 'name'!

    cell.textLabel.text   = [Strings nameString];
    cell.imageView.image  = nil;
    cell.accessoryType    = UITableViewCellAccessoryNone;
    cell.selectionStyle   = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)controlsCellForIndexPath:(NSIndexPath*)indexPath
{
    return controlsCell;
}


#pragma mark - Actions

- (void)saveAction
{
    self.recording.name = name;

    //### Send to server (look at ForwardingViewController's saveAction.

    [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];

    tappedSave = YES; // Prevents removal of file in viewWillDisappear.
    [self.navigationController popViewControllerAnimated:YES];
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
    if ([audioRecorder.url checkResourceIsReachableAndReturnError:nil] == YES)
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
        [audioRecorder stop];
        isPausedRecording = NO;

        [meteringTimer invalidate];
        meteringTimer = nil;

        self.meterProgressView.progress = 0;
    }

    if (audioPlayer.isPlaying || isPausedPlaying)
    {
        [audioPlayer stop];
        isPausedPlaying = NO;

        [sliderTimer invalidate];
        sliderTimer = nil;

        audioPlayer.currentTime = 0;
        [self updateSlider];
    }

    [self updateControls];
}


- (IBAction)playButtonAction:(id)sender
{
    if (isPausedPlaying == NO && isNew)
    {
        NSError*    error;
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
    name = [textField.text stringByReplacingCharactersInRange:range withString:string];

    [self enableSaveButton];

    return YES;
}


#pragma mark - Helper Methods

- (void)pauseRecording
{
    [audioRecorder pause];
    isPausedRecording = YES;

    [meteringTimer invalidate];
    meteringTimer = nil;

    [self setMeterLevel:0.0f];

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


- (void)enableSaveButton
{
    BOOL hasRecording = ([audioRecorder.url checkResourceIsReachableAndReturnError:nil] == YES);

    self.navigationItem.rightBarButtonItem.enabled = (name.length > 0) && ((hasRecording && !isPausedRecording) || !isNew);
}


- (void)startRecording
{
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    NSError*        error = nil;

    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error != nil)
    {
        NBLog(@"//### Failed to set audio-session category: %@", error.localizedDescription);

        return;
    }

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
    BOOL        isPlaying   = audioPlayer.isPlaying;
    BOOL        isRecording = audioRecorder.isRecording;
    BOOL        canPlay     = ([audioRecorder.url checkResourceIsReachableAndReturnError:nil] == YES) || !isNew;

    // These expressions are negated so that they are about when an UI item is visible (instead of hidden). 
    self.meterProgressView.hidden = !((isNew && !canPlay) || isRecording || isPausedRecording);
    self.timeSlider.hidden        = !self.meterProgressView.hidden;
    self.recordButton.hidden      = !(isNew && !isRecording && !isPausedRecording && !isPlaying && !isPausedPlaying);
    self.pauseButton.hidden       = !(isRecording || isPlaying);
    self.continueButton.hidden    = !(isPausedRecording);

    // These expressions are only correct for when the UI item is visible.
    self.timeSlider.enabled       = isPlaying && !isForwarding && !isReversing && !isPausedPlaying;
    self.reverseButton.enabled    = isPlaying && !isForwarding && !isSliding;
    self.stopButton.enabled       = (isRecording || isPausedRecording || isPlaying || isPausedPlaying) &&
                                      !isForwarding && !isReversing && !isSliding;
    self.recordButton.enabled     = isNew && !isPlaying;
    self.playButton.enabled       = canPlay;
    self.pauseButton.enabled      = (isRecording || isPlaying) && !isForwarding && !isReversing && !isSliding;
    self.forwardButton.enabled    = isPlaying && !isReversing && !isSliding;

    [self enableSaveButton];

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


static void audioRouteChangeListener(
    void*                   inClientData,
    AudioSessionPropertyID  inID,
    UInt32                  inDataSize,
    const void*             inData)
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


- (void)hideKeyboard:(UIGestureRecognizer*)gestureRecognizer
{
    [[self.tableView superview] endEditing:YES];
}

@end
