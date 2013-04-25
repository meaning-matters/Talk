//
//  RecordingViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 19/04/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "RecordingViewController.h"
#import "RecordingControlsCell.h"
#import "RecordingData.h"
#import "Common.h"
#import "NSTimer+Blocks.h"
#import "BlockAlertView.h"
#import "CommonStrings.h"


typedef enum
{
    TableSectionName        = 1UL << 0, // User-given name.
    TableSectionControls    = 1UL << 1,
    TableSectionForwardings = 1UL << 2,
} TableSections;


static const int    TextFieldCellTag = 1111;


@interface RecordingViewController ()
{
    TableSections               sections;
    BOOL                        isForwarding;
    BOOL                        isReversing;
    BOOL                        isSliding;
    BOOL                        isPausedRecording;
    BOOL                        isPausedPlaying;
    float                       duration;
    BOOL                        tappedSave;

    AVAudioRecorder*            audioRecorder;
    AVAudioPlayer*              audioPlayer;
    NSTimer*                    sliderTimer;
    NSTimer*                    meteringTimer;

    NSFetchedResultsController* fetchedResultsController;
    NSManagedObjectContext*     managedObjectContext;
    RecordingData*              recording;
    RecordingControlsCell*      controlsCell;

    NSMutableArray*             meterProgressViewsArray;
}

@end


@implementation RecordingViewController

- (id)initWithFetchedResultsController:(NSFetchedResultsController*)resultsController
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"RecordingView ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Recording",
                                                       @"Title of app screen with details of an audio recording\n"
                                                       @"[1 line larger font].");

        fetchedResultsController = resultsController;

        // Create a new managed object context for the new book; set its parent to the fetched results controller's context.
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [managedObjectContext setParentContext:[fetchedResultsController managedObjectContext]];
        recording = (RecordingData*)[NSEntityDescription insertNewObjectForEntityForName:@"Recording"
                                                                  inManagedObjectContext:managedObjectContext];

        sections |= TableSectionName;
        sections |= TableSectionControls;
        sections |= (recording.forwardings.count > 0) ? TableSectionForwardings : 0;

        if (recording.urlString.length == 0)
        {
            NSString*       uuid = [[NSUUID UUID] UUIDString];
            NSURL*          url  = [Common audioUrl:[NSString stringWithFormat:@"%@.aac", uuid]];
            NSError*        error;
            NSDictionary*   settings = @{ AVEncoderAudioQualityKey : @(AVAudioQualityMedium),
                                          AVEncoderBitRateKey      : @(12800),
                                          AVNumberOfChannelsKey    : @(1),
                                          AVSampleRateKey          : @(44100.0f),
                                          AVFormatIDKey            : @(kAudioFormatMPEG4AAC) };
            
            audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
            if (error == nil)
            {
                audioRecorder.meteringEnabled = YES;
                audioRecorder.delegate = self;
            }
            else
            {
                NSLog(@"//### Failed to create audio recorder: %@", [error localizedDescription]);
            }
        }

        // Select initial audio route, and add listerer for changes.
        audioRouteChangeListener(NULL, kAudioSessionProperty_AudioRouteChange, 0, NULL);
        OSStatus result = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange,
                                                          audioRouteChangeListener,
                                                          (__bridge void*)self);
        if (result != 0)
        {
            NSLog(@"//### Failed to set AudioRouteChange listener: %@", [Common stringWithOsStatus:result]);
        }
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    self.navigationItem.rightBarButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                            target:self
                                                                                            action:@selector(saveAction)];

    NSArray*    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"RecordingControlsCell" owner:self options:nil];
    controlsCell = [topLevelObjects objectAtIndex:0];
    
    [self updateControls];
    self.meterProgressView.progress = 0;
    self.timeSlider.value = 0;

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


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if ([self.navigationController.viewControllers indexOfObject:self] != NSNotFound)
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

        AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange,
                                                       audioRouteChangeListener,
                                                       (__bridge void*)self);

        if (tappedSave == NO)
        {
            NSError*    error;
            [[NSFileManager defaultManager] removeItemAtURL:audioRecorder.url error:&error];
            if (error != nil)
            {
                NSLog(@"//### Failed to remove unused audio file: %@.", [error localizedDescription]);
            }
        }
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 2 + (recording.forwardings.count > 0);
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
            numberOfRows = recording.forwardings.count;
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
        textField = [self addTextFieldToCell:cell];
        textField.tag = TextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
    }

    textField.placeholder = [CommonStrings requiredString];

    cell.textLabel.text   = [CommonStrings nameString];
    cell.imageView.image  = nil;
    cell.accessoryType    = UITableViewCellAccessoryNone;
    cell.selectionStyle   = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)controlsCellForIndexPath:(NSIndexPath*)indexPath
{
    return controlsCell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}


