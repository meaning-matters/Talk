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


@interface ConversationViewController ()

@property (nonatomic, strong) NSMutableArray*                fetchedMessages;
@property (nonatomic, strong) NSArray*                       messages;
@property (nonatomic, strong) JSQMessagesBubbleImageFactory* bubbleFactory;
@property (nonatomic, strong) UISearchBar*                   contactSearchBar;
@property (nonatomic, strong) PhoneNumber*                   phoneNumber;
//@property (nonatomic, strong) NBPeopleListViewController*    peopleListViewController;

@end


@implementation ConversationViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Disable the attachement button.
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
    // Set avatar-size to zero, since it's not being used and takes up space next to the messages.
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    // Hide the QuickType bar (the 3 suggestions above the keyboard).
    self.inputToolbar.contentView.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    
    // When the CollectionView is tapped.
    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleCollectionTapRecognizer:)];
    [self.collectionView addGestureRecognizer:tapRecognizer];
    
    // Setup searchbar for selecting a contact or choosing a number.
    self.contactSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 40)];
    self.contactSearchBar.delegate        = self;
    self.contactSearchBar.searchBarStyle  = UISearchBarStyleMinimal;
    self.contactSearchBar.tintColor       = [UIColor grayColor];
    self.contactSearchBar.searchBarStyle  = UISearchBarStyleMinimal;
    self.contactSearchBar.backgroundColor = [UIColor whiteColor]; // @TODO: Same color as navigationBar
    self.contactSearchBar.placeholder = @"Contact or number"; // @TODO: Other text + localizedString
    [self.view addSubview:self.contactSearchBar];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:
                                                                      @{NSForegroundColorAttributeName:[UIColor blackColor]}];
}


-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [[[AppDelegate appDelegate] nBPeopleListViewController] filterContactsWithSearchString:searchText completion:^(NSArray* contacts)
    {
        for (int i = 0; i < contacts.count; i++)
        {
            ABRecordRef contact = (__bridge ABRecordRef)[contacts objectAtIndex:i];
            NSString* contactId = [NSString stringWithFormat:@"%d", ABRecordGetRecordID(contact)];
            NSLog(@"%@\n", contactId);
        }
    }];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    
    self.collectionView.delegate   = self;
    self.collectionView.dataSource = self;
    
    self.phoneNumber = [[PhoneNumber alloc] init];
    
//    self.peopleListViewController = [[NBPeopleListViewController alloc] init];
    
    if (self.contactId != nil)
    {
        self.title = [[AppDelegate appDelegate] contactNameForId:self.contactId];
    }
    else
    {
        self.title = self.externE164;
    }
}


// Must be overriden for JSQMessagesViewController.
- (NSString*)senderId
{
    return nil;
}


// Used by JSQMessagesViewController to determine where to draw the message (left / right).
- (BOOL)isOutgoingMessage:(id<JSQMessageData>)messageItem
{
    return !((JSQMessage*)messageItem).isIncoming;
}


- (NSArray*)messages
{
    if (self.fetchedMessages == nil)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"numberE164 == %@ AND externE164 = %@", [self numberE164], [self externE164]];
        self.fetchedMessages = [[NSMutableArray alloc] initWithArray:[[self.fetchedMessagesController fetchedObjects] filteredArrayUsingPredicate:predicate]];
    }
    
    return self.fetchedMessages;
}


- (MessageData*)messageAtIndexPath:(NSIndexPath*)indexPath
{
    return [self.messages objectAtIndex:indexPath.row];
}


#pragma mark - CollectionView DataSource methods

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.messages.count;
}


- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView*)collectionView
       messageDataForItemAtIndexPath:(NSIndexPath*)indexPath
{
    MessageData* message  = [self messageAtIndexPath:indexPath];
    NSString*    senderId = message.direction == MessageDirectionInbound ? message.externE164 : message.numberE164;

    return [[JSQMessage alloc] initWithSenderId:senderId
                              senderDisplayName:[NSString stringWithFormat:@"%@%@", @"name: ", message.externE164]
                                           date:message.timestamp
                                           text:message.text
                                       incoming:message.direction == MessageDirectionInbound];
}


- (UICollectionViewCell*)collectionView:(JSQMessagesCollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
    JSQMessagesCollectionViewCell* cell = (JSQMessagesCollectionViewCell*)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    // Enable hyperlink highlighting + selection of text.
    cell.textView.editable               = NO;
    cell.textView.dataDetectorTypes      = UIDataDetectorTypeAll;
    cell.textView.selectable             = YES;
    cell.textView.userInteractionEnabled = YES;
    
    cell.textView.delegate = self;
    
    MessageData* message = [self messageAtIndexPath:indexPath];
    
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
    MessageData*                        message = [self messageAtIndexPath:indexPath];
    id<JSQMessageBubbleImageDataSource> result  = nil;
    
    switch (message.direction)
    {
        case MessageDirectionInbound:
        {
            result = [self.bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
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


// Mandatory to override.
- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView*)collectionView
                    avatarImageDataForItemAtIndexPath:(NSIndexPath*)indexPath
{
    NBLog(@"--- [ Not Implemented ]: ConversationViewController.m -> avatarImageDataForItemAtIndexPath");

    // Return nil to disable avatarImages next to the bubbles.
    return nil;
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
                                                callerId:nil // Determine the caller ID based on user preferences.
                                              completion:^(Call* call)
            {
                if (call != nil)
                {
                    [Settings sharedSettings].lastDialedNumber = phoneNumber.number;
                }
            }];
        }];
        
        return NO;
    }
    else
    {
        return YES;
    }
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

@end
