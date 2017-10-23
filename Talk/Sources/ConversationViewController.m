//
//  ConversationViewController.m
//  Talk
//
//  Created by Jeroen Kooiker on 18/10/2017.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConversationViewController.h"
#import "MessageData.h"
#import "CallManager.h"
#import "PhoneNumber.h"
#import "Settings.h"
#import "AppDelegate.h"


@interface ConversationViewController ()

@property (strong, nonatomic) NSMutableArray* messages;

@end


@implementation ConversationViewController

// @TODO:
// - When navigating back from this view to the conversations-view, the inputToolbar shows a bit of black for a short time.
//   Maybe because it's removed too early?

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Disable the attachement button.
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
    // Set avatar-size to zero, since it's not being used and takes up space next to the messages.
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    // Disable the QuickTyping bar (the 3 suggestions above the keyboard).
    self.inputToolbar.contentView.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    
    // GestureRecognizer for when the CollectionView is tapped (close the keyboard).
    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleCollectionTapRecognizer:)];
    [self.collectionView addGestureRecognizer:tapRecognizer];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    if (self.contactId != nil)
    {
        self.title = [[AppDelegate appDelegate] contactNameForId:self.contactId];
    }
    else
    {
        self.title = self.extern_e164;
    }
}


- (NSString*)senderId
{
    // senderId is used to determine the direction of the message (where to draw it, left or right).
    return self.number_e164;
}


- (NSArray*)getMessages
{
    if (self.messages == nil)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"number_e164 == %@ AND extern_e164 = %@", [self number_e164], [self extern_e164]];
        self.messages = [[NSMutableArray alloc] initWithArray:[[self.fetchedMessagesController fetchedObjects] filteredArrayUsingPredicate:predicate]];
    }
    
    return self.messages;
}


- (MessageData*)getMessageAtIndex:(NSIndexPath*)indexPath
{
    return [[self getMessages] objectAtIndex:indexPath.row];
}


#pragma mark - CollectionView DataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[self getMessages] count];
}


- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView*)collectionView messageDataForItemAtIndexPath:(NSIndexPath*)indexPath
{
    MessageData* message = [self getMessageAtIndex:indexPath];
    
    return [[JSQMessage alloc] initWithSenderId:[message.direction isEqualToString:@"IN"] ? message.extern_e164 : message.number_e164
                                             senderDisplayName:[NSString stringWithFormat:@"%@%@", @"name: ", message.extern_e164]
                                                          date:message.timestamp
                                                          text:message.text];
}


- (UICollectionViewCell*)collectionView:(JSQMessagesCollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
    JSQMessagesCollectionViewCell* cell = (JSQMessagesCollectionViewCell*)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    // Enables hyperlink highlighting + selection of text.
    cell.textView.editable = NO;
    cell.textView.dataDetectorTypes = UIDataDetectorTypeAll;
    cell.textView.selectable = YES;
    cell.textView.userInteractionEnabled = YES;
    
    cell.textView.delegate = self;
    
    MessageData* message = [self getMessageAtIndex:indexPath];
    
    if ([message.direction isEqualToString:@"IN"]) {
        cell.textView.textColor = [UIColor whiteColor];
    }
    else {
        cell.textView.textColor = [UIColor blackColor];
    }
    
    cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                          NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    
    cell.accessoryButton.hidden = YES;
    
    return cell;
}


- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MessageData* message = [self getMessageAtIndex:indexPath];
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    if ([message.direction isEqualToString:@"IN"])
    {
        return [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    }
    else
    {
        return [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    }
}


- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"--- [ Not Implemented ]: ConversationViewController.m -> avatarImageDataForItemAtIndexPath");
    return nil;
}


- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"--- [ Not Implemented ]: ConversationViewController.m -> didDeleteMessageAtIndexPath");
}


- (NSAttributedString*)collectionView:(JSQMessagesCollectionView*)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath*)indexPath
{
    NSLog(@"--- [ Not Implemented ]: ConversationViewController.m -> attributedTextForCellTopLabelAtIndexPath");
    return [[NSAttributedString alloc] initWithString:[[NSString alloc] initWithFormat:@"Indexpath: %d-%d", indexPath.section, indexPath.row]];
}


- (NSAttributedString*)collectionView:(JSQMessagesCollectionView*)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath*)indexPath
{
    NSLog(@"--- [ Not Implemented ]: ConversationViewController.m -> attributedTextForMessageBubbleTopLabelAtIndexPath");
    return [[NSAttributedString alloc] initWithString:[[NSString alloc] initWithFormat:@"Indexpath: %d-%d", indexPath.section, indexPath.row]];
}


- (NSAttributedString*)collectionView:(JSQMessagesCollectionView*)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath*)indexPath
{
    NSLog(@"--- [ Not Implemented ]: ConversationViewController.m -> attributedTextForCellBottomLabelAtIndexPath");
    return [[NSAttributedString alloc] initWithString:[[NSString alloc] initWithFormat:@"Indexpath: %d-%d", indexPath.section, indexPath.row]];
}


- (BOOL)textView:(UITextView*)textView shouldInteractWithURL:(NSURL*)URL inRange:(NSRange)characterRange
{
    // @TODO: When the number is not valid, you get a popup. If you still make the call, the inputToolbar is over the callView.
    if ([URL.scheme isEqualToString:@"tel"])
    {
        PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:URL.resourceSpecifier];
        
        // @TODO: Now we wait till the contact is fetched, and then initiate the call. Is this OK?
        // KeypadViewController.m:436 does the same.
        
        // @TODO: When the number is invalid + there are spaces in it, the Keypad shows that as %20 instead of spaces.
        
        // Get the contactId for the chosen number.
        [[AppDelegate appDelegate] findContactsHavingNumber:[phoneNumber nationalDigits]
                                                 completion:^(NSArray* contactIds)
        {
            NSString* callContactId;
            if (contactIds.count > 0)
            {
                callContactId = [contactIds firstObject];
            }
            
            // Initiate the call.
            [[CallManager sharedManager] callPhoneNumber:phoneNumber
                                               contactId:callContactId
                                                callerId:nil // Determine the caller ID based on user preferences.
                                              completion:^(Call *call)
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