#pragma mark - Actions

- (void)saveAction
{
    NSError*    error;
    if ([managedObjectContext save:&error] == NO || [[fetchedResultsController managedObjectContext] save:&error] == NO)
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    tappedSave = YES;   // Prevents removal of file in viewWillDisappear.
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
        NSString*   title;
        NSString*   message;
        NSString*   buttonTitle;

        title = NSLocalizedStringWithDefaultValue(@"RecordingView OverwriteTitle", nil,
                                                  [NSBundle mainBundle], @"Discard Recording",
                                                  @"Alert title asking if existing audio recording can be overwritten\n"
                                                  @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"RecordingView OverwriteMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"Do you want to overwrite the existing recording you just made?\n"
                                                    @"The new recoding starts immediately after you confirm.",
                                                    @"Alert message explaing that existing recording will be overwritten\n"
                                                    @"[iOS alert message size]");

        buttonTitle = NSLocalizedStringWithDefaultValue(@"RecordingView RecordButtonTitle", nil,
                                                        [NSBundle mainBundle], @"Record",
                                                        @"Button title for starting an audio recording\n"
                                                        @"[iOS alert button size 1/2 alert width].");

        [BlockAlertView showAlertViewWithTitle:title message:message completion:^(BOOL canceled, NSInteger buttonIndex)
        {
            if (buttonIndex == 1)
            {
                [self startRecording];
            }
        }
                             cancelButtonTitle:[CommonStrings cancelString]
                             otherButtonTitles:buttonTitle, nil];
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
        duration = audioRecorder.currentTime;

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

    self.timeLabel.text = [NSString stringWithFormat:@"%ds", (int)duration];
}


- (IBAction)playButtonAction:(id)sender
{
    if (isPausedPlaying == NO)
    {
        NSError*    error;
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioRecorder.url error:&error];
        if (error == nil)
        {
            audioPlayer.delegate = self;
        }
        else
        {
            NSLog(@"//### Failed to create audio player: %@", [error localizedDescription]);
        }
    }

    sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^
    {
        [self updateSlider];
    }];

    [audioPlayer play];
    isPausedPlaying = NO;

    // For some reason the durations are not constant.
    self.timeSlider.maximumValue = MIN(duration, audioPlayer.duration) - 0.15;

    [self updateControls];
}


- (IBAction)pauseButtonAction:(id)sender
{
    if (audioRecorder.isRecording)
    {
        [audioRecorder pause];
        isPausedRecording = YES;

        [meteringTimer invalidate];
        meteringTimer = nil;

        [self setMeterLevel:0.0f];
        
        self.timeLabel.text = NSLocalizedStringWithDefaultValue(@"RecordingView RecordingPausedLabel", nil,
                                                                [NSBundle mainBundle], @"Recording is paused",
                                                                @"Label saying that recording audio is paused\n"
                                                                @"[1 line].");
    }

    if (audioPlayer.isPlaying)
    {
        [audioPlayer pause];
        isPausedPlaying = YES;
        
        [sliderTimer invalidate];
        sliderTimer = nil;

        self.timeLabel.text = NSLocalizedStringWithDefaultValue(@"RecordingView RecordingPausedLabel", nil,
                                                                [NSBundle mainBundle], @"Playing is paused",
                                                                @"Label saying that playing audio is paused\n"
                                                                @"[1 line].");
    }

    [self updateControls];
}


- (IBAction)continueButtonAction:(id)sender
{
    [audioRecorder record];
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

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder*)recorder error:(NSError*)error
{
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder*)recorder successfully:(BOOL)flag
{
}


