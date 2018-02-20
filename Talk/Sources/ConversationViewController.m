//
//  ConversationViewController.m
//  Talk
//
//  Created by Jeroen Kooiker on 18/10/2017.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConversationViewController.h"
#import "MessageDirection.h"
#import "MessageData.h"
#import "CallManager.h"
#import "PhoneNumber.h"
#import "Settings.h"
#import "AppDelegate.h"
#import "MessageUpdatesHandler.h"
#import "DataManager.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "WebClient.h"
#import "PurchaseManager.h"


@interface ConversationViewController ()

@property (nonatomic, strong) NSManagedObjectContext*        managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController*    fetchedMessagesController;
@property (nonatomic, weak) id<NSObject>                     messagesObserver;
@property (nonatomic, strong) NSMutableArray*                fetchedMessages;
@property (nonatomic, strong) NSArray*                       messages;

@property (nonatomic, strong) JSQMessagesBubbleImageFactory* bubbleFactory;
@property (nonatomic, strong) MessageData*                   sentMessage;

@property (nonatomic, strong) PhoneNumber*                   localPhoneNumber;
@property (nonatomic, strong) PhoneNumber*                   externPhoneNumber;
@property (nonatomic, strong) NSString*                      contactId;

@property (nonatomic) NSInteger                              firstUnreadMessageIndex;
@property (nonatomic) BOOL                                   hasFetchedMessages;

@end


@implementation ConversationViewController

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                   fetchedMessagesController:(NSFetchedResultsController*)fetchedMessagesController
                            localPhoneNumber:(PhoneNumber*)localPhoneNumber
                           externPhoneNumber:(PhoneNumber*)externPhoneNumber
                                   contactId:(NSString*)contactId
{
    if (self = [super init])
    {
        self.managedObjectContext      = managedObjectContext;
        self.fetchedMessagesController = fetchedMessagesController;
        
        self.localPhoneNumber  = localPhoneNumber;
        self.externPhoneNumber = externPhoneNumber;
        self.contactId         = contactId;
    }
    
    return self;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self processMessages:self.fetchedMessagesController.fetchedObjects];
    
    // Scroll to first unread message.
    if (self.firstUnreadMessageIndex >= 0)
    {
        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:self.firstUnreadMessageIndex inSection:0];
        [self scrollToIndexPath:indexPath animated:NO];
    }
    
    // Disable the attachment button.
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
    // Set avatar-size to zero, since it's not being used and takes up space next to the messages.
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    // Hide the QuickType bar (the 3 suggestions above the keyboard).
    self.inputToolbar.contentView.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    
    // When the CollectionView is tapped.
    UITapGestureRecognizer* tapRecognizer;
    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                            action:@selector(handleCollectionTapRecognizer:)];
    [self.collectionView addGestureRecognizer:tapRecognizer];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.hasFetchedMessages      = NO;
    self.firstUnreadMessageIndex = -1;
    
    self.bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    
    self.collectionView.delegate   = self;
    self.collectionView.dataSource = self;
    
    self.fetchedMessagesController = [[DataManager sharedManager] fetchResultsForEntityName:@"Message"
                                                                               withSortKeys:nil
                                                                       managedObjectContext:self.managedObjectContext];
    
    if (self.contactId != nil)
    {
        self.title = [[AppDelegate appDelegate] contactNameForId:self.contactId];
    }
    else
    {
        self.title = [self.externPhoneNumber internationalFormat];
    }
    
    __weak typeof(self) weakSelf = self;
    self.messagesObserver = [[NSNotificationCenter defaultCenter] addObserverForName:MessageUpdatesNotification
                                                                              object:nil
                                                                               queue:[NSOperationQueue mainQueue]
                                                                          usingBlock:^(NSNotification* note)
                             {
                                 [weakSelf.fetchedMessagesController performFetch:nil];
                                 [weakSelf processMessages:[weakSelf.fetchedMessagesController fetchedObjects]];
                             }];
}


