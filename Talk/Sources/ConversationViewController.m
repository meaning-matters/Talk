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


@interface ConversationViewController ()

@end


@implementation ConversationViewController

// @TODO:
// - When navigating back from this view to the conversations-view, the inputToolbar shows a bit of black for a short time.
//   Maybe because it's removed too early?
//   For slow animations, pause debugger and execute: p [(CALayer *)[[[[UIApplication sharedApplication] windows] objectAtIndex:0] layer] setSpeed:.1f]
// - Message bubbles are not displayed the right size. Is this an iPad issue? (everything stretched)

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Disable the attachement button.
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
    // Set avatar-size to zero.
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    // GestureRecognizer for when the CollectionView is tapped.
    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleCollectionTapRecognizer:)];
    [self.collectionView addGestureRecognizer:tapRecognizer];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    self.title = [self getTitle];
}


- (NSString*)getTitle
{
    // @TODO: Return the correct screen title (Contact name or correct number-format if not in contacts)
    return self.extern_e164;
}


- (NSString*)senderDisplayName
{
    // @TODO: Return correct name for the sender. (This could be either the incoming or outgoing)
    return self.extern_e164;
}


- (NSString*)senderId
{
    // @TODO: What is senderId? Is this a contactId with which I can get the contact's name (and other info?)
    return self.number_e164;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[self getMessages] count];
}


- (NSArray*)getMessages
{
    // @TODO: Maybe it's bad to call this everytime. Should maybe only be done when it's known there are changes.
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"number_e164 == %@ AND extern_e164 = %@", [self number_e164], [self extern_e164]];
    return [[self.fetchedMessagesController fetchedObjects] filteredArrayUsingPredicate:predicate];
}


- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView*)collectionView messageDataForItemAtIndexPath:(NSIndexPath*)indexPath
{
    // @TODO: Don't fetch messages every time again.
    MessageData* message = [[self getMessages] objectAtIndex:indexPath.row];
    
    return [[JSQMessage alloc] initWithSenderId:[message.direction isEqualToString:@"IN"] ? message.extern_e164 : message.number_e164
                                             senderDisplayName:[NSString stringWithFormat:@"%@%@", @"name: ", message.extern_e164]
                                                          date:message.timestamp
                                                          text:message.text];
}


- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // @TODO: Don't fetch messages every time again.
    MessageData* message = [[self getMessages] objectAtIndex:indexPath.row];
    
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    if ([message.direction isEqualToString:@"IN"]) {
        return [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    }
    
    return [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
}


- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (NSAttributedString*)collectionView:(JSQMessagesCollectionView*)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath*)indexPath
{
    return [[NSAttributedString alloc] initWithString:[[NSString alloc] initWithFormat:@"1-Indexpath: %d-%d", indexPath.section, indexPath.row]];
}


- (NSAttributedString*)collectionView:(JSQMessagesCollectionView*)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath*)indexPath
{
    return [[NSAttributedString alloc] initWithString:[[NSString alloc] initWithFormat:@"2-Indexpath: %d-%d", indexPath.section, indexPath.row]];
}


- (NSAttributedString*)collectionView:(JSQMessagesCollectionView*)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath*)indexPath
{
    return [[NSAttributedString alloc] initWithString:[[NSString alloc] initWithFormat:@"3-Indexpath: %d-%d", indexPath.section, indexPath.row]];
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



/*
 - (void)didPressSendButton:(UIButton *)button
 withMessageText:(NSString *)text
 senderId:(NSString *)senderId
 senderDisplayName:(NSString *)senderDisplayName
 date:(NSDate *)date
 
 - (void)didPressAccessoryButton:(UIButton *)sender

 - (NSString *)senderDisplayName
 
 - (NSString *)senderId

 - (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath

 - (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath

 - (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath

 - (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath

 ?? - (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath

 ?? - (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath

 ?? - (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath

 ???? - (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section

 ???? - (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView

 
 */