#pragma mark - Player Delegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag
{
    [sliderTimer invalidate];
    sliderTimer = nil;

    audioPlayer.currentTime = 0.0;
    [self updateSlider];

    [self updateControls];
    self.timeLabel.text = [NSString stringWithFormat:@"%ds", (int)duration];
}


#pragma mark - Helper Methods

- (void)startRecording
{
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    NSError*        error = nil;

    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error != nil)
    {
        NSLog(@"//### Failed to set audio-session category: %@.", [error localizedDescription]);

        return;
    }

    if ([audioRecorder prepareToRecord] == NO || [audioRecorder record] == NO)
    {
        NSLog(@"//### Failed to start recording.");

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

#warning Localize these times!
        self.timeLabel.text = [NSString stringWithFormat:@"%ds", (int)audioRecorder.currentTime];
    }
}


- (void)setMeterLevel:(float)level
{
    for (int n = 0; n < 26; n++)
    {
        UIProgressView* progressView = meterProgressViewsArray[n];
        progressView.progress = (level * 26.0f > n) ? 1 : 0;
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


- (UITextField*)addTextFieldToCell:(UITableViewCell*)cell
{
    UITextField*    textField;
    CGRect          frame = CGRectMake(83, 6, 198, 30);

    textField = [[UITextField alloc] initWithFrame:frame];
    [textField setFont:[UIFont boldSystemFontOfSize:15]];

    textField.adjustsFontSizeToFitWidth = NO;
    textField.autocapitalizationType    = UITextAutocapitalizationTypeWords;
    textField.clearButtonMode           = UITextFieldViewModeWhileEditing;
    textField.contentVerticalAlignment  = UIControlContentVerticalAlignmentCenter;

    textField.delegate                  = self;

    [cell.contentView addSubview:textField];

    return textField;
}


- (void)updateControls
{
    BOOL        isNew       = (recording.urlString.length == 0);
    BOOL        isPlaying   = audioPlayer.isPlaying;
    BOOL        isRecording = audioRecorder.isRecording;
    BOOL        canPlay     = ([audioRecorder.url checkResourceIsReachableAndReturnError:nil] == YES);

    // These expressions are negated so that they are about when an UI item is visible (instead of hidden). 
    self.meterProgressView.hidden   = !((isNew && !canPlay) || isRecording || isPausedRecording);
    self.timeSlider.hidden          = !self.meterProgressView.hidden;
    self.recordButton.hidden        = !(isNew && !isRecording && !isPausedRecording && !isPlaying && !isPausedPlaying);
    self.pauseButton.hidden         = !(isRecording || isPlaying);
    self.continueButton.hidden      = !(isPausedRecording);

    // These expressions are only correct for when the UI item is visible.
    self.timeSlider.enabled         = isPlaying && !isForwarding && !isReversing && !isPausedPlaying;
    self.reverseButton.enabled      = isPlaying && !isForwarding && !isSliding;
    self.stopButton.enabled         = (isRecording || isPausedRecording || isPlaying || isPausedPlaying) &&
                                      !isForwarding && !isReversing && !isSliding;
    self.recordButton.enabled       = isNew && !isPlaying;
    self.playButton.enabled         = canPlay;
    self.pauseButton.enabled        = (isRecording || isPlaying) && !isForwarding && !isReversing && !isSliding;
    self.forwardButton.enabled      = isPlaying && !isReversing && !isSliding;

    self.navigationItem.rightBarButtonItem.enabled = canPlay && !isRecording && !isPausedRecording;

    for (int n = 1; n < 26; n++)
    {
        UIProgressView* progressView = meterProgressViewsArray[n];
        progressView.hidden = self.meterProgressView.hidden;
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
            CFShow(newRoute);
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
                AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
                                         sizeof(audioRouteOverride),
                                         &audioRouteOverride);
            }
        }
    }
}


#warning Not used.
- (void)resetAudioRoute
{
    UInt32      routeSize = sizeof(CFStringRef);
    CFStringRef routeRef;
    OSStatus    status = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &routeSize, &routeRef);
    NSString*   route = (__bridge NSString*)routeRef;

}

@end