// self.messages will only contain messages where:
// - message.externE164 == [self.localPhoneNumber e164Format].
// - message.numberE164 == [self.externPhoneNumber e164Format].
//
// Sorts the messages on timestamp.
// Removes the MessageUpdates for all those messages.
// Reloads the collectionView.
- (void)processMessages:(NSArray*)messages
{
    // Filter to keep only the messages with the correct number-combination.
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"numberE164 = %@ AND externE164 = %@",
                              [self.localPhoneNumber e164Format],
                              [self.externPhoneNumber e164Format]];
    messages = [messages filteredArrayUsingPredicate:predicate];
    
    // Sort the messages by timestamp.
    self.messages = [messages sortedArrayUsingComparator:^(id a, id b)
                     {
                         NSDate* first  = ((MessageData*)a).timestamp;
                         NSDate* second = ((MessageData*)b).timestamp;
                         
                         return [first compare:second];
                     }];
    
    // Determine if we have to scroll to the first unread message.
    if (self.hasFetchedMessages == NO)
    {
        int index = 0;
        for (MessageData* message in self.messages)
        {
            if ([[MessageUpdatesHandler sharedHandler] messageUpdateWithUuid:message.uuid] != nil)
            {
                self.firstUnreadMessageIndex = index;
                
                break;
            }
            
            index++;
        }
        
        self.hasFetchedMessages = YES;
    }
    
    [self removeUpdates];
    [self.collectionView reloadData];
}


// Remove the MessageUpdates for all messages in this conversation.
// This decreases the badgeCount and makes the chat "read" (remove the dot on the left).
- (void)removeUpdates
{
    for (MessageData* message in self.messages)
    {
        if ([[MessageUpdatesHandler sharedHandler] messageUpdateWithUuid:message.uuid] != nil)
        {
            [[MessageUpdatesHandler sharedHandler] removeMessageUpdateWithUuid:message.uuid];
        }
    }
}


#pragma mark - CollectionView DataSource methods

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.messages.count;
}


- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView*)collectionView
       messageDataForItemAtIndexPath:(NSIndexPath*)indexPath
{
    MessageData* message  = self.messages[indexPath.row];
    NSString*    senderId = (message.direction == MessageDirectionInbound) ? message.externE164 : message.numberE164;
    
    return [[JSQMessage alloc] initWithSenderId:senderId
                              senderDisplayName:@"" // Not used.
                                           date:message.timestamp
                                           text:message.text
                                       incoming:message.direction == MessageDirectionInbound];
}


- (UICollectionViewCell*)collectionView:(JSQMessagesCollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
    JSQMessagesCollectionViewCell* cell = (JSQMessagesCollectionViewCell*)[super collectionView:collectionView
                                                                         cellForItemAtIndexPath:indexPath];
    
    // Enable hyperlink highlighting + selection of text.
    cell.textView.editable               = NO;
    cell.textView.dataDetectorTypes      = UIDataDetectorTypeAll;
    cell.textView.selectable             = YES;
    cell.textView.userInteractionEnabled = YES;
    
    cell.textView.delegate = self;
    
    MessageData* message = self.messages[indexPath.row];
    
    switch (message.direction)
    {
        case MessageDirectionInbound:  cell.textView.textColor = [UIColor whiteColor]; break;
        case MessageDirectionOutbound: cell.textView.textColor = [UIColor blackColor]; break;
    }
    
    cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                          NSUnderlineStyleAttributeName  : @(NSUnderlineStyleSingle |
                                              NSUnderlinePatternSolid) };
    
    cell.accessoryButton.hidden = YES;
    
    return cell;
}


- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView*)collectionView
             messageBubbleImageDataForItemAtIndexPath:(NSIndexPath*)indexPath
{
    MessageData*                        message = self.messages[indexPath.row];
    id<JSQMessageBubbleImageDataSource> result  = nil;
    
    switch (message.direction)
    {
        case MessageDirectionInbound:
        {
            result = [self.bubbleFactory incomingMessagesBubbleImageWithColor:[Skinning onTintColor]];
            
            break;
        }
        case MessageDirectionOutbound:
        {
            result = [self.bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
            
            break;
        }
    }
    
    return result;
}


- (BOOL)textView:(UITextView*)textView shouldInteractWithURL:(NSURL*)URL inRange:(NSRange)characterRange
{
    // @TODO: (another user-story)
    // - When the number is not valid, you get a popup. If you still make the call, the inputToolbar is over the callView.
    // - When the number is invalid + there are spaces in it, the Keypad shows that as %20 instead of spaces.
    // - What needs to be added here is an alert that allows selection of the number's home country (in case +xx is missing). Discuss with me.
    //    - SMS' sender country-code
    //    - App's country-code
    //    - Choose country
    if ([URL.scheme isEqualToString:@"tel"])
    {
        NSString* number = [URL.resourceSpecifier stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:number isoCountryCode:@"ES"]; // @TODO: country code from self.externE164 (other branch)
        
        if ([phoneNumber isValid])
        {
            // Get the contactId for the chosen number.
            [[AppDelegate appDelegate] findContactsHavingNumber:[phoneNumber nationalDigits]
                                                     completion:^(NSArray* contactIds)
             {
                 NSString* contactId;
                 if (contactIds.count > 0)
                 {
                     contactId = [contactIds firstObject];
                 }
                 
                 // Initiate the call.
                 [[CallManager sharedManager] callPhoneNumber:phoneNumber
                                                    contactId:contactId
                                                     callerId:nil // @TODO: Use callerID of number used for SMS.
                                                   completion:nil];
             }];
        }
        else
        {
            NSString* title;
            NSString* message;
            
            title   = NSLocalizedString(@"Number Invalid",
                                        @"Alert title indicating the pressed number is invalid.");
            
            message = NSLocalizedString(@"The chosen number is invalid and cannot be used to make a call.",
                                        @"Alert mesage indicating the pressed number is invalid.");
            
            
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:nil
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
        
        return NO;
    }
    else
    {
        return YES;
    }
}


- (void)didPressSendButton:(UIButton*)button
           withMessageText:(NSString*)text
                  senderId:(NSString*)senderId
         senderDisplayName:(NSString*)senderDisplayName
                      date:(NSDate*)date
{
    // @TODO: Disable send-button during this process?
    // @TODO: Fix server side that SMS is not always sent
    // @TODO: Show loading screen while buying?
    
    // Check if there's enough credit.
    [[WebClient sharedClient] retrieveCreditWithReply:^(NSError* error, float credit)
     {
         float totalFee         = 1.0; // @TODO: Get the actual cost for sending the SMS
         NSString* creditString = [[PurchaseManager sharedManager] localizedFormattedPrice:credit];
         NSString* totalString  = [[PurchaseManager sharedManager] localizedFormattedPrice:totalFee];
         
         if (error == nil)
         {
             if (totalFee < credit)
             {
                 // Credit is sufficient, send SMS
                 [self sendMessageWithText:text andDate:date];
                 [[AppDelegate appDelegate] checkCreditWithCompletion:nil];
             }
             else
             {
                 int extraCreditAmount = [[PurchaseManager sharedManager] amountForCredit:totalFee - credit];
                 if (extraCreditAmount > 0)
                 {
                     NSString* productIdentifier;
                     NSString* extraString;
                     NSString* title;
                     NSString* message;
                     
                     productIdentifier = [[PurchaseManager sharedManager] productIdentifierForCreditAmount:extraCreditAmount];
                     extraString       = [[PurchaseManager sharedManager] localizedPriceForProductIdentifier:productIdentifier];
                     
                     title   = NSLocalizedStringWithDefaultValue(@"SendSMS NeedExtraCreditTitle", nil,
                                                                 [NSBundle mainBundle], @"Extra Credit Needed",
                                                                 @"Alert title: extra credit must be bought.\n"
                                                                 @"[iOS alert title size].");
                     message = NSLocalizedStringWithDefaultValue(@"SendSMS NeedExtraCreditMessage", nil,
                                                                 [NSBundle mainBundle],
                                                                 @"The total price of %@ is more than your current "
                                                                 @"Credit: %@.\n\nYou can buy the sufficient standard "
                                                                 @"amount of %@ extra Credit now, or cancel to first "
                                                                 @"increase your Credit from the Credit tab.",
                                                                 @"Alert message: buying extra credit is needed.\n"
                                                                 @"[iOS alert message size]");
                     message = [NSString stringWithFormat:message, totalString, creditString, extraString];
                     [BlockAlertView showAlertViewWithTitle:title
                                                    message:message
                                                 completion:^(BOOL cancelled, NSInteger buttonIndex)
                      {
                          if (cancelled == NO)
                          {
                              [[PurchaseManager sharedManager] buyCreditAmount:extraCreditAmount
                                                                    completion:^(BOOL success, id object)
                               {
                                   if (success == YES)
                                   {
                                       // Credit is sufficient now, send SMS
                                       [self sendMessageWithText:text andDate:date];
                                       [[AppDelegate appDelegate] checkCreditWithCompletion:nil];
                                   }
                                   else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
                                   {
                                       // @TODO: Put SMS in chat as NOT SENT?
                                   }
                                   else if (object != nil)
                                   {
                                       NSString* title;
                                       NSString* message;
                                       
                                       title   = NSLocalizedStringWithDefaultValue(@"PayNumber FailedBuyCreditTitle", nil,
                                                                                   [NSBundle mainBundle], @"Buying Credit Failed",
                                                                                   @"Alert title: Credit could not be bought.\n"
                                                                                   @"[iOS alert title size].");
                                       message = NSLocalizedStringWithDefaultValue(@"PayNumber FailedBuyCreditMessage", nil,
                                                                                   [NSBundle mainBundle],
                                                                                   @"Something went wrong while buying Credit: "
                                                                                   @"%@\n\nPlease try again later.",
                                                                                   @"Message telling that buying credit failed\n"
                                                                                   @"[iOS alert message size]");
                                       message = [NSString stringWithFormat:message, [object localizedDescription]];
                                       [BlockAlertView showAlertViewWithTitle:title
                                                                      message:message
                                                                   completion:^(BOOL cancelled, NSInteger buttonIndex)
                                        {
                                            // @TODO: Put SMS in chat as NOT SENT?
                                        }
                                                            cancelButtonTitle:[Strings closeString]
                                                            otherButtonTitles:nil];
                                   }
                               }];
                          }
                          else
                          {
                              // @TODO: Put SMS in chat as NOT SENT?
                          }
                      }
                                          cancelButtonTitle:[Strings cancelString]
                                          otherButtonTitles:[Strings buyString], nil];
                 }
             }
         }
         else
         {
             NSString* title;
             NSString* message;
             
             title   = NSLocalizedStringWithDefaultValue(@"PaySMS FailedGetCreditTitle", nil,
                                                         [NSBundle mainBundle], @"Credit Unknown",
                                                         @"Alert title: Reading the user's credit failed.\n"
                                                         @"[iOS alert title size].");
             message = NSLocalizedStringWithDefaultValue(@"PaySMS FailedGetCreditMessage", nil,
                                                         [NSBundle mainBundle],
                                                         @"Could not get your up-to-date Credit: %@.\n\n"
                                                         @"Please try again later.",
                                                         @"Message telling that paying an SMS failed\n"
                                                         @"[iOS alert message size]");
             message = [NSString stringWithFormat:message, error.localizedDescription];
             [BlockAlertView showAlertViewWithTitle:title
                                            message:message
                                         completion:^(BOOL cancelled, NSInteger buttonIndex)
              {
                  // @TODO: Put SMS in chat as NOT SENT?
              }
                                  cancelButtonTitle:[Strings closeString]
                                  otherButtonTitles:nil];
         }
     }];
}


- (void)sendMessageWithText:(NSString*)text andDate:(NSDate*)date
{
    self.sentMessage = [NSEntityDescription insertNewObjectForEntityForName:@"Message"
                                                     inManagedObjectContext:self.managedObjectContext];
    
    // @TODO: Format message (special chars, emojis, etc etc)
    [self.sentMessage createForNumberE164:[self.localPhoneNumber e164Format]
                               externE164:[self.externPhoneNumber e164Format]
                                     text:text
                                 datetime:date
                               completion:^(NSError* error)
     {
         if (error == nil)
         {
             [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
             NSManagedObjectContext* mainContext = [DataManager sharedManager].managedObjectContext;
             self.sentMessage = [mainContext existingObjectWithID:self.sentMessage.objectID error:nil];
             
             [self.fetchedMessages addObject:self.sentMessage];
             
             [self finishSendingMessage];
             [self processMessages:self.fetchedMessagesController.fetchedObjects];
         }
         else
         {
             NSString* title   = NSLocalizedString(@"Sending Message Failed",
                                                   @"Alert-title that message could not be sent.");
             // @TODO: Implement different failures by accepting error-codes from server (to-implement)
             NSString* message = NSLocalizedString(@"Make sure you have a working internet-connection. Please try again later.",
                                                   @"Alert-message that message could not be sent.");
             
             [BlockAlertView showAlertViewWithTitle:title
                                            message:message
                                         completion:nil
                                  cancelButtonTitle:[Strings closeString]
                                  otherButtonTitles:nil];
         }
     }];
}


// Hides the keyboard when the CollectionView is tapped.
- (void)handleCollectionTapRecognizer:(UITapGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        if ([self.inputToolbar.contentView.textView isFirstResponder])
        {
            [self.inputToolbar.contentView.textView resignFirstResponder];
        }
    }
}


// Used by JSQMessagesViewController to determine where to draw the message (left / right).
- (BOOL)isOutgoingMessage:(id<JSQMessageData>)messageItem
{
    return !((JSQMessage*)messageItem).isIncoming;
}


// Mandatory to override.
- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView*)collectionView
                    avatarImageDataForItemAtIndexPath:(NSIndexPath*)indexPath
{
    // Disable avatarImages next to the bubbles.
    return nil;
}


// Must be overriden for JSQMessagesViewController.
- (NSString*)senderId
{
    return @"";
}


- (NSString*)senderDisplayName
{
    return nil;
}

@end

