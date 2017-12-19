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


@interface ConversationViewController ()

@property (nonatomic, strong) NSManagedObjectContext*        managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController*    fetchedMessagesController;
@property (nonatomic, weak) id<NSObject>                     messagesObserver;
@property (nonatomic, strong) NSMutableArray*                fetchedMessages;
@property (nonatomic, strong) NSArray*                       messages;

@property (nonatomic, strong) JSQMessagesBubbleImageFactory* bubbleFactory;
@property (nonatomic, strong) MessageData*                   sentMessage;

@property (nonatomic, strong) PhoneNumber*                   numberE164;
@property (nonatomic, strong) PhoneNumber*                   externE164;
@property (nonatomic, strong) NSString*                      contactId;

@property (nonatomic) NSInteger                              firstUnreadMessageIndex;
@property (nonatomic) BOOL                                   hasFetchedMessages;

@end


@implementation ConversationViewController

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                   fetchedMessagesController:(NSFetchedResultsController*)fetchedMessagesController
                                  numberE164:(PhoneNumber*)numberE164
                                  externE164:(PhoneNumber*)externE164
                                   contactId:(NSString *)contactId
{
    if (self = [super init])
    {
        self.managedObjectContext      = managedObjectContext;
        self.fetchedMessagesController = fetchedMessagesController;
        
        self.numberE164 = numberE164;
        self.externE164 = externE164;
        self.contactId  = contactId;
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


- (void)viewWillDisappear:(BOOL)animated
{
    // @TODO: This still shows the 2nd viewController for a second ...
    [super viewWillDisappear:animated];
    
    // If there are messages, so the conversation already exists, go back to root.
    // Otherwise go back one so the user can change the contact.
    if (self.messages.count > 0)
    {
        [self.navigationController popToRootViewControllerAnimated:animated];
    }
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
        self.title = [self.externE164 internationalFormat];
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


// self.messages will only contain messages where message.externE164 == self.externE164.
// Sorts the messages on timestamp.
// Removes the MessageUpdates for all those messages.
// Reloads the collectionView.
- (void)processMessages:(NSArray*)messages
{
    NSMutableArray* sortedMessages = [[NSMutableArray alloc] init];
    
    // Get the messages for this conversation.
    [messages enumerateObjectsUsingBlock:^(MessageData* message, NSUInteger index, BOOL* stop)
    {
        if ([message.externE164 isEqualToString:[self.externE164 e164Format]])
        {
            [sortedMessages addObject:message];
        }
    }];
    
    // Sort the messages by timestamp.
    self.messages = [[NSArray arrayWithArray:sortedMessages] sortedArrayUsingComparator:^(id a, id b)
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
        PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:URL.resourceSpecifier];
        
        // @TODO: Check if number is valid?
        // Get the contactId for the chosen number.
        [[AppDelegate appDelegate] findContactsHavingNumber:phoneNumber.number
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
                                                callerId:nil // Determine the caller ID based on user preferences.
                                              completion:nil];
        }];
        
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
    self.sentMessage = [NSEntityDescription insertNewObjectForEntityForName:@"Message"
                                                     inManagedObjectContext:self.managedObjectContext];
    
    // @TODO: Format message (special chars, emojis, etc etc)
    [self.sentMessage createForNumberE164:[self.numberE164 e164Format]
                               externE164:[self.externE164 e164Format]
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
    return nil;
}


- (NSString*)senderDisplayName
{
    return nil;
}

@end
